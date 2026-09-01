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

# What "leaving your control" means. Deliberately literal and short: every entry either sends
# bytes off the machine or changes who may read the ones already sent. Add your project's own
# here — a Kaggle submit, a deploy script — rather than making the patterns clever. Each arm
# also sets what the prompt will claim the command does, because a guard that states a reason
# it cannot back is worse than one that stays quiet (attest ADR-0035).
#
# NOT here, on purpose: `gh pr merge`. By then every byte is already on the remote — put there
# by a push this guard did gate — so "sends data off the machine" would be a false claim; the
# merge commit does not exist yet, so no record could ever name it (ADR-0033); and most merges
# never touch this machine at all (the web button, auto-merge, a colleague), so matching only
# the CLI form would advertise a coverage this hook cannot have. That boundary belongs to
# branch protection and required CI, which are server-side and catch every path (ADR-0035).
case "$CMD" in
  *"git push"*|*"git send-email"*) ACT="sends data off the machine" ;;
  *"gh pr create"*|*"gh release create"*|*"gh gist create"*) ACT="sends data off the machine" ;;
  *"npm publish"*|*"twine upload"*|*"cargo publish"*|*"docker push"*) ACT="sends data off the machine" ;;
  *"kaggle"*"submit"*) ACT="sends data off the machine" ;;
  *"scp "*|*"rsync"*) ACT="sends data off the machine" ;;
  *"aws s3 cp"*|*"aws s3 sync"*|*"gsutil cp"*) ACT="sends data off the machine" ;;
  *"--upload-file"*|*"curl"*" -T "*) ACT="sends data off the machine" ;;
  # Not a transfer — a change of audience, and the one command whose blast radius is the whole
  # history rather than the current tree: every old blob and every commit you never re-read
  # becomes world-readable, irreversibly. `--visibility private` matches too. Narrowing to the
  # value would need a second pattern per spelling (`--visibility=public`), and this file's own
  # rule is that an extra prompt beats a miss.
  *"gh repo edit"*"--visibility"*|*"gh repo create"*)
    ACT="changes who can read this repository, its whole history included" ;;
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

# Only characters that cannot break the JSON string survive into the reason — and into the
# trace below, so one sanitisation serves both.
SAFE="$(printf '%s' "$CMD" | tr -c 'A-Za-z0-9 ._/:=@-' ' ' | cut -c1-120)"

SHA="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || true)"

# Leave a trace, for the pass as well as the ask (attest ADR-0034). A hook that decides
# silently cannot be told apart from one that was never registered — this repo hit exactly
# that: a push at a sha no record named went through with no prompt, and from inside the
# session "the guard did not fire" and "the guard fired and the permission mode auto-approved
# it" were indistinguishable. The pass is logged too, because a silent pass is the case that
# looked like a dead hook. `.attest/tmp/` is the kit's ignored scratch (ADR-0026 as narrowed by
# ADR-0034), so a trace is never committed and never mistaken for a record. Fail-open like
# everything else here: an unwritable repo loses the line, never the decision.
trace() { # trace <decision>
  {
    mkdir -p "$ROOT/.attest/tmp" &&
      printf '%s %s %s %s\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "${SHA:--}" "$SAFE" \
        >> "$ROOT/.attest/tmp/ship-guard.log"
  } 2>/dev/null || true
}

if [ -n "$SHA" ]; then
  for rec in "$ROOT"/.attest/ship-*"$SHA"*.md; do
    if [ -e "$rec" ]; then
      trace pass
      exit 0
    fi
  done
  WHY="no /audit-history run record for HEAD ($SHA) under .attest/"
else
  WHY="this is not a git checkout, so no ship record could be matched"
fi

trace ask

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' \
  "attest ship gate: this command $ACT ($SAFE) and $WHY. Run /audit-history first (full before a public release), or approve to ship unaudited."

exit 0
