#!/bin/sh
# attest ship guard: PreToolUse on the shell tools and on MCP publish tools. It asks, and never
# denies, before anything leaves the machine. In order:
#   MCP publish tool   always asks: no record covers bytes chosen in the call
#   ship list          the commands that send data off the machine
#   record write       writing .attest/ship-*.md asks: that write is the attestation
#   dry run            a plain `--dry-run` passes, traced
#   leak scan          betterleaks, when installed, over every unpushed branch and tag
#   push shape         a record speaks for HEAD, so the push has to ship HEAD alone
#   record lookup      every record naming HEAD must read `findings: 0 blocker`
#   prompt             otherwise ask, saying what is missing; every decision is traced
# No payload or no match: the command proceeds. No HEAD: it asks.

set -uf
export LC_ALL=C
# The hook's own state starts empty, whatever the session's environment holds.
KIND=; ACT=; DEC=; CLEAN_RECORD=0; SCAN=-; NOHEAD_NEXT=

ROOT="${CLAUDE_PROJECT_DIR:-.}"
PAYLOAD="$(cat 2>/dev/null || true)"
[ -n "$PAYLOAD" ] || exit 0
CMD="$(printf '%s' "$PAYLOAD" |
  sed -nE 's/.*"command"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p')"
[ -n "$CMD" ] || CMD="$PAYLOAD"
TOOL="$(printf '%s' "$PAYLOAD" | tr ',' '\n' |
  sed -nE 's/.*"tool_name"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | sed -n '1p')"

# Quotes go and git's own options (-C dir, -c k=v, …) are skipped: every spelling reads the same.
NORM="$(printf '%s' "$CMD" | awk '
  {
    gsub(/[\042\047]/, "")
    out = ""
    for (i = 1; i <= NF; i++) {
      out = (out == "" ? $i : out " " $i)
      if ($i ~ /git$/)
        while (i < NF && substr($(i+1), 1, 1) == "-") {
          if ($(i+1) ~ /^(-[cC]|--(git-dir|work-tree|namespace|config-env|attr-source))$/) i++
          i++
        }
    }
    print out
  }' 2>/dev/null)"
[ -n "$NORM" ] || NORM="$CMD"
case "$TOOL" in
  mcp__*create_repository*) KIND=mcp
    ACT="creates a repository and can publish what you send to it" ;;
  mcp__*) KIND=mcp
    ACT="sends data off the machine without going through a shell" ;;
esac
[ -n "${KIND:-}" ] || case "$NORM" in
  *"git push"*|*"git send-email"*) ACT="sends data off the machine" ;;
  *"gh pr create"*|*"gh release create"*|*"gh gist create"*) ACT="sends data off the machine" ;;
  *"npm publish"*|*"twine upload"*|*"cargo publish"*|*"docker push"*) ACT="sends data off the machine" ;;
  *"yarn publish"*|*"bun publish"*|*"uv publish"*) ACT="sends data off the machine" ;;
  *"poetry publish"*|*"gem push"*|*"gh release upload"*) ACT="sends data off the machine" ;;
  *"kaggle"*"submit"*) ACT="sends data off the machine" ;;
  *"scp "*|*"rsync"*) ACT="sends data off the machine" ;;
  *"aws s3 cp"*|*"aws s3 sync"*|*"gsutil cp"*) ACT="sends data off the machine" ;;
  *"--upload-file"*|*"curl"*" -T "*) ACT="sends data off the machine" ;;
  *"gh repo edit"*"--visibility"*|*"gh repo create"*)
    ACT="changes who can read this repository, its whole history included" ;;
  *) ;;
esac

if [ -z "${ACT:-}" ]; then
  _parts="$(printf '%s' "$NORM" | sed 's/\\n/;/g; s/>|/>/g' | tr ';|&' '\n' | sed 's/>[[:space:]]*/>/g')"
  _oifs="$IFS"; IFS='
'
  for _part in $_parts; do
    case "$_part" in
      *">"*".attest/ship-"*|*"tee"*".attest/ship-"*|*"cp "*".attest/ship-"*|\
      *"mv "*".attest/ship-"*|*"sed -i"*".attest/ship-"*|*"sed --in-place"*".attest/ship-"*|\
      *"perl -pi"*".attest/ship-"*|*"truncate"*".attest/ship-"*)
        KIND=record; ACT="writes a ship record — the file this gate reads as evidence"; break ;;
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
ask() { printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$1"; }

if [ "${KIND:-}" = mcp ]; then
  trace mcp
  ask "attest ship gate: this tool call $ACT ($SAFE). No ship record can clear it: a record attests the tree at a commit, and this call sends bytes chosen in the call, which need not be committed or match HEAD (${SHA:-none}) at all. Run /audit-history over what you are about to send, or push through git so the record covers it."
  exit 0
fi

# Only a plain dry run passes: anything compound can hide a real push behind it.
NL='
'
# shellcheck disable=SC2016
case "$CMD" in
  *';'*|*'&'*|*'|'*|*'$('*|*'`'*|*'#'*|*'"'*|*"'"*|*"$NL"*|*'\n'*) ;;
  *) case " $NORM " in
       *" --dry-run "*) trace dryrun; exit 0 ;;
     esac ;;
esac

if [ "${KIND:-}" = record ]; then
  trace record
  ask "attest ship gate: this command $ACT ($SAFE). Approve only if /audit-history actually ran and this is its verdict — nothing in the tooling can tell a written record from an earned one, so this prompt is the step that makes it an attestation rather than a claim."
  exit 0
fi
record_head_sha() {
  sed -n '/^- HEAD:/{p;q;}' "$1" 2>/dev/null | tr -d '\r' |
    sed -n 's/^- HEAD:[[:space:]]*\([0-9a-fA-F][0-9a-fA-F]*\).*/\1/p' | tr 'A-F' 'a-f'
}
record_is_clean() {
  sed -n '/^- findings:/{p;q;}' "$1" 2>/dev/null | tr -d '\r' |
    grep -Eq '^- findings:[^0-9]*0 blocker'
}

# The scan can only add a question. The tool's own --timeout calls a partial scan clean, so a
# watchdog kills it at ATTEST_LEAK_SCAN_SECONDS (1..540, default 30); anything but 0 or 42 is an
# error. A secret on any unpushed branch or tag asks: the command cannot say what ships.
LEAK_RANGE="HEAD --branches --tags --not --remotes"
if [ -n "$FULL" ]; then
  case "$NORM" in
    *"git push"*)
      if [ "${ATTEST_LEAK_SCAN:-on}" = off ]; then
        SCAN=off
      elif ! command -v betterleaks >/dev/null 2>&1; then
        SCAN=absent
      else
        _limit="${ATTEST_LEAK_SCAN_SECONDS:-30}"
        case "$_limit" in ''|*[!0-9]*) _limit=30 ;; esac
        { [ "$_limit" -ge 1 ] && [ "$_limit" -le 540 ]; } 2>/dev/null || _limit=30
        {
          (cd "$ROOT" && exec betterleaks git . --log-opts="$LEAK_RANGE" \
             --redact=100 --no-banner --exit-code 42) </dev/null >/dev/null 2>&1 &
          _bl=$!
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
# plain `git push` with known options and refspecs that resolve to HEAD, in this repository.
SHAPE=; SHAPEDEC=nothead; _plain=0
if [ -n "$FULL" ]; then
  case "$NORM" in *"git push"*)
    TOP="$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null)"
    CWD="$(printf '%s' "$PAYLOAD" | sed -nE 's/.*"cwd"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p')"
    CWD="${CWD:-$ROOT}"
    [ "$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null)" = "$TOP" ] ||
      SHAPE="the shell is in another repository, $(san "$CWD")"
    _shape="$(printf '%s' "$CMD" | sed -E 's/\\n/;/g; s/\\//g; s/[0-9]*>&[0-9-]*//g; s/&>>?[[:space:]]*[^[:space:];|&]+//g
      s/[0-9]*>>?\|?[[:space:]]*[^[:space:];|&]+//g; s/[0-9]*<+[[:space:]]*[^[:space:];|&]+//g' | tr ';|&' '\n' | awk '
      function scan(k) { G = 0; V = 0; for (k = 1; k <= NF; k++) if ($k ~ /(^|\/)git$/) { G = k; break }
        if (G) { for (k = G + 1; k <= NF && substr($k, 1, 1) == "-"; k++)
          if ($k ~ /^(-[cC]|--(git-dir|work-tree|namespace|config-env|exec-path|super-prefix))$/) k++
          if (k <= NF) V = k } }
      { gsub(/[\042\047]/, ""); if (NF) p[++n] = $0 }
      END { for (i = 1; i <= n; i++) { $0 = p[i]; scan(); if (V && $V == "push") last = i }
        if (!last) print "nopush"
        for (i = 1; i <= last; i++) { $0 = p[i]; scan(); bad = ""
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
          else if (!(G == 1 && V && $V ~ /^(status|diff|log|show|fetch|add|rev-parse)$/) && $1 !~ /^(echo|printf|ls|pwd|true|sleep|date|cat|head|tail|grep|wc|sort)$/)
            print "pre " $1 " " (V ? $V : "") } }')"
    while read -r _k _v; do
      [ -z "$SHAPE" ] || break
      case "$_k" in
        C) [ "$(cd "$CWD" 2>/dev/null && git -C "$_v" rev-parse --show-toplevel 2>/dev/null)" = "$TOP" ] ||
             SHAPE="it runs git in another directory, $(san "$_v")" ;;
        cd) _d="$(cd "$CWD" 2>/dev/null && cd "$_v" 2>/dev/null && pwd -P)"
            if [ -n "$_d" ] && [ "$(git -C "$_d" rev-parse --show-toplevel 2>/dev/null)" = "$TOP" ]; then CWD="$_d"
            else SHAPE="it changes directory to $(san "$_v") before it pushes"; fi ;;
        pre) SHAPE="it runs $(san "$_v") before the push, so the commit it pushes may not exist yet"; SHAPEDEC=compound ;;
        gopt) SHAPE="it runs git with $(san "$_v"), which can change what a push sends" ;;
        opt) SHAPE="it pushes with $(san "$_v"), which the guard does not read as HEAD alone" ;;
        wrapped) SHAPE="it runs the push through $(san "$_v"), which can change what it sends" ;;
        unsafe) SHAPE="it holds $(san "$_v"), which the guard cannot read (a variable, a subshell, a glob)" ;;
        nopush) SHAPE="the guard could not read which push this is" ;;
        src) _s="${_v#+}"; _s="${_s%%:*}"
          case "$_s" in
            HEAD|@) ;;
            '') SHAPE="its refspec $(san "$_v") names no commit to send" ;;
            *) [ "$(git -C "$ROOT" rev-parse --verify -q "$_s^{commit}" 2>/dev/null)" = "$FULL" ] ||
                 SHAPE="it pushes $(san "$_s"), which is not HEAD" ;;
          esac ;;
        plain) _plain=1 ;;
      esac
    done <<EOF
$_shape
EOF
    while read -r _k _v; do
      [ -z "$SHAPE" ] || break
      case "$_k=$_v" in
        =|push.recursesubmodules=check|push.recursesubmodules=no|push.recursesubmodules=false|submodule.recurse=false) ;;
        push.default=simple|push.default=current|push.default=upstream|remote.*.mirror=false) ;;
        push.default=*|remote.*) [ "$_plain" = 1 ] &&
          SHAPE="git's config sets $(san "$_k $_v"), so a plain push can send more than HEAD" ;;
        *) SHAPE="git's config sets $(san "$_k $_v"), so a push can send submodules too" ;;
      esac
    done <<EOF
$(git -C "$ROOT" config --get-regexp '^(push\.default|push\.recursesubmodules|submodule\.recurse|remote\..*\.(push|mirror))$' 2>/dev/null)
EOF
    ;;
  esac
fi

if [ -n "$FULL" ]; then
  # Every record naming HEAD must be clean (a later blocker still holds); the glob needs set +f.
  FOUND=0
  BAD=0
  set +f
  for rec in "$ROOT"/.attest/ship-*.md; do
    [ -e "$rec" ] || continue
    _r="$(record_head_sha "$rec")"
    case "$_r" in [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]*) ;; *) continue ;; esac
    case "$FULL" in "$_r"*) ;; *) continue ;; esac
    FOUND=1
    record_is_clean "$rec" || BAD=1
  done
  if [ "$FOUND" = 1 ] && [ "$BAD" = 0 ]; then
    if [ -z "$SHAPE" ]; then
      case "$SCAN" in
        leak|error) ;;
        *) trace pass; exit 0 ;;
      esac
    fi
    CLEAN_RECORD=1
    WHY="a clean /audit-history record for HEAD ($SHA) exists"
  elif [ "$FOUND" = 1 ]; then
    DEC=blocked
    WHY="a /audit-history record for HEAD ($SHA) exists but not every record for this commit attests a clean scan — one of them reports a blocker, or predates the record format and carries no readable 'HEAD:' and 'findings: 0 blocker' header lines"
  else
    WHY="no /audit-history run record for HEAD ($SHA) under .attest/"
  fi
else
  if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    WHY="this repository has no commits yet, so there is no HEAD a ship record could name"
    NOHEAD_NEXT="Commit first and run /audit-history for that commit, or approve to proceed without a record."
  else
    WHY="git found no repository here, or refused to read one, so there is no HEAD a ship record could name"
    NOHEAD_NEXT="If this is a repository git refuses to read (safe.directory), make it readable and run /audit-history; otherwise no ship record can clear a command run here, so approve only if this is what you mean to send."
  fi
fi

NEXT="Run /audit-history first (full before a public release) and let it write a clean record for this HEAD, or approve to proceed on the evidence as it stands."
if [ -n "$NOHEAD_NEXT" ]; then NEXT="$NOHEAD_NEXT"; fi
if [ -n "$SHAPE" ]; then
  WHY="$WHY, but $SHAPE"
  [ "$CLEAN_RECORD" = 1 ] && DEC=$SHAPEDEC
  if [ "$CLEAN_RECORD" = 0 ]; then :
  elif [ "$SHAPEDEC" = compound ]; then
    NEXT="Run the commit as its own command and push in the next one, so the guard judges the commit that actually ships."
  else
    NEXT="Push HEAD alone (git push, or git push origin HEAD), or check out what this sends, run /audit-history there and push from it."
  fi
fi
# The decision word says what the record did; the scan column says what the scanner did.
case "$SCAN" in
  leak)
    [ "$CLEAN_RECORD" = 1 ] && [ -z "$SHAPE" ] && DEC=leak
    WHY="$WHY, but betterleaks found at least one secret in the commits not yet on any remote. The values are not repeated here; list them redacted, with the fingerprint each one needs to be ignored, using: betterleaks git . --log-opts='$LEAK_RANGE' --redact=100 --report-format json --report-path -"
    NEXT="Do not approve until that scan is clean: a secret pushed in one commit stays readable in history after a later commit deletes it. Remove it from the unpushed commits, or add the Fingerprint of a false positive to .betterleaksignore."
    ;;
  error)
    WHY="$WHY, but betterleaks is installed and did not finish (it failed, or passed its $_limit-second limit), so the commits not yet on any remote were not scanned"
    if [ "$CLEAN_RECORD" = 1 ] && [ -z "$SHAPE" ]; then
      DEC=scanerr
      NEXT="Run the scan by hand to see why: betterleaks git . --log-opts='$LEAK_RANGE' --redact=100. Approving proceeds on the record alone; a longer ATTEST_LEAK_SCAN_SECONDS, up to 540, gives a long history time to finish, and ATTEST_LEAK_SCAN=off stops the guard calling the scanner."
    fi
    ;;
esac
trace "${DEC:-ask}"
ask "attest ship gate: this command $ACT ($SAFE) and $WHY. $NEXT"
exit 0
