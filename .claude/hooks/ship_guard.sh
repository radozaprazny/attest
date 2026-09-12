#!/bin/sh
# PreToolUse hook on Bash and on the publish tools of an MCP server: make the ship boundary
# real (attest ADR-0028, widened past the shell by ADR-0055).
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

# WHICH TOOL this call is, which is the question the `case` below cannot ask (attest ADR-0055).
# The kit registers this hook twice: once for `Bash`, once for the publish tools of a GitHub MCP
# server — those ship bytes without ever opening a shell, so no command string exists to match.
#
# Split on commas and take the FIRST match rather than letting `.*` run greedy to the last one:
# a `push_files` payload carries file CONTENT, and a repo whose own files quote the string
# `"tool_name"` (this one does) would otherwise have the quoted copy read as the key. Failing to
# extract is not a miss either — an unparsed MCP payload falls through to the `case`, where
# `CMD` is the whole blob and over-matches into a prompt.
TOOL="$(printf '%s' "$PAYLOAD" | tr ',' '\n' |
  sed -nE 's/.*"tool_name"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | sed -n '1p')"

# The publish path that never opens a shell (attest ADR-0055). A GitHub MCP server pushes files,
# opens pull requests and creates repositories over the API, so `git push` is never typed and the
# `Bash` matcher never fires — the gate the README advertises was simply absent on that path,
# which is the "believed-but-false gate" ADR-0035 refuses everywhere else.
#
# For this arm the coverage lives in `.claude/settings.json`, not here, and that is deliberate:
# for Bash the matcher is the word `Bash` and the list of ship commands has to live in this file,
# but an MCP tool only ever reaches a hook the matcher NAMES. The matcher is therefore the list.
# Wiring a tool to this hook is the statement that it publishes, so anything `mcp__*` that gets
# here asks — wire the publish tools, not the whole server. Widen coverage in that file.
#
# It ASKS UNCONDITIONALLY and never consults a ship record, unlike every arm below. A record
# attests the tree at a HEAD sha; these calls send bytes chosen IN the call, which need not be
# in git at all and need not match HEAD. "This state was audited" is therefore not a claim a
# record can make about them, and a guard that passes on evidence about something else is worse
# than one that asks every time (ADR-0035).
case "$TOOL" in
  mcp__*create_repository*) KIND=mcp
    ACT="creates a repository and can publish what you send to it" ;;
  mcp__*) KIND=mcp
    ACT="sends data off the machine without going through a shell" ;;
esac

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
# `|| case` rather than an `if` wrapping the whole block: the MCP arm above has already decided,
# and re-indenting these arms to nest them would obscure the one list a reader comes here to read.
[ -n "${KIND:-}" ] || case "$CMD" in
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
  # Not here any more: the record arm, which is judged per command PART below (ADR-0057).
  # A `*)` that exits would take every command the record check still has to see.
  *) ;;
esac

# Writing the evidence is itself an event worth a human (attest ADR-0051). A record is an
# ordinary untracked file, so anything that can write a file can write one — including the agent
# whose work the record attests. This covers the shapes a shell actually uses to write; a
# determined path (an editor, `python -c`) is not covered and is not meant to be. The boundary
# this kit defends is forgetting, not an adversary — see README. In-place editors belong here
# too (attest ADR-0054): `sed -i` is not an exotic path, it is how a shell edits a file it
# already has, and it is the shape that turns `1 blocker` into `0 blocker` without ever opening
# the Write tool.
#
# Judged one command PART at a time, unlike every arm above (attest ADR-0057). As a single
# whole-command `case`, `*">"*".attest/ship-"*` read a redirect belonging to one command and a
# record path belonging to another as a write: `grep -c . README.md > /tmp/n && ls
# .attest/ship-a.md` only READS the record and still asked, and `cp x y && ls .attest/ship-a.md`
# the same. An over-prompt rather than a miss, so it never opened a door — but a prompt on
# reading is exactly what ADR-0054 refused to buy, because it trains the click-through that
# makes the arms that DO gate something worthless. Splitting first costs one `tr` and keeps
# every real write: a redirect and its target are in the same part by definition.
#
# `sed 's/\\n/;/g'` first, because a newline survives JSON escaping as the two characters \n;
# then `>` is glued to its target so the spaced spelling needs no second pattern; `>` BEFORE the
# path is what separates writing a record from reading one into something else (`cat
# .attest/ship-a.md >/tmp/x`).
if [ -z "${ACT:-}" ]; then
  _parts="$(printf '%s' "$CMD" | sed 's/\\n/;/g' | tr ';|&' '\n' | sed 's/>[[:space:]]*/>/g')"
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

# Nothing this hook knows about — the command proceeds untouched, and leaves no trace line, so
# an empty log means only that nothing it recognises ran (GUIDE 2.2).
[ -n "${ACT:-}" ] || exit 0

# Only characters that cannot break the JSON string survive into the reason — and into the
# trace below, so one sanitisation serves both.
# What the prompt and the trace will name. For an MCP call there is no command to quote, and
# quoting the payload would put file content — possibly the very secret being shipped — into a
# prompt and into a log on disk. The tool name is the whole subject (attest ADR-0055).
if [ "${KIND:-}" = mcp ]; then SUBJ="$TOOL"; else SUBJ="$CMD"; fi
SAFE="$(printf '%s' "$SUBJ" | tr -c 'A-Za-z0-9 ._/:=@-' ' ' | cut -c1-120)"

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

# The MCP arm answers here, before the dry-run and record arms below: both of those read `$CMD`,
# which for an MCP call is the raw payload, so `--dry-run` appearing anywhere in a file being
# pushed would otherwise wave the push through (attest ADR-0055).
if [ "${KIND:-}" = mcp ]; then
  trace mcp
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' \
    "attest ship gate: this tool call $ACT ($SAFE). No ship record can clear it: a record attests the tree at a commit, and this call sends bytes chosen in the call, which need not be committed or match HEAD (${SHA:-none}) at all. Run /audit-history over what you are about to send, or push through git so the record covers it."
  exit 0
fi

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
