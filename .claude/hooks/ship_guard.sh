#!/bin/sh
# attest ship guard: PreToolUse on the shell tools and on MCP publish tools. It asks before
# anything leaves the machine, and denies instead only under ATTEST_GUARD=deny. In order:
#   MCP publish tool   always asks: no record covers bytes chosen in the call
#   ship list          the commands that send data off the machine
#   record write       writing .attest/ship-*.md asks: that write is the attestation
#   dry run            a plain `--dry-run` passes, traced
#   leak scan          betterleaks, when installed, over every unpushed branch and tag
#   push shape         a record speaks for HEAD, so the push has to ship HEAD alone
#   record lookup      every record naming HEAD must read `findings: 0 blocker`
#   carrier            a push or PR whose HEAD only adds records passes as the commit they name
#   prompt             otherwise ask, saying what is missing; every decision is traced
# No payload or no match: the command proceeds. No HEAD: it asks.

set -uf
export LC_ALL=C
# The hook's own state starts empty, whatever the session's environment holds.
KIND=; ACT=; DEC=; CLEAN_RECORD=0; SCAN=-; V=; AUDITED=; CARRY=; SHIPS=

ROOT="${CLAUDE_PROJECT_DIR:-.}"
PAYLOAD="$(cat 2>/dev/null || true)"
[ -n "$PAYLOAD" ] || exit 0
CMD="$(printf '%s' "$PAYLOAD" |
  sed -nE 's/.*"command"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p')"
[ -n "$CMD" ] || CMD="$PAYLOAD"
TOOL="$(printf '%s' "$PAYLOAD" | tr ',' '\n' |
  sed -nE 's/.*"tool_name"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | sed -n '1p')"

# Quotes go and git's own options (-C dir, -c k=v, …) are skipped: every spelling reads the same.
# git.exe reads as git, and an option or value whose quotes do not pair up runs on to the word
# that pairs them (an escaped quote does not count).
norm() { printf '%s' "$1" | awk '
  function bare(x) { gsub(/[\042\047]/, "", x); return x }
  function q(x) { gsub(/\\\\[\042\047]/, "", x); if (K == "" && match(x, /[\042\047]/)) K = substr(x, RSTART, 1); return K == "" ? 0 : gsub(K, "", x) }
  {
    out = ""
    for (i = 1; i <= NF; i++) {
      t = bare($i); sub(/git\.exe$/, "git", t)
      out = (out == "" ? t : out " " t)
      if (t ~ /git$/)
        while (i < NF && substr(bare($(i+1)), 1, 1) == "-") {
          i++; K = ""; c = q($i)
          if (bare($i) ~ /^(-[cC]|--(git-dir|work-tree|namespace|config-env|attr-source))$/ && i < NF) c += q($(++i))
          while (c % 2 && i < NF) c += q($(++i))
        }
    }
    print out
  }' 2>/dev/null; }
NORM="$(norm "$CMD")"
[ -n "$NORM" ] || NORM="$CMD"
case "$TOOL" in
  mcp__*create_repository*) KIND=mcp; ACT="creates a repository and publishes what you send" ;;
  mcp__*) KIND=mcp; ACT="sends data off the machine" ;;
esac
ship_act() { case "$1" in
  *"git push"*|*"git send-email"*|*"gh "*"pr create"*|*"gh "*"pr new"*|*"gh release create"*|*"gh gist create"*|\
  *"npm publish"*|*"twine upload"*|*"cargo publish"*|*"docker push"*|*"docker image push"*|*"docker buildx"*"--push"*|\
  *"yarn publish"*|*"bun publish"*|*"uv publish"*|*"poetry publish"*|*"gem push"*|*"gh release upload"*|*"kaggle"*"submit"*|\
  *"scp "*":"*|*"scp "*'$'*|*"rsync "*":"*|*"rsync "*'$'*|*"aws s3 cp"*|*"aws s3 sync"*|*"gsutil cp"*|\
  *"--upload-file"*|*"curl"*" -T "*)
    echo "sends data off the machine" ;;
  *"gh repo edit"*"--visibility"*|*"gh repo create"*) echo "changes who can read this repository" ;;
esac; }
[ -n "${KIND:-}" ] || ACT="$(ship_act "$NORM")"

# A record written in a push's own command would skip its prompt, so every shell command is read.
NL='
'
if [ "${KIND:-}" != mcp ]; then
  _parts="$(printf '%s' "$NORM" | sed 's#\\\\#/#g; s/\\n/;/g; s/>|/>/g' | tr ';|&' '\n' | sed 's/>[[:space:]]*/>/g')"
  _oifs="$IFS"; IFS="$NL"
  for _part in $_parts; do
    case "$_part" in
      *">"*".attest/ship-"*|*"tee"*".attest/ship-"*|*"cp "*".attest/ship-"*|\
      *"mv "*".attest/ship-"*|*"sed -i"*".attest/ship-"*|*"sed --in-place"*".attest/ship-"*|\
      *"perl -pi"*".attest/ship-"*|*"truncate"*".attest/ship-"*)
        KIND=record; ACT="writes a ship record${ACT:+ and $ACT}"; break ;;
    esac
  done
  IFS="$_oifs"
fi

[ -n "${ACT:-}" ] || exit 0

# A credential in the command never reaches the trace or the prompt.
if [ "${KIND:-}" = mcp ]; then SUBJ="$TOOL"; else SUBJ="$CMD"; fi
SUBJ="$(printf '%s' "$SUBJ" | sed -E 's#://[^/@[:space:]]*@#://***@#g; s/(--password|--pass|--token|--api-key|--auth|-p)([= ]+)[^[:space:]]+/\1\2***/g
  s/([A-Za-z0-9_]*([Kk][Ee][Yy]|[Tt][Oo][Kk][Ee][Nn]|[Ss][Ee][Cc][Rr][Ee][Tt]|[Pp][Aa][Ss][Ss]|PAT|AUTH|CRED)[A-Za-z0-9_]*)=(\\"[^"]*\\"|[^[:space:]]*)/\1=***/g
  s/(-u|--user)([= ]+)[^[:space:]]*:[^[:space:]]*/\1\2***/g; s/([Bb]earer|[Tt]oken|[Bb]asic)[[:space:]]+[^[:space:]\\"]+/\1 ***/g')"
san() { printf '%s' "$1" | tr -c 'A-Za-z0-9 ._/:=@*+-' ' ' | cut -c1-"${2:-60}"; }
SAFE="$(san "$SUBJ" 120)"

SHA="$(git -C "$ROOT" rev-parse --short --verify -q HEAD 2>/dev/null || true)"
FULL="$(git -C "$ROOT" rev-parse --verify -q HEAD 2>/dev/null || true)"
MODE="$(printf '%s' "$PAYLOAD" |
  sed -nE 's/.*"permission_mode"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p')"
trace() { { mkdir -p "$ROOT/.attest/tmp" && printf '%s %s %s %s %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  "$1" "${SHA:--}" "${MODE:--}" "$SCAN" "$SAFE" >> "$ROOT/.attest/tmp/ship-guard.log"; } 2>/dev/null || true; }
# Every ask names its verdict first; ATTEST_GUARD=deny turns each into a deny, for where nobody answers.
ask() { _d=ask; [ "${ATTEST_GUARD:-}" != deny ] || _d=deny
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$_d" "$1"; }

if [ "${KIND:-}" = mcp ]; then
  trace mcp; ask "attest ship guard: MCP PUBLISH — $ACT ($SAFE). No record can clear bytes chosen in the call. Push through git instead, or approve only after checking them."
  exit 0
fi
if [ "${KIND:-}" = record ]; then
  trace record; ask "attest record guard: RECORD WRITE — $ACT ($SAFE). Approve only if /audit-history ran and this is its verdict: approving is the attestation."
  exit 0
fi

# Only a plain dry run passes: anything compound can hide a real push behind it.
# shellcheck disable=SC2016
case "$CMD" in
  *';'*|*'&'*|*'|'*|*'$('*|*'`'*|*'#'*|*'"'*|*"'"*|*"$NL"*|*'\n'*) ;;
  *) case " $NORM " in *" --no-d"*|*" -o --dry-run "*|*" --push-option --dry-run "*) ;; *" --dry-run "*) trace dryrun; exit 0 ;; esac ;;
esac
record_head_sha() {
  sed -n '/^- HEAD:/{p;q;}' "$1" 2>/dev/null | tr -d '\r' |
    sed -n 's/^- HEAD:[[:space:]]*\([0-9a-fA-F]\{7,\}\).*/\1/p' | tr 'A-F' 'a-f'
}
# The records naming commit $1: none (empty), `clean`, or `blocked <the first failing record>`.
records_for() {
  set +f; _f=
  for rec in "$ROOT"/.attest/ship-*.md; do
    _r="$(record_head_sha "$rec")"
    case "$1" in "${_r:--}"*) ;; *) continue ;; esac
    if sed -n '/^- findings:/{p;q;}' "$rec" | tr -d '\r' | grep -Eq '^- findings:[^0-9]*0 blocker'
    then _f="${_f:-clean}"; else [ "${_f%% *}" = blocked ] || _f="blocked ${rec##*/}"; fi
  done 2>/dev/null
  echo "$_f"
}
# HEAD carries records for S when no commit in S..HEAD is a merge and each adds regular files
# .attest/ship-*.md and nothing else, one of the 10 newest records names S, and no record for S or
# a commit above it reports a blocker. Such an S lies on HEAD's line, which the walk follows.
carrier() {
  export GIT_NO_REPLACE_OBJECTS=1 GIT_GRAFT_FILE=/dev/null; set +f; set -- "$ROOT"/.attest/ship-*.md; [ $# -le 10 ] || shift $(($# - 10))
  _ss="$(git -C "$ROOT" log --no-show-signature --no-relative --ignore-submodules=none --no-abbrev --raw \
    --format='commit %H %P' HEAD -- 2>/dev/null | awk -F '\t' -v p="$(git -C "$ROOT" rev-parse --show-prefix 2>/dev/null)" '
    /^commit / { split($0, c, " "); if (h && !k) exit; if (h) print c[2]; if (c[4] != "") exit; h = 1; k = 0; next }
    NF { if ($1 !~ "^:000000 100644 0+ [0-9a-f]+ A$" || substr($2, 1, length(p)) != p ||
      substr($2, length(p) + 1) !~ "^[.]attest/ship-[^/]*[.]md$") exit; k++ }')"
  for _s in $_ss; do
    _st="$(records_for "$_s")"; [ "${_st%% *}" != blocked ] || return 1; [ "$_st" = clean ] || continue
    for rec in "$@"; do
      _r="$(record_head_sha "$rec")"
      case "$_s" in "${_r:--}"*) git -C "$ROOT" rev-parse --short "$_s"; return 0 ;; esac
    done
  done
  return 1
}

# The scan can only add a question. The tool's own --timeout calls a partial scan clean, so a
# watchdog kills it at ATTEST_LEAK_SCAN_SECONDS (1..540, default 30); anything but 0 or 42 is an
# error. A secret on any unpushed branch or tag asks: the command cannot say what ships.
LEAK_RANGE="HEAD --branches --tags --not --remotes"
if [ -n "$FULL" ]; then
  case "$NORM" in
    *"git push"*)
      if [ "${ATTEST_LEAK_SCAN:-on}" = off ]; then SCAN=off
      elif ! command -v betterleaks >/dev/null 2>&1; then SCAN=absent
      else
        _limit="${ATTEST_LEAK_SCAN_SECONDS:-30}"
        case "$_limit" in ''|*[!0-9]*) _limit=30 ;; esac
        { [ "$_limit" -ge 1 ] && [ "$_limit" -le 540 ]; } 2>/dev/null || _limit=30
        {
          (cd "$(git -C "$ROOT" rev-parse --show-toplevel)" && exec betterleaks git . --log-opts="$LEAK_RANGE" \
             --redact=100 --no-banner --exit-code 42) </dev/null >/dev/null 2>&1 & _bl=$!
          (sleep "$_limit"; kill "$_bl") </dev/null >/dev/null 2>&1 &
          _dog=$!
          wait "$_bl"; _rc=$?
          kill "$_dog" 2>/dev/null
        } 2>/dev/null
        case "$_rc" in 0) SCAN=clean ;; 42) SCAN=leak ;; *) SCAN=error ;; esac
      fi ;;
  esac
fi

# Allow-list: redirections dropped, each part up to the last push on a short list, the push a
# plain `git push` with known options and refspecs that resolve to HEAD, in this repository, and
# no ship command after it. A PR with no push is read the same way, but only to decide whether it
# may carry records.
SHAPE=; SHAPEDEC=nothead; _plain=0
if [ -n "$FULL" ]; then
  case "$NORM" in *"git push"*|*"gh pr create"*|*"gh pr new"*)
    TOP="$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null)"
    CWD="$(printf '%s' "$PAYLOAD" | sed -nE 's/.*"cwd"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p')"; CWD="${CWD:-$ROOT}"
    [ "$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null)" = "$TOP" ] ||
      SHAPE="The shell is in another repository, $(san "$CWD")"
    case "$CMD" in *'<('*|*'>('*) SHAPE="It holds a process substitution, which runs a command the guard cannot read" ;; esac
    _shape="$(printf '%s' "$CMD" | sed -E 's/\\n/;/g; s/\\//g; s/[0-9]*>&[0-9-]*//g; s/&>>?[[:space:]]*[^[:space:];|&]+//g
      s/[0-9]*>>?\|?[[:space:]]*[^[:space:];|&]+//g; s/[0-9]*<+[[:space:]]*[^[:space:];|&]+//g' | tr ';|&' '\n' | awk '
      function scan(k) { G = 0; V = 0; for (k = 1; k <= NF; k++) if ($k ~ /(^|\/)git(\.exe)?$/) { G = k; break }
        if (G) { for (k = G + 1; k <= NF && substr($k, 1, 1) == "-"; k++)
          if ($k ~ /^(-[cC]|--(git-dir|work-tree|namespace|config-env|exec-path|super-prefix))$/) k++
          if (k <= NF) V = k } }
      { r0 = $0; gsub(/[\042\047]/, ""); if (NF) { p[++n] = $0; r[n] = r0 } }
      END { for (i = 1; i <= n; i++) { $0 = p[i]; scan(); if (V && $V == "push") last = i }
        for (i = 1; i <= n && !last; i++) { $0 = p[i]; if ($1 == "gh" && $2 == "pr" && $3 ~ /^(create|new)$/) { last = i; pr = 1 } }; if (pr) print "pr"
        for (i = 1; i <= n; i++) if (i != last) { $0 = p[i]; scan(); if (!(V && $V == "push")) print "part " r[i] }
        if (!last) print "nopush"
        for (i = 1; i <= last; i++) { $0 = p[i]; scan(); bad = ""
          if (pr && i == last) { if (/[$`]/) print "unsafe $("; continue }
          ro = (G == 1 && V && $V ~ /^(status|diff|log|show|fetch|add|rev-parse)$/) || $1 ~ /^(echo|printf|ls|pwd|true|sleep|date|cat|head|tail|grep|wc|sort)$/
          if (!(V && $V == "push") && !ro && $1 != "cd" && $1 ~ /^[A-Za-z0-9._\/-]+$/) { print "pre " $1 " " (V ? $V : ""); continue }
          for (k = 1; k <= NF; k++) if ($k !~ /^[A-Za-z0-9._\/:@^~+=,%-]+$/) { bad = $k; break }
          if (bad != "") print "unsafe " bad
          else if (V && $V == "push" && G != 1) print "wrapped " $1
          else if (V && $V == "push") { m = 0
            for (k = 2; k < V; k++) if ($k == "-C") print "C " $(++k)
              else if ($k !~ /^(--no-pager|-P|--no-optional-locks)$/) { print "gopt " $k; if ($k ~ /^(-c|--[a-z-]+)$/) k++ }
            for (k = V + 1; k <= NF; k++) if ($k ~ /^(-o|--push-option)$/) k++
              else if ($k ~ /^-/) { if ($k !~ /^(-[uf46nqv]|--(set-upstream|force|force-with-lease(=.*)?|force-if-includes|no-force-if-includes|quiet|verbose|(no-)?progress|(no-)?verify|(no-)?atomic|porcelain|ipv4|ipv6|signed(=.*)?|no-signed|(no-)?thin|dry-run|push-option=.*))$/) print "opt " $k }
              else if (++m > 1) print "src " $k
            if (m < 2) print "plain" }
          else if ($1 == "cd" && NF == 2) print "cd " $2
          else if (!ro) print "pre " $1 " " (V ? $V : "") } }')"
    while read -r _k _v; do
      [ "$_k" != pr ] || { _plain="pr"; continue; }
      if [ "$_k" = part ]; then case "$_v" in "gh pr create"*|"gh pr new"*) ;; *) [ -n "$SHIPS" ] ||
        [ -z "$(ship_act "$(norm "$_v")")" ] || SHIPS="${_v%% *}" ;; esac; continue; fi
      [ -z "$SHAPE" ] || break
      case "$_k" in
        C) [ "$(cd "$CWD" 2>/dev/null && git -C "$_v" rev-parse --show-toplevel 2>/dev/null)" = "$TOP" ] ||
             SHAPE="It runs git in another directory, $(san "$_v")" ;;
        cd) _d="$(cd "$CWD" 2>/dev/null && cd "$_v" 2>/dev/null && pwd -P)"
            if [ -n "$_d" ] && [ "$(git -C "$_d" rev-parse --show-toplevel 2>/dev/null)" = "$TOP" ]; then CWD="$_d"
            else SHAPE="It changes directory to $(san "$_v") first"; fi ;;
        pre) SHAPE="It runs $(san "$_v") before the push, so the pushed commit may not exist yet"; SHAPEDEC=compound ;;
        gopt) SHAPE="It runs git with $(san "$_v"), which can change what a push sends" ;;
        opt) SHAPE="It pushes with $(san "$_v"), which the guard does not read as HEAD alone" ;;
        wrapped) SHAPE="It runs the push through $(san "$_v"), which can change what it sends" ;;
        unsafe) SHAPE="It holds $(san "$_v"), which the guard cannot read (a variable, a subshell, a glob)" ;;
        nopush) SHAPE="The guard could not read which push or pull request this is" ;;
        src) _s="${_v#+}"; _s="${_s%%:*}"
          case "$_s" in
            HEAD|@) ;;
            '') SHAPE="Its refspec $(san "$_v") names no commit to send" ;;
            *) [ "$(git -C "$ROOT" rev-parse --verify -q "$_s^{commit}" 2>/dev/null)" = "$FULL" ] ||
                 SHAPE="It pushes $(san "$_s"), which is not HEAD" ;;
          esac ;;
        plain) _plain=plain ;;
      esac
    done <<EOF
$_shape
EOF
    while read -r _k _v; do
      [ -z "$SHAPE" ] || break
      case "$_k=$_v" in
        =|push.recursesubmodules=check|push.recursesubmodules=no|push.recursesubmodules=false|submodule.recurse=false) ;;
        push.default=simple|push.default=current|push.default=upstream|remote.*.mirror=false) ;;
        push.default=*|remote.*) [ "$_plain" = plain ] &&
          SHAPE="Git's config sets $(san "$_k $_v"), so a plain push can send more than HEAD" ;;
        *) [ "$_plain" = pr ] || SHAPE="Git's config sets $(san "$_k $_v"), so a push can send submodules too" ;;
      esac
    done <<EOF
$(git -C "$ROOT" config --get-regexp '^(push\.default|push\.recursesubmodules|submodule\.recurse|remote\..*\.(push|mirror))$' 2>/dev/null)
EOF
    [ -z "$SHIPS" ] || { SHAPE="It runs $(san "$SHIPS") beside the push or PR, which sends data too"; SHAPEDEC=nothead; }
    if [ "$_plain" = pr ]; then [ -n "$SHAPE" ] || CARRY=1; [ -n "$SHIPS" ] || SHAPE=; else CARRY=1; fi ;;
  esac
fi

if [ -n "$FULL" ]; then
  # Every record naming HEAD must be clean (a later blocker still holds). A carrier is looked for
  # only once the push is read as shipping HEAD alone.
  RECORDS="$(records_for "$FULL")"
  if [ -z "$RECORDS" ] && [ -z "$SHAPE" ] && [ "$CARRY" = 1 ]; then AUDITED="$(carrier)" && RECORDS=clean; fi
  case "$RECORDS" in
    clean) if [ -z "$SHAPE" ] && [ "$SCAN" != leak ] && [ "$SCAN" != error ]; then trace "pass${AUDITED:+-carrier}"; exit 0; fi
      CLEAN_RECORD=1 ;;
    blocked*) DEC=blocked; V=BLOCKED; WHY="Record $(san "${RECORDS#blocked }") for HEAD $SHA reports a blocker, or has no readable header"
      NEXT="Fix it and re-run /audit-history; do not approve past it." ;;
    *) V="NO RECORD"; WHY="No clean /audit-history record names HEAD $SHA"
      NEXT="Run /audit-history, commit its record on its own, then push; or approve anyway." ;;
  esac
elif git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  V="NO HEAD"; WHY="This repository has no commit yet, so no record can name HEAD"; NEXT="Commit, run /audit-history, then retry; or approve."
else
  V="NO HEAD"; WHY="git found no repository here, or refused to read one"
  NEXT="Fix safe.directory and run /audit-history, or approve only if you mean this."
fi
# The decision word says what the record did; the scan column, what the scanner did.
if [ "$CLEAN_RECORD" = 1 ]; then
  if [ -n "$SHAPE" ] && [ "$SHAPEDEC" = compound ]; then DEC=compound; V="COMMIT FIRST"; NEXT="Commit in one command, push in the next."
  elif [ -n "$SHAPE" ]; then DEC=nothead; V="NOT HEAD"; NEXT="Push HEAD alone, or audit what it sends."
  else DEC=scanerr; V="SCAN FAILED"; SHAPE="betterleaks failed or passed its $_limit-second limit, so nothing unpushed was scanned"
    NEXT="Run it by hand; approving proceeds on the record alone."; fi
  WHY="$SHAPE"
fi
if [ "$SCAN" = leak ]; then
  [ "$DEC" != scanerr ] || DEC=leak; V=LEAK
  WHY="betterleaks found a secret in commits not yet on any remote"
  NEXT="Remove it, or add its Fingerprint to the top-level .betterleaksignore; list from there: betterleaks git . --log-opts='$LEAK_RANGE' --redact=100 --report-format json --report-path -"
fi
trace "${DEC:-ask}"
ask "attest ship guard: $V — $ACT ($SAFE). $WHY. $NEXT"
exit 0
