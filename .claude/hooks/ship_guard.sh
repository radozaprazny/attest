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
  function bare(x) { gsub(/\\*[\042\047]/, "", x); return x }
  function q(x) { gsub(/\\\\[\042\047]/, "", x); if (K == "" && match(x, /[\042\047]/)) K = substr(x, RSTART, 1); return K == "" ? 0 : gsub(K, "", x) }
  {
    out = ""
    for (i = 1; i <= NF; i++) {
      t = bare($i); sub(/\.([Ee][Xx][Ee]|[Cc][Mm][Dd]|[Pp][Ss]1|[Bb][Aa][Tt])$/, "", t)
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
# gh api, glab api, curl and PowerShell's web calls send data only with some options, so the raw
# command is cut into parts and words three ways, as reread does (quotes kept, kept until a newline,
# ignored): a GET in one part never clears a POST in the next. A body from a file, stdin or an
# expansion sends; an inline one is in the command itself. A GraphQL call sends a mutation.
sends() { printf '%s\n' "$1" | awk '
  BEGIN { G["--method"] = "X"; G["--field"] = "F"; G["--raw-field"] = "f"; G["--input"] = "<"
    split("data d data-binary d data-ascii d json d data-urlencode @ form F upload-file T config K", a, " ")
    for (k = 1; k < 16; k += 2) C["--" a[k]] = a[k + 1] }
  function val(r) { if (r != "") return r; i++; return w[i] }
  function hit(o, v) { if (c == "gh") { if (o == "X") m = toupper(v); else if (o ~ /^[fF<]$/) { f = 1; if (o == "<" || v ~ /(^|=)[@$`]/) at = 1 } }
    else if (o ~ /^[TK]$/ || (o == "d" && v ~ /^[@$`]/) || (o == "@" && v ~ /[@$`]/) || (o == "F" && v ~ /=[@<$`]/)) out = 1 }
  function judge(   x, b, o, v, t, k) { c = ""; m = ""; f = 0; at = 0; g = 0
    for (i = 1; i <= n; i++) { x = w[i]; b = x; sub(/.*\//, "", b)
      if (c == "") { if (b ~ /^(gh|glab)$/ && w[i + 1] == "api") { c = "gh"; i++ } else if (b == "curl") c = "curl"; continue }
      if (x == "graphql") g = 1
      else if (x ~ /^--/) { o = x; sub(/=.*/, "", o); v = (x ~ /=/) ? substr(x, index(x, "=") + 1) : ""
        if (c == "gh" && o in G) hit(G[o], val(v)); else if (c == "curl" && o in C) hit(C[o], val(v)) }
      else if (x ~ /^-[A-Za-z]/) { t = (c == "gh") ? "XfFHpqt" : "AbcCdDeEFHKmoPQrtTuUwxXyYz"
        for (k = 2; k <= length(x); k++) if (index(t, substr(x, k, 1))) { hit(substr(x, k, 1), val(substr(x, k + 1))); break } } }
    if (c == "gh" && (g ? (M || at) : ((m != "" || f) && m !~ /^(GET|HEAD)$/))) out = 1
    n = 0 }
  # A quoted run is taken whole: a character at a time is quadratic in some awks.
  function walk(mode,   j, ch, d, q, wd, r) { n = 0
    for (j = 1; j <= L + 1; j++) { ch = (j > L) ? ";" : substr(s, j, 1)
      if (ch == "\001" && mode == 1) q = ""
      if (j <= L && q != "" && ch != q && ch != "\\" && ch != "\001") { r = substr(s, j)
        match(r, q == "\047" ? "^[^\047\001]+" : "^[^\"\\\\\001]+"); wd = wd substr(r, 1, RLENGTH); j += RLENGTH - 1; continue }
      if (ch == "\\" && q != "\047") { d = substr(s, ++j, 1); if (d != "\001") wd = wd d; continue }
      if (q != "") { if (ch == q) q = ""; else wd = wd ch; continue }
      if (ch == "\"" || ch == "\047") { if (mode < 2) q = ch; continue }
      if (ch ~ /[ ;|&()\001]/) { if (wd != "") w[++n] = wd; wd = ""; if (ch != " ") judge(); continue }
      wd = wd ch } }
  { s = $0; gsub(/\\\\/, "\002", s); gsub(/\\"/, "\"", s); gsub(/\\[nr]/, "\001", s); gsub(/\\t/, " ", s); gsub(/\002/, "\\", s)
    L = length(s); M = (tolower(s) ~ /mutation/)
    out = (tolower(s) ~ /(invoke-webrequest|invoke-restmethod|iwr|irm|curl|wget)[^;|&]* (-inf|-form|[(]?get-content|[(]gc )/)
    walk(0); walk(1); walk(2); if (out) print "sends data off the machine" }'; }
# npm takes any prefix of publish from pu on; each is a whole word, so np\m pub\lish stays hidden.
ship_act() { set -- "$1 "; case "$1" in
  *"git push"*|*"git lfs push"*|*"git subtree push"*|*"git send-email"*|*"gh "*"pr create"*|*"gh "*"pr new"*|*"gh release create"*|*"gh gist create"*|\
  *"npm publish"*|*"npm pu "*|*"npm pub "*|*"npm publ "*|*"npm publi "*|*"npm publis "*|*"twine upload"*|*"cargo publish"*|*"docker push"*|*"docker image push"*|*"docker buildx"*"--push"*|\
  *"yarn publish"*|*"bun publish"*|*"uv publish"*|*"poetry publish"*|*"gem push"*|*"gh release upload"*|*"kaggle"*"submit"*|\
  *"scp "*":"*|*"scp "*'$'*|*"rsync "*":"*|*"rsync "*'$'*|*"aws s3 cp"*|*"aws s3 sync"*|*"gsutil cp"*|\
  *"--upload-file"*|*"curl"*" -T"*|*"pnpm"*" publish"*|*"docker"*"compose"*" push"*|\
  *"podman"*" push"*|*"buildah"*" push"*|*"skopeo"*" copy"*|*"skopeo"*" sync"*|*"gh "*"workflow run"*|*"glab "*"mr create"*|\
  *"glab "*"mr new"*|*"glab "*"ci run"*|*"glab "*"release create"*|*"glab "*"release upload"*|*"glab "*"snippet create"*|\
  *"aws"*"s3 mv"*|*"aws"*"s3api put-object"*|*"aws"*"s3api upload-part"*|*"gcloud"*"storage cp"*|*"gcloud"*"storage mv"*|\
  *"gcloud"*"storage rsync"*|*"az "*"storage"*" upload"*|*"az "*"storage"*" sync"*|*"az "*"storage copy"*|*"azcopy"*" copy"*|\
  *"azcopy"*" sync"*|*"rclone"*" copy"*|*"rclone"*"sync"*|*"rclone"*" move"*|*"rclone"*" rcat"*|*"wget"*"--post-file"*|\
  *"wget"*"--body-file"*|*"sftp "*|*"kaggle"*" create"*|*"kaggle"*" version "*|*"kaggle"*" push"*)
    echo "sends data off the machine" ;;
  *"gh repo edit"*"--visibility"*|*"gh repo create"*|*"glab "*"repo create"*) echo "changes who can read this repository" ;;
  *"gh api"*|*"glab api"*|*[Cc][Uu][Rr][Ll]*|*[Ii][Nn][Vv][Oo][Kk][Ee]-*|*[Ii][Ww][Rr]*|*[Ii][Rr][Mm]*) sends "$CMD" ;;
esac; }
[ -n "${KIND:-}" ] || ACT="$(ship_act "$NORM")"
# A second reading, of the still JSON-escaped command. Line 1: the command with continuations
# joined, other shell backslashes dropped and $'x' or $"x" read as "x". Line 2: `x` when a part
# starts with a ship tool the list cannot read: its subcommand is an expansion (a variable,
# substitution, $'…', brace, glob, extglob), its verb sits behind options (npm --silent publish),
# or git is handed an alias. The tool is looked for at the start of a part, past assignments and
# wrappers; quotes keep a value whole. A program name that is itself an expansion is not read.
reread() { awk 'BEGIN { TOOLS = "^(git|npm|yarn|bun|uv|poetry|twine|cargo|gem|docker|gh|kaggle|aws|gsutil)$" }
  # base: a word as a program name, with quotes, path, case and a Windows suffix gone.
  function base(x) { gsub(/["\047]/, "", x); sub(/.*[\/]/, "", x); x = tolower(x); sub(/\.(exe|cmd|ps1|bat)$/, "", x); return x }
  function part(   k, j, t, v, w, m, x) {
    for (k = 1; k <= nw; k++) if (W[k] !~ /^[A-Za-z_][A-Za-z0-9_]*=/ && W[k] !~ /^(if|while|until|then|do|else|[{!]|builtin)$/) break
    if (k > nw) return
    # Past a wrapper the program is the first word that names a ship tool or is an expansion. No
    # option of the wrapper is read, so no value of one can hide the tool.
    if (base(W[k]) ~ /^(sudo|env|nice|exec|xargs|timeout|stdbuf|command|nohup|time|setsid|ionice)$/) {
      for (j = k + 1; j <= nw; j++) if (base(W[j]) ~ TOOLS || (W[j] !~ /^-/ && W[j] ~ /[$`]/)) break
      if (j > nw) return; k = j }
    t = base(W[k])
    if (t ~ /[$`]/) { for (j = k + 1; j <= nw; j++) { w = W[j]; gsub(/["\047]/, "", w)
        if (w ~ /^(push|publish|upload|submit|send-email)$/) { f = 1; return } }; return }
    if (t !~ TOOLS) return
    if (t == "git" && tolower(P) ~ /alias\./) f = 1
    v = (t == "twine") ? "upload" : (t ~ /^(gem|docker)$/) ? "push" : (t == "gsutil") ? "cp|rsync|mv" : (t == "npm") ? "pu(b(l(i(sh?)?)?)?)?" : "publish"
    for (j = k + 1; j <= nw; j++) { w = W[j]
      if (w ~ /^[-+]/) { if (t == "git" && w ~ /^(-[cC]|--(git-dir|work-tree|namespace|config-env|attr-source))$/) j++; continue }
      m++; x = (w ~ /[$`{*?[]/); gsub(/["\047]/, "", w)
      if (x && (m == 1 || t !~ /^(gh|aws)$/)) { f = 1; return }
      if (t == "git") return
      if (t ~ /^(gh|aws)$/ && m == 1 && w !~ /^(pr|release|gist|repo|s3)$/ && W[j - 1] ~ /^-[^=]*$/) { m--; continue }
      if (t == "gh") { if (m == 1 && w ~ /^(pr|release|gist|repo)$/) continue; if (x) f = 1; return }
      if (t == "aws") { if (m == 1 && w == "s3") continue; if (x || (m == 2 && w ~ /^(cp|sync|mv)$/)) f = 1; return }
      if (w ~ ("^(" v ")$")) { f = 1; return }
      if (t == "docker" && w == "image") continue
      if (W[j - 1] !~ /^-[^=]*$/) return } }
  # One walk over r, splitting it into parts and words. A newline ends a part; with reset, it also
  # ends a quote, since an apostrophe in a comment or heredoc never closes. Both walks run: a
  # quoted string over several lines reads right only without the reset.
  function walk(reset,   i, c, w, q) {
    nw = 0; w = ""; q = ""; P = ""
    for (i = 1; i <= length(r) + 1; i++) { c = (i > length(r)) ? ";" : substr(r, i, 1)
      if (c == "\001") { if (reset) q = ""; if (q == "") c = ";" }
      if (q != "") { w = w c; P = P c; if (c == q) q = ""; continue }
      if (c == "\"" || c == "\047") { q = c; w = w c; P = P c; continue }
      if (c ~ /[ ;|&()]/) { if (w != "") W[++nw] = w; w = ""
        if (c != " ") { part(); nw = 0; P = "" } else P = P c; continue }
      w = w c; P = P c } }
  { s = $0; o = ""; n = length(s)
    for (i = 1; i <= n; i++) { c = substr(s, i, 1)
      if (c != "\\") { o = o c; continue }
      d = substr(s, ++i, 1)
      if (d == "n") { o = o "\001"; continue }
      if (d == "t") { o = o " "; continue }
      if (d != "\\") { o = o d; continue }
      if (substr(s, i + 1, 2) == "\\n") i += 2 }
    r = o; gsub(/\001/, ";", o); gsub(/[$]["\047]/, "\"", o); print o
    gsub(/[@+!][(]/, "$(", r); walk(1); walk(0)
    print (f ? "x" : "") }'; }
# A ship command seen only in the second reading always asks, record or not. A command with none
# of what can hide one (a shell backslash, an expansion, an alias, a tool the list reads only with
# no option before its verb) skips it. Beside a ship command seen first, every part it missed is read.
HIDDEN=; NL='
'
can_hide() { case "$1" in
  *\\[!\"]*|*'$'*|*'`'*|*'{'*|*'*'*|*'?'*|*'['*|*'@('*|*'+('*|*'!('*|*[Aa][Ll][Ii][Aa][Ss].*|\
  *npm*|*yarn*|*bun*|*uv*|*poetry*|*cargo*|*twine*|*gem*|*docker*|*aws*|*gsutil*) return 0 ;; esac; return 1; }
if [ -z "${KIND:-}" ] && can_hide "$CMD"; then
  if [ -z "$ACT" ]; then _x="$(printf '%s' "$CMD" | reread)"
    ACT="$(ship_act "$(norm "${_x%"$NL"*}")")"
    [ -n "$ACT" ] || [ "${_x##*"$NL"}" != x ] || ACT="sends data off the machine"
    [ -z "$ACT" ] || HIDDEN=1
  else _oifs="$IFS"; IFS="$NL"
    for _p in $(printf '%s' "$CMD" | sed 's/\\n/;/g' | tr ';|&()' '\n'); do
      can_hide "$_p" && [ -z "$(ship_act "$(norm "$_p")")" ] || continue; _x="$(printf '%s' "$_p" | reread)"
      [ -z "$(ship_act "$(norm "${_x%"$NL"*}")")" ] && [ "${_x##*"$NL"}" != x ] || { HIDDEN=1; break; }
    done; IFS="$_oifs"; fi
fi

# A record written in a push's own command would skip its prompt, so every shell command is read.
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
  trace record; ask "attest record guard: RECORD WRITE — $ACT ($SAFE). Approve only if /gate ran and this is its verdict: approving is the attestation."
  exit 0
fi

# Only a plain dry run passes: anything compound can hide a real push behind it, and an option
# before --dry-run can take it as its value, so --dry-run must follow the verb itself.
# shellcheck disable=SC2016
case "$CMD" in
  *';'*|*'&'*|*'|'*|*'$'*|*'<('*|*'>('*|*'`'*|*'#'*|*'"'*|*"'"*|*"$NL"*|*\\*|*'{'*|*'*'*|*'?'*|*'['*) ;;
  *' --repo'*|*' --exec'*|*' --receive-pack'*|*' --dry-run='*|*' --dry-run false'*) ;;
  *) case " $NORM " in *" --no-d"*) ;;
       *" push --dry-run "*|*" publish --dry-run "*|*" upload --dry-run "*|*" rsync --dry-run "*) trace dryrun; exit 0 ;; esac ;;
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
# A blocker there prints `blocked <record>` and returns 2, so the prompt says BLOCKED.
carrier() {
  export GIT_NO_REPLACE_OBJECTS=1 GIT_GRAFT_FILE=/dev/null; set +f; set -- "$ROOT"/.attest/ship-*.md; [ $# -le 10 ] || shift $(($# - 10))
  _ss="$(git -C "$ROOT" log --no-show-signature --no-relative --ignore-submodules=none --no-abbrev --raw \
    --format='commit %H %P' HEAD -- 2>/dev/null | awk -F '\t' -v p="$(git -C "$ROOT" rev-parse --show-prefix 2>/dev/null)" '
    /^commit / { split($0, c, " "); if (h && !k) exit; if (h) print c[2]; if (c[4] != "") exit; h = 1; k = 0; next }
    NF { if ($1 !~ "^:000000 100644 0+ [0-9a-f]+ A$" || substr($2, 1, length(p)) != p ||
      substr($2, length(p) + 1) !~ "^[.]attest/ship-[^/]*[.]md$") exit; k++ }')"
  for _s in $_ss; do
    _st="$(records_for "$_s")"; [ "${_st%% *}" != blocked ] || { echo "$_st"; return 2; }; [ "$_st" = clean ] || continue
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
          (sleep "$_limit"; kill -s KILL "$_bl") </dev/null >/dev/null 2>&1 &
          _dog=$!
          wait "$_bl"; _rc=$?
          kill -s KILL "$_dog" 2>/dev/null; wait "$_dog"
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
if [ -n "$HIDDEN" ]; then CARRY=; SHAPEDEC=nothead
  SHAPE="It spells a ship command with a backslash, \$'…' or a variable, which the guard cannot read"; fi

if [ -n "$FULL" ]; then
  # Every record naming HEAD must be clean (a later blocker still holds). A carrier is looked for
  # only once the push is read as shipping HEAD alone.
  RECORDS="$(records_for "$FULL")"
  if [ -z "$RECORDS" ] && [ -z "$SHAPE" ] && [ "$CARRY" = 1 ]; then AUDITED="$(carrier)"
    case $? in 0) RECORDS=clean ;; 2) RECORDS="$AUDITED"; AUDITED= ;; esac; fi
  case "$RECORDS" in
    clean) if [ -z "$SHAPE" ] && [ "$SCAN" != leak ] && [ "$SCAN" != error ]; then trace "pass${AUDITED:+-carrier}"; exit 0; fi
      CLEAN_RECORD=1 ;;
    blocked*) DEC=blocked; V=BLOCKED; WHY="Record $(san "${RECORDS#blocked }") reports a blocker, or has no readable header"
      NEXT="Fix the blocker and re-run /gate; do not approve past it." ;;
    *) V="NO RECORD"; WHY="No clean ship record names HEAD $SHA"
      NEXT="Run /gate, which commits its record, then push; or approve anyway." ;;
  esac
elif git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  _n="repository"; [ -z "$(git -C "$ROOT" rev-list -n 1 --all 2>/dev/null)" ] || _n="branch"
  V="NO HEAD"; WHY="This $_n has no commit yet, so no record can name HEAD"; NEXT="Commit, run /gate, then retry; or approve."
else
  V="NO HEAD"; WHY="git found no repository here, or refused to read one"
  NEXT="Fix safe.directory and run /gate, or approve only if you mean this."
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
