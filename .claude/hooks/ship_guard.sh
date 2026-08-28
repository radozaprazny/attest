#!/bin/sh
# PreToolUse(Bash) hook: make the ship boundary real (attest ADR-0028).
#
# /audit-history is the kit's ship gate — the check that no secret, no personal data and no
# client name leaves the machine. Until now it was purely advisory: you had to remember it,
# and the one command that makes the question irreversible is exactly the one you type when
# you are done thinking. This hook asks at that moment instead.
#
# It ASKS, it does not forbid: the answer is a permission prompt you can approve. A guard that
# cannot be overridden gets deleted; one that states what is missing gets used.
#
# Evidence is a run record /audit-history appends under .attest/ whose name carries the short
# SHA of the commit being shipped — so the check is "was THIS state audited", not "did you ever
# run it". Fail-open everywhere: no payload, no git, no match => the command proceeds untouched.

set -u

ROOT="${CLAUDE_PROJECT_DIR:-.}"
PAYLOAD="$(cat 2>/dev/null || true)"
[ -n "$PAYLOAD" ] || exit 0

# The Bash command out of the JSON payload. sed, not a JSON parser: the value is only ever
# matched against fixed patterns below, never executed, so a payload this cannot parse falls
# back to the whole blob — which over-matches into an extra prompt at worst, never a miss.
# -E, not BRE: \| alternation is a GNU extension and undefined on BSD/macOS sed, where the
# extraction would silently return nothing and the fallback below would put raw JSON in the
# prompt text.
CMD="$(printf '%s' "$PAYLOAD" |
  sed -nE 's/.*"command"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p')"
[ -n "$CMD" ] || CMD="$PAYLOAD"

# What "leaving the machine" means. Deliberately literal and short: every entry is a command
# that publishes, submits or uploads. Add your project's own here — a Kaggle submit, a deploy
# script — rather than making the patterns clever.
case "$CMD" in
  *"git push"*|*"git send-email"*) ;;
  *"gh pr create"*|*"gh release create"*|*"gh gist create"*) ;;
  *"npm publish"*|*"twine upload"*|*"cargo publish"*|*"docker push"*) ;;
  *"kaggle"*"submit"*) ;;
  *"scp "*|*"rsync"*) ;;
  *"aws s3 cp"*|*"aws s3 sync"*|*"gsutil cp"*) ;;
  *"--upload-file"*|*"curl"*" -T "*) ;;
  *) exit 0 ;;
esac

# A dry run publishes nothing — but only when the dry run is the WHOLE command. In a compound
# command the flag may belong to a different call than the one that ships
# (`git push --dry-run && git push origin main`), so judge those as a whole and ask.
NL='
'
case "$CMD" in
  # a compound command — ';' '&&' '||' '|' or a newline, the last of which survives JSON
  # escaping as the two characters \n
  *';'*|*'&&'*|*'||'*|*'|'*|*"$NL"*|*'\n'*) ;;
  *--dry-run*) exit 0 ;;
esac

SHA="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || true)"
if [ -n "$SHA" ]; then
  for rec in "$ROOT"/.attest/ship-*"$SHA"*.md; do
    [ -e "$rec" ] && exit 0
  done
  WHY="no /audit-history run record for HEAD ($SHA) under .attest/"
else
  WHY="this is not a git checkout, so no ship record could be matched"
fi

# Only characters that cannot break the JSON string survive into the reason.
SAFE="$(printf '%s' "$CMD" | tr -c 'A-Za-z0-9 ._/:=@-' ' ' | cut -c1-120)"

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' \
  "attest ship gate: this command sends data off the machine ($SAFE) and $WHY. Run /audit-history first (full before a public release), or approve to ship unaudited."

exit 0
