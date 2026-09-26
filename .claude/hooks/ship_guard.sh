#!/bin/sh
# PreToolUse hook on the shell tools (Bash, and PowerShell — attest ADR-0073) and on the publish
# tools of an MCP server: make the ship boundary real (attest ADR-0028, widened past the shell by
# ADR-0058).
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
# => the command proceeds untouched. Outside a git checkout, and in a repository with no commits
# yet, it ASKS instead — there is no HEAD to match a record against, so "audited" and "unaudited"
# are the same observation, and this file's rule is that an extra prompt beats a miss. The header
# used to claim fail-open there too; the code never did (attest ADR-0050). The prompt names which
# of the two it is (attest ADR-0073).

set -u

# This hook's own state starts empty, whatever the session's environment holds (attest ADR-0070).
# Every one of these used to be read with `${VAR:-}` before anything set it, so a value inherited
# from the environment Claude Code was started in was honoured as if the hook had decided it —
# and one of them was a silent miss: with `KIND` set to anything, a `git push` with no record went
# through with no prompt, because a non-empty KIND skips the ship list. Measured on the guard as
# released in v0.9.0 before this line existed.
KIND=; ACT=; DEC=; CLEAN_RECORD=0; SCAN=-; NOHEAD_NEXT=

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

# WHICH TOOL this call is, which is the question the `case` below cannot ask (attest ADR-0058).
# The kit registers this hook twice: once for the shell tools, once for the publish tools of a
# GitHub MCP server — those ship bytes without ever opening a shell, so no command string exists
# to match.
#
# Split on commas and take the FIRST match rather than letting `.*` run greedy to the last one:
# a `push_files` payload carries file CONTENT, and a repo whose own files quote the string
# `"tool_name"` (this one does) would otherwise have the quoted copy read as the key. Failing to
# extract is not a miss either — an unparsed MCP payload falls through to the `case`, where
# `CMD` is the whole blob and over-matches into a prompt.
TOOL="$(printf '%s' "$PAYLOAD" | tr ',' '\n' |
  sed -nE 's/.*"tool_name"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | sed -n '1p')"

# NORMALISE BEFORE MATCHING (attest ADR-0069). The list below is literal substrings, and that is
# the point — a reader can check it against what they type. But a substring list reads SPELLING,
# and one command has many: `git  push` with two spaces, `git -C . push`, `git -c k=v push`,
# `git --no-pager push`, `git --work-tree /w push`. Every one of those was silent, so the gate
# the README advertises was a gate on one spelling of each command. (`bash -c "git push"` was
# NOT: the raw string carries the substring, so it asked before this change and has to keep
# asking after it — it is a control here, not a fix.) Three cheap passes make the spellings
# converge and leave the list itself untouched.
#
# What they do NOT converge is a quoted value holding a SPACE: `git -c user.name="John Doe" push`
# loses its quotes, `Doe` is read as the subcommand and the push goes through in silence — as it
# did before this file was touched. Tracking that needs to know a quoted run is one word, which
# is the parser this normalisation is explicitly not. It is written down in attest ADR-0069.
#
#   1. quotes are dropped, so a push written inside one word of them is still a push;
#   2. runs of whitespace collapse to one space, which awk's default field splitting does for
#      free (tabs included);
#   3. git's GLOBAL options are dropped from between the word `git` and its subcommand.
#
# SEVEN OF THOSE OPTIONS TAKE A SEPARATE ARGUMENT and have to lose it with them, or the argument
# becomes the subcommand and the walk stops one word short of `push`. The list is git's, not
# ours, and it was measured against `git version 2.43.0` rather than read off a man page:
# `-c` `-C` `--git-dir` `--work-tree` `--namespace` `--config-env` `--attr-source`.
# Getting this list wrong MISSES a push in both directions — an option left off it eats the
# subcommand, and a plain flag wrongly put on it eats `push` itself — which is why it is exact
# and why seven smoke cases pin it, one per entry. The `=` spellings need no entry:
# `--git-dir=/x` is one word, so it falls to the ordinary single-word skip.
#
# `--exec-path` LOOKS like it belongs here and does not, which is worth one line because the
# first version of this list had it. Given no `=`, git prints its exec path and exits without
# ever reaching the subcommand — so `git --exec-path /x push` pushes nothing, and normalising it
# to something that does not match is the correct answer rather than a miss. Only `--exec-path=`
# reaches a subcommand, and that spelling is one word.
#
# The walk goes left to right and never steps over a subcommand, which is what keeps it from
# inventing a push out of a git command that merely reads one: `git --no-pager log --grep push`
# loses `--no-pager`, and then `log` stops the walk, so it never becomes `git push`. It is not a
# parser, and the claim stops there — because the walk fires on any word ENDING in `git`, a
# non-git command can still be normalised into a match (`grep -r git -l push` becomes
# `grep -r git push` and asks). That direction costs a prompt, never a miss, which is the trade
# this file makes everywhere.
#
# Newlines survive on purpose — the record arm below splits on them (attest ADR-0060), and
# flattening them here would put a redirect from one command and a record path from another back
# in the same part, which is the exact bug that entry closed.
#
# $CMD itself is untouched: it is what the human is shown, and a prompt quoting a command nobody
# typed is a prompt nobody can check. If awk is missing or the program fails, $NORM falls back to
# $CMD and every arm matches exactly what it matched before this entry — a narrower gate, never
# an open one.
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

# The publish path that never opens a shell (attest ADR-0058). A GitHub MCP server pushes files,
# opens pull requests and creates repositories over the API, so `git push` is never typed and the
# `Bash` matcher never fires — the gate the README advertises was simply absent on that path,
# which is the "believed-but-false gate" ADR-0035 refuses everywhere else.
#
# For this arm the coverage lives in `.claude/settings.json`, not here, and that is deliberate:
# for a shell the matcher names the tool, `Bash|PowerShell`, and the list of ship commands has to
# live in this file, but an MCP tool only ever reaches a hook the matcher NAMES. The matcher is
# therefore the list.
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
#
# NOT here either: a script name — `npm run release`, `make deploy`. A registry's publish command
# means the same thing on every machine; `release` or `deploy` is whatever one project wrote into
# its package.json or Makefile, and a prompt claiming it "sends data off the machine" would state
# a reason this file cannot back. That is the "add your project's own" line above, not a gap
# (ADR-0072).
#
# `|| case` rather than an `if` wrapping the whole block: the MCP arm above has already decided,
# and re-indenting these arms to nest them would obscure the one list a reader comes here to read.
[ -n "${KIND:-}" ] || case "$NORM" in
  *"git push"*|*"git send-email"*) ACT="sends data off the machine" ;;
  *"gh pr create"*|*"gh release create"*|*"gh gist create"*) ACT="sends data off the machine" ;;
  # `npm publish` also catches `pnpm publish` and Yarn 2+'s `yarn npm publish` — as substrings,
  # which smoke.sh pins so that tightening this pattern cannot drop them unseen (ADR-0072).
  *"npm publish"*|*"twine upload"*|*"cargo publish"*|*"docker push"*) ACT="sends data off the machine" ;;
  *"yarn publish"*|*"bun publish"*|*"uv publish"*) ACT="sends data off the machine" ;;
  *"poetry publish"*|*"gem push"*|*"gh release upload"*) ACT="sends data off the machine" ;;
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
  # Not here any more: the record arm, which is judged per command PART below (ADR-0060).
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
# Judged one command PART at a time, unlike every arm above (attest ADR-0060). As a single
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
  _parts="$(printf '%s' "$NORM" | sed 's/\\n/;/g' | tr ';|&' '\n' | sed 's/>[[:space:]]*/>/g')"
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
# prompt and into a log on disk. The tool name is the whole subject (attest ADR-0058).
if [ "${KIND:-}" = mcp ]; then SUBJ="$TOOL"; else SUBJ="$CMD"; fi
SAFE="$(printf '%s' "$SUBJ" | tr -c 'A-Za-z0-9 ._/:=@-' ' ' | cut -c1-120)"

# `--verify -q`, never a bare `rev-parse HEAD`: in a repository with no commits yet the bare form
# prints the literal word `HEAD` on stdout before failing, `|| true` keeps it, and the guard then
# believed a HEAD existed — it scanned, failed, and asked about a record "for HEAD ()". Measured
# on the guard as released in v0.11.0 (attest ADR-0073).
SHA="$(git -C "$ROOT" rev-parse --short --verify -q HEAD 2>/dev/null || true)"
# The FULL sha is what a record is matched against (attest ADR-0050). `--short` is not a stable
# length: `core.abbrev` is a config value, and git widens the default as a repo grows — so two
# machines, or one machine before and after a `git config`, disagree about how many characters
# a record's `- HEAD:` line should carry. `$SHA` stays for what humans read: the trace and the
# prompt.
FULL="$(git -C "$ROOT" rev-parse --verify -q HEAD 2>/dev/null || true)"

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
#
# The fifth column is the leak scanner's outcome (attest ADR-0070): `-` where no scan was in
# question, then `off`, `absent`, `clean`, `leak` or `error`. It is a column and not a longer
# decision word so that neither fact hides the other — the decision still says what the RECORD
# did (`pass` · `ask` · `blocked`), and a `pass` now says whether a scanner looked at all, which is
# the question a scanner missing from a GUI session's PATH would otherwise leave unanswerable.
trace() { # trace <decision>
  {
    mkdir -p "$ROOT/.attest/tmp" &&
      printf '%s %s %s %s %s %s\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "${SHA:--}" "${MODE:--}" "$SCAN" "$SAFE" \
        >> "$ROOT/.attest/tmp/ship-guard.log"
  } 2>/dev/null || true
}

# The MCP arm answers here, before the dry-run and record arms below. Those read `$CMD` and
# `$NORM`, and for an MCP call both are built from the raw payload — so `--dry-run` appearing
# anywhere in a file being pushed would otherwise wave the push through (attest ADR-0058).
# Normalising changed nothing about why this ordering matters, only how many strings it is true
# of (attest ADR-0069).
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
#
# Both halves of that judgment were too loose, and each was a real command going through
# silently (attest ADR-0069). `git push --dry-run & git push origin main` held no `&&` and was
# waved through on the first half's flag; `--dry-run` was matched as a SUBSTRING, so
# `git push --push-option=--dry-run` — a value git hands to the server, not a dry run — read as
# one; and `gh pr create --body "adds a --dry-run flag"` opened a real pull request on the
# strength of a word in its own description. What follows asks for a SIMPLE, UNQUOTED command
# and a WHOLE WORD.
#
# Quoting is what separates those last two from a genuine dry run, and it is the cheapest
# reliable signal available here: `git push --dry-run` and `npm publish --dry-run` carry no
# quotes, while a flag named inside prose is quoted by definition. Deciding it any other way
# needs to know which options of which command take a value — a grammar this guard deliberately
# does not have. A quoted command that really is a dry run now asks; that is one prompt, against
# a publish that was silent.
NL='
'
# SC2016 is the point here, not a slip: `$(` is being matched as two literal characters, because
# what makes a command compound is that it CONTAINS a substitution, never what one expands to.
# shellcheck disable=SC2016
case "$CMD" in
  # Compound, or able to hold a second command: ';' '&' (which covers '&&' and a background
  # job) '|' (which covers '||') '$(' a backtick, a '#' comment that can park the flag out of
  # the shell's sight, or a newline — the last surviving JSON escaping as the two characters \n.
  # A quote of either kind joins them: it means some of this command is DATA, and a flag read
  # out of data is not a flag. In the payload a double quote arrives escaped, as \" — the
  # pattern below sees the quote character itself either way.
  *';'*|*'&'*|*'|'*|*'$('*|*'`'*|*'#'*|*'"'*|*"'"*|*"$NL"*|*'\n'*) ;;
  # A simple command, so the flag can only belong to it. Whole word, tested by padding both
  # sides with the single space $NORM has already collapsed every run of whitespace into: that
  # is what keeps `--push-option=--dry-run` and `--dry-run-ish` out while `git push --dry-run`
  # and `git  push  --dry-run` both stay in.
  *) case " $NORM " in
       *" --dry-run "*) trace dryrun; exit 0 ;;
     esac ;;
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

# THE LEAK SCANNER, WHEN ONE IS INSTALLED (attest ADR-0070). A ship record is a model's reading
# of a diff: stable on the primary finding, variable at the margins, and its key-shaped layer is
# the weakest thing it does. `betterleaks` is a maintained rule-pack, from the original author of
# gitleaks, that answers the one question a regex answers better than a model. So on `git push`
# — and only there — the guard runs it over the commits not yet on any remote.
#
# Four properties, each of them load-bearing, each pinned in smoke.sh:
#   - OPTIONAL. Not on PATH, or ATTEST_LEAK_SCAN=off, and nothing is scanned: every decision is
#     the one the guard made before this entry. The kit gains no dependency.
#   - IT CAN ONLY ADD A QUESTION. A leak or an unfinished scan takes a pass away; a clean scan
#     never turns an ask into a pass, because the record is the attestation and a regex is not.
#   - IT NEVER REPEATS THE SECRET. Everything the scanner prints goes to /dev/null, and the prompt
#     names a REDACTED command that lists the findings. Measured: without `--redact` a verbose run
#     prints the secret, so the first draft of that advice would have put it into the transcript
#     the moment someone asked the model to run it (the reasoning of attest ADR-0058).
#   - A SCAN THAT DID NOT FINISH IS NOT A CLEAN ONE — enforced here, because the tool does not
#     enforce it. Its own `--timeout` stops a scan part-way, prints "no leaks found", and exits 0
#     or 1 at random: six identical runs over one history that holds a finding gave 1 0 1 0 0 1.
#     A 0 there is a silent pass. So the limit is this hook's: a watchdog kills the scanner at
#     ATTEST_LEAK_SCAN_SECONDS (default 30), a killed scanner exits 143, and anything but 0 or 42
#     is an error. `--exit-code 42` for the same reason: the tool's default for a leak is 1, which
#     is also what it exits with when it cannot open the repository.
#
# Why a limit at all, and why 30: Claude Code gives a command hook 600 seconds, and a PreToolUse
# hook that runs out of them "doesn't block the tool call" — the whole guard, record check
# included, would be discarded and the push would go through the ordinary permission flow. The
# hook has to end itself, well before. 30 seconds is a bound on how long a push waits; 121 MB of
# history scanned in 5.2 seconds on the machine this was written on. The variable raises it for a
# long first push — but only to 540: a limit at or past Claude Code's 600 would reintroduce the
# exact failure the watchdog exists to prevent, so anything outside 1..540, a non-number, or a run
# of zeros falls back to 30. A zero would kill every scan, and a quoted value would reach the JSON.
#
# Run from the repository root, so the scanner reads that repo's own configuration. Repository
# content can silence it, and that is named rather than defended against — forgetting, not
# forgery: `.betterleaksignore` (where a false positive's fingerprint belongs), a
# `.betterleaks.toml` or `.gitleaks.toml`, an inline `betterleaks:allow` comment, and the
# `env` block of a committed `.claude/settings.json` setting ATTEST_LEAK_SCAN=off for everyone.
#
# "Not yet on any remote" means every commit HEAD, a local branch or a tag has and no
# remote-tracking ref has yet — not HEAD's alone (attest ADR-0074): `git push origin
# other-branch`, `--all`, `--tags`, `push.default=matching` or a `remote.*.push` refspec each ship
# commits HEAD does not have, and a HEAD-only range traced them `clean`. The command string
# cannot say what ships, so the range does not try: a secret on a local branch this push leaves
# behind asks too. HEAD stays in for a detached HEAD, which `--branches` does not reach.
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
        # Digits first, so the numeric test below never sees `$(id)` or a quote; then the range,
        # which also catches `00` and a number too long for `test` to parse.
        case "$_limit" in ''|*[!0-9]*) _limit=30 ;; esac
        { [ "$_limit" -ge 1 ] && [ "$_limit" -le 540 ]; } 2>/dev/null || _limit=30
        # `exec`, so $! is the scanner itself and the kill reaches it; every descriptor on
        # /dev/null, so nothing the scanner or a leftover `sleep` holds can keep the hook's
        # output open; the group's stderr too, so the shell's own "Terminated" notice stays
        # out of what Claude Code reads.
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
    # The one pass in this file — and the scanner is the only thing that can take it away.
    case "$SCAN" in
      leak|error) ;;
      *) trace pass; exit 0 ;;
    esac
    CLEAN_RECORD=1
    WHY="a clean /audit-history record for HEAD ($SHA) exists"
  elif [ "$FOUND" = 1 ]; then
    # A distinct word in the log — "a record exists and does not clear this" is a different
    # event from "no record at all", and only the log can tell them apart afterwards. One
    # decision, one line: it is traced at the single exit below, never here (attest ADR-0038).
    DEC=blocked
    WHY="a /audit-history record for HEAD ($SHA) exists but not every record for this commit attests a clean scan — one of them reports a blocker, or predates the record format and carries no readable 'HEAD:' and 'findings: 0 blocker' header lines"
  else
    WHY="no /audit-history run record for HEAD ($SHA) under .attest/"
  fi
else
  # No HEAD to name, which is two different places that used to get one message (attest
  # ADR-0073, closing P0 item 7): a repository with no commits yet was told it was "not a git
  # checkout", and both were told to write a record "for this HEAD" — advice nobody could follow.
  # Each now hears what it is and the one step that can change the answer. It still ASKS in both,
  # as ADR-0050 decided: with no HEAD, "audited" and "unaudited" are the same observation.
  if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    WHY="this repository has no commits yet, so there is no HEAD a ship record could name"
    NOHEAD_NEXT="Commit first and run /audit-history for that commit, or approve to proceed without a record."
  else
    # Not "not a git checkout": git says the same when it refuses to read a repository owned by
    # another user (safe.directory), which is common on Windows, and its wording is translated,
    # so the refusal cannot be told apart reliably from here. Say both.
    WHY="git found no repository here, or refused to read one, so there is no HEAD a ship record could name"
    NOHEAD_NEXT="If this is a repository git refuses to read (safe.directory), make it readable and run /audit-history; otherwise no ship record can clear a command run here, so approve only if this is what you mean to send."
  fi
fi

# What the scanner adds, and what the prompt then tells the person to do. The default advice —
# go and write a clean record — is wrong once the record is already clean, so each outcome that
# can reach here with a clean record carries its own.
#
# The decision word keeps saying what the RECORD did, and only becomes `leak` or `scanerr` when
# the scanner is the sole reason this push stopped — a clean record it took the pass away from.
# On a push that asks anyway, the word stays `ask` or `blocked` and the scan column says `leak`
# or `error` beside it. The first draft let `leak` win outright, which erased the difference
# ADR-0038 made `blocked` a word to keep; with the column, neither fact hides the other.
NEXT="Run /audit-history first (full before a public release) and let it write a clean record for this HEAD, or approve to proceed on the evidence as it stands."
if [ -n "$NOHEAD_NEXT" ]; then NEXT="$NOHEAD_NEXT"; fi
case "$SCAN" in
  leak)
    [ "$CLEAN_RECORD" = 1 ] && DEC=leak
    WHY="$WHY, but betterleaks found at least one secret in the commits not yet on any remote. The values are not repeated here; list them redacted, with the fingerprint each one needs to be ignored, using: betterleaks git . --log-opts='$LEAK_RANGE' --redact=100 --report-format json --report-path -"
    NEXT="Do not approve until that scan is clean: a secret pushed in one commit stays readable in history after a later commit deletes it. Remove it from the unpushed commits, or add the Fingerprint of a false positive to .betterleaksignore."
    ;;
  error)
    WHY="$WHY, but betterleaks is installed and did not finish (it failed, or passed its $_limit-second limit), so the commits not yet on any remote were not scanned"
    if [ "$CLEAN_RECORD" = 1 ]; then
      DEC=scanerr
      NEXT="Run the scan by hand to see why: betterleaks git . --log-opts='$LEAK_RANGE' --redact=100. Approving proceeds on the record alone; a longer ATTEST_LEAK_SCAN_SECONDS, up to 540, gives a long history time to finish, and ATTEST_LEAK_SCAN=off stops the guard calling the scanner."
    fi
    ;;
esac

trace "${DEC:-ask}"

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' \
  "attest ship gate: this command $ACT ($SAFE) and $WHY. $NEXT"

exit 0
