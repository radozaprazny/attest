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
# Evidence is a run record /audit-history appends under .attest/: its name carries the short SHA
# of the commit being shipped, and two of its lines are read — so the check is "was THIS state
# audited AND did it come back clean", not "did you ever run it" and not "does a file exist"
# (ADR-0028, narrowed by ADR-0037). Fail-open where it can be: no payload and no matching command
# => the command proceeds untouched. Outside a git checkout it ASKS instead — there is no HEAD to
# match a record against, so "audited" and "unaudited" are the same observation, and this file's
# rule is that an extra prompt beats a miss. The header used to claim fail-open there too; the code
# never did (attest ADR-0050).

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
  # Writing the evidence is itself an event worth a human (attest ADR-0051). A record is an
  # ordinary untracked file, so anything that can write a file can write one — including the
  # agent whose work the record attests. This arm covers the shapes a shell actually uses to
  # write; a determined path (an editor, `python -c`) is not covered and is not meant to be.
  # The boundary this kit defends is forgetting, not an adversary — see README.
  *">"*".attest/ship-"*|*"tee"*".attest/ship-"*|*"cp "*".attest/ship-"*|*"mv "*".attest/ship-"*)
    KIND=record; ACT="writes a ship record — the file this gate reads as evidence" ;;
  *) exit 0 ;;
esac

# Only characters that cannot break the JSON string survive into the reason — and into the
# trace below, so one sanitisation serves both.
SAFE="$(printf '%s' "$CMD" | tr -c 'A-Za-z0-9 ._/:=@-' ' ' | cut -c1-120)"

SHA="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || true)"
# The FULL sha is what a record is matched against (attest ADR-0050). `--short` is not a stable
# length: `core.abbrev` is a config value, and git widens the default as a repo grows — so two
# machines, or one machine before and after a `git config`, disagree about how many characters
# a record's `- HEAD:` line should carry. `$SHA` stays for what humans read: the trace and the
# prompt.
FULL="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || true)"

# The permission mode this call is being decided under, straight out of the payload. ADR-0034
# gave the log a line for every decision because "the hook did not fire" and "the hook fired and
# something auto-approved it" were indistinguishable afterwards; the mode is the other half of
# that answer, and it costs one sed (attest ADR-0050).
MODE="$(printf '%s' "$PAYLOAD" |
  sed -nE 's/.*"permission_mode"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p')"

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
      printf '%s %s %s %s %s\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "${SHA:--}" "${MODE:--}" "$SAFE" \
        >> "$ROOT/.attest/tmp/ship-guard.log"
  } 2>/dev/null || true
}

# A dry run publishes nothing — but only when the dry run is the WHOLE command. In a compound
# command the flag may belong to a different call than the one that ships
# (`git push --dry-run && git push origin main`), so judge those as a whole and ask.
#
# This branch sits AFTER trace() on purpose (attest ADR-0038). It used to sit above it, and a
# command that took it left no line at all — so a miss and an unregistered hook looked the same
# from the log, which is the one ambiguity ADR-0034 introduced the log to remove. A decision to
# let something through is still a decision; it gets a line.
NL='
'
case "$CMD" in
  # a compound command — ';' '&&' '||' '|' or a newline, the last of which survives JSON
  # escaping as the two characters \n
  *';'*|*'&&'*|*'||'*|*'|'*|*"$NL"*|*'\n'*) ;;
  *--dry-run*) trace dryrun; exit 0 ;;
esac

# A record write never reaches the evidence check below — it IS the evidence being made
# (attest ADR-0051). Its own reason, because the gate's ("no record for HEAD") would be
# nonsense here.
if [ "${KIND:-}" = record ]; then
  trace record
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' \
    "attest ship gate: this command $ACT ($SAFE). Approve only if /audit-history actually ran and this is its verdict — nothing in the tooling can tell a written record from an earned one, so this prompt is the step that makes it an attestation rather than a claim."
  exit 0
fi

# What the record has to SAY, not merely that it exists (attest ADR-0037). A filename cannot
# carry a verdict, so matching one only ever answered "was this state audited" — an empty file
# passed, and so did a record whose verdict was `blocker`. That made "audited" and "clean" the
# same word to this hook while its own prompt offered to "ship unaudited", i.e. it treated the
# two as opposites. Two lines of the record template (`/audit-history`) are load-bearing here:
#
#   - HEAD: <short sha> …
#   - findings: 0 blocker · …
#
# `[^0-9]*` before `0 blocker` is what keeps `1 blocker` and `10 blocker` out; anchoring on
# `^- ` keeps prose that merely mentions the words out.
# record_is_clean <file> — the FIRST `- HEAD:` line names this sha and the FIRST `- findings:`
# line begins `0 blocker`. First, not any: the record's prose is the author's and may quote
# either form at column 0, so two independent greps over the whole file could be satisfied by
# a sentence rather than by the header (attest ADR-0037). `sed -n '/…/{p;q;}'` rather than
# `grep -m1`, which is a GNU extension.
# record_head_sha <file> — the hex the FIRST `- HEAD:` line names, lowercased, or empty. `tr -d`
# takes the CR of a CRLF checkout with it: line endings are a property of the checkout, never of
# the verdict, and a guard that reads them as a verdict blames the record's age for the shell's
# problem (attest ADR-0050 — the `.gitattributes` pin stays, it is now belt and braces).
record_head_sha() {
  sed -n '/^- HEAD:/{p;q;}' "$1" 2>/dev/null | tr -d '\r' |
    sed -n 's/^- HEAD:[[:space:]]*\([0-9a-fA-F][0-9a-fA-F]*\).*/\1/p' | tr 'A-F' 'a-f'
}
# The case-fold is the LAST step, not the first. Folding the line before matching turns
# `- HEAD:` into `- Head:` — H is not in A-F, E A D are — so the anchor stops matching and every
# record goes invisible. The first draft of this function did exactly that, and the fixture that
# caught it was the control case: same abbreviation on both sides, which had passed for months.
# record_is_clean <file> — the FIRST `- findings:` line begins `0 blocker`. First, not any: the
# record's prose is the author's and may quote either form at column 0, so a grep over the whole
# file could be satisfied by a sentence rather than by the header (attest ADR-0037). `[^0-9]*`
# before `0 blocker` is what keeps `1 blocker` and `10 blocker` out.
record_is_clean() {
  sed -n '/^- findings:/{p;q;}' "$1" 2>/dev/null | tr -d '\r' |
    grep -Eq '^- findings:[^0-9]*0 blocker'
}

if [ -n "$FULL" ]; then
  # EVERY record for this sha has to be clean, not merely one of them. The glob expands
  # lexicographically, so "the first clean one wins" meant the OLDEST won — and the workflow the
  # prompt itself recommends produces exactly the bad case: a quick scan comes back clean, a
  # later `full` scan finds a blocker, and the push went through on the earlier file. A verdict
  # for a given tree state does not expire, so a blocker recorded against this sha still holds
  # (attest ADR-0037).
  #
  # Which records are ABOUT this commit is decided by what each one says, not by its filename
  # (attest ADR-0050). The old glob was `ship-*$SHA*.md` with `$SHA` from `--short`, so a record
  # written under a different `core.abbrev` was either invisible ("no record for HEAD", while it
  # sat right there) or found-but-unreadable ("reports a blocker, or predates the record format",
  # while it reported neither). Both diagnoses were false, and ADR-0037 exists to stop this hook
  # giving false diagnoses. A `- HEAD:` line naming any prefix of this commit, seven hex or
  # longer, is about this commit — that is what an abbreviated sha means. The filename keeps its
  # sha for people; it is no longer load-bearing for the machine.
  FOUND=0
  BAD=0
  for rec in "$ROOT"/.attest/ship-*.md; do
    [ -e "$rec" ] || continue
    _r="$(record_head_sha "$rec")"
    # seven hex minimum — shorter is not an abbreviation, it is a coincidence waiting to happen
    case "$_r" in [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]*) ;; *) continue ;; esac
    case "$FULL" in "$_r"*) ;; *) continue ;; esac
    FOUND=1
    record_is_clean "$rec" || BAD=1
  done
  if [ "$FOUND" = 1 ] && [ "$BAD" = 0 ]; then
    trace pass
    exit 0
  fi
  if [ "$FOUND" = 1 ]; then
    # A distinct word in the log — "a record exists and does not clear this" is a different
    # event from "no record at all", and only the log can tell them apart afterwards. One
    # decision, one line: it is traced at the single exit below, never here (attest ADR-0038).
    DEC=blocked
    WHY="a /audit-history record for HEAD ($SHA) exists but not every record for this commit attests a clean scan — one of them reports a blocker, or predates the record format and carries no readable 'HEAD:' and 'findings: 0 blocker' header lines"
  else
    WHY="no /audit-history run record for HEAD ($SHA) under .attest/"
  fi
else
  WHY="this is not a git checkout, so no ship record could be matched"
fi

trace "${DEC:-ask}"

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' \
  "attest ship gate: this command $ACT ($SAFE) and $WHY. Run /audit-history first (full before a public release) and let it write a clean record for this HEAD, or approve to proceed on the evidence as it stands."

exit 0
