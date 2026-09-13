#!/bin/sh
# Stage 0 of /gate: decide which passes this diff needs, before any subagent exists.
#
# WHY THIS IS A SCRIPT AND NOT A PROMPT. The gate launched four subagents on every diff, and
# `/compliance audit`'s "cheap trigger check" was cheap only in what it returned: the context was
# already spent by the time it said "out of scope". Four contexts for a one-file change is the
# cost that stops a gate from being run at all. Deciding from the diff needs no judgment, so it
# needs no model (attest ADR-0067).
#
# CONTRACT. Input: one argument, the material directory `$M` that /gate step 1 wrote, and the
# repository as the working directory. Read: `$M/diff.patch`, `$M/status.txt`, the repo's
# `BUSINESS.md` and `COMPLIANCE.md`, and any untracked file `status.txt` names — untracked
# content is not in the diff and is exactly where a new file's first regulated line lives.
# Written: `$M/triggers.txt`, one line per pass, and `$M/trigger-<pass>.txt` holding the
# `file:line` hits a running pass starts from.
#
# FAIL-OPEN, AND NOTE WHICH WAY THAT POINTS. Every hook in this kit fails open by letting the
# action through. Here the safe direction is the opposite: a stage that cannot decide must not
# silently skip an audit. So on any failure this script writes nothing and exits 0, and the
# skill's rule is that a missing or unreadable `triggers.txt` means RUN EVERY PASS. Silence
# costs a few contexts; a wrong skip costs a finding nobody sees.
#
# NOT A SECURITY BOUNDARY, AND NOT A JUDGE. These are keyword sets. They find what a word can
# find and nothing else — a non-goal violated without a word on any list is invisible here, and
# the `.gitattributes` blocker of 2026-09-07 was exactly that shape. That is why `/gate full`
# exists and runs every pass unconditionally before a push.

set -u

M="${1:-}"
[ -n "$M" ] || exit 0
[ -d "$M" ] || exit 0
[ -r "$M/diff.patch" ] || exit 0

OUT="$M/triggers.txt"
WORK="$M/.stage0"
rm -rf "$WORK" 2>/dev/null
mkdir -p "$WORK" 2>/dev/null || exit 0

say() { printf '%s %s · %s\n' "$1" "$2" "$3" >> "$OUT"; }

# declared <file> — true when the document says something of its own. A bullet that still carries
# an <angle-bracketed placeholder> is the kit's own template text, not a declaration; headings,
# the router blockquote and HTML comments are furniture. This is ADR-0066's skeleton test
# written as a command instead of a judgment, so `/business` is never launched to discover that
# its ground is a skeleton.
#
# Two details, both of them bugs found by the gate that reviewed this file (attest ADR-0067):
# a placeholder is `<…` with a SPACE inside `…>` — bare `<` also matches `latency < 100ms` and a
# `<https://url>`, and calling those template text would silence the audit on a real document;
# and the test is applied to a WRAPPED BULLET, not a physical line, because the shipped
# `COMPLIANCE.md` carries a bullet whose placeholder sits on its second line — testing lines
# alone read the first half as a declaration and the whole posture check went dead.
#
# TWO DOCUMENTS, TWO QUESTIONS, AND THEY ARE NOT THE SAME ONE. `/business` asks *is there any
# declaration to audit against* — one real non-goal is enough, so `declared` below answers it.
# The posture check asks the opposite: ADR-0030 says an **unfilled** `COMPLIANCE.md` is worse
# than an absent one, because it reads as "posture declared" to every later audit. The shipped
# template carries instructional prose with no placeholder in it — *"- Per obligation: met /
# open / N-A + one line of evidence."* — so "has a real line" is satisfied by the template
# itself, and the posture check went dead. It uses `has_placeholder` instead: while any
# `<…>` placeholder survives, nothing is declared.
has_placeholder() {
  [ -r "$1" ] || return 1
  awk '
    /<!--/ { c = 1 }
    c      { if (/-->/) { c = 0 } next }
    /<[^>]* [^>]*>/ { found = 1; exit }
    END { exit(found ? 0 : 1) }
  ' "$1" 2>/dev/null
}

declared() {
  [ -r "$1" ] || return 1
  awk '
    function flush() { if (buf != "" && buf !~ /<[^>]* [^>]*>/) { found = 1 } buf = "" }
    /<!--/                        { c = 1 }
    c                             { if (/-->/) { c = 0 } next }
    /^[[:space:]]*$/              { flush(); next }
    /^#/                          { flush(); next }
    /^>/                          { flush(); next }
    /^[[:space:]]/                { buf = buf " " $0; next }
                                  { flush(); buf = $0 }
    END { flush(); exit(found ? 0 : 1) }
  ' "$1" 2>/dev/null
}

# --- the material: every added line, as path:line:content, and every path touched -----------
# ONE walk of the unified diff writes both lists. It used to be two parsers — this awk for the
# lines and a `sed` for the paths — and they disagreed the moment a diff did not look the way
# the sed expected: with `diff.noprefix=true` in a user's git config the headers read
# `+++ app.py`, the sed matched nothing, the path list came out empty and the gate concluded
# "records only" and skipped every pass while writing an attestation that said so. One parser,
# and four header shapes it must survive (attest ADR-0067).
#
# `+++ b/path` names the file, `@@ … +c,d @@` resets the counter, and a context line advances
# it — so the number reported is the line as it will exist in the new file, which is what a
# finding has to cite. Paths are taken by offset, not by field, so a path containing a space
# survives; the prefix is whatever git chose (`a/ b/` by default, `i/ w/ c/ o/` under
# `diff.mnemonicPrefix`, none under `diff.noprefix`).
awk -v pf="$WORK/paths.txt" '
  function norm(s) { sub(/^[abciwo]\//, "", s); return s }
  function note(s) { if (s != "" && s != "/dev/null") { print s > pf } }
  # The `diff --git` header is the one line every shape carries — a mode-only change, a binary
  # file and a pure rename have no `+++` at all, and without this they would read as no paths.
  /^diff --git /   { hdr = 1; i = index($0, " b/"); if (i > 0) { note(substr($0, i + 3)) } next }
  hdr && /^rename from / { note(substr($0, 13)); next }
  hdr && /^rename to /   { note(substr($0, 11)); next }
  hdr && /^\+\+\+ /      { p = norm(substr($0, 5)); note(p); next }
  hdr && /^--- /         { note(norm(substr($0, 5))); next }
  /^@@ /           { hdr = 0; n = $3; sub(/^\+/, "", n); sub(/,.*/, "", n); ln = n + 0; next }
  /^\\ No newline/ { next }
  /^\+/            { if (p != "" && p != "/dev/null") printf "%s:%d:%s\n", p, ln, substr($0, 2); ln++; next }
  /^-/             { next }
                   { ln++ }
' "$M/diff.patch" > "$WORK/added.txt" 2>/dev/null || exit 0

# Does this grep understand -I (skip binary)? Asked once, because a grep that does not would
# fail the test and silently drop every untracked file — a skip in the unsafe direction.
if printf 'x\n' | grep -qI . 2>/dev/null; then HAVE_I=1; else HAVE_I=0; fi

# Untracked files are new in full: every line is an added line. Capped, because a data file that
# slipped in is `/audit-history`'s finding, not a reason to read a megabyte here — and the cap is
# stated in the record, never silent, since a truncated file is a place a finding could hide.
#
# `git status --porcelain` without `-uall` collapses a whole new directory into one `?? src/`
# entry, so the first commit of a feature — the case this stage exists for — would be read as a
# single unreadable path. The skill asks for `-uall`; this walks a directory anyway, because a
# caller that forgets must not turn into a silent skip (attest ADR-0067).
if [ -r "$M/status.txt" ]; then
  sed -n 's/^?? //p' "$M/status.txt" 2>/dev/null | while IFS= read -r u; do
    case "$u" in .attest/*) continue ;; esac
    if [ -d "$u" ]; then
      find "$u" -type f 2>/dev/null | head -200
    else
      printf '%s\n' "$u"
    fi
  done | while IFS= read -r f; do
    [ -f "$f" ] && [ -r "$f" ] || continue
    case "$f" in .attest/*) continue ;; esac
    printf 'UNTRACKED\t%s\n' "$f" >> "$WORK/untracked.txt"
    if [ "$HAVE_I" = 1 ] && ! LC_ALL=C grep -qI . "$f" 2>/dev/null; then continue; fi
    awk -v p="$f" 'NR <= 2000 { printf "%s:%d:%s\n", p, NR, $0 }' "$f" 2>/dev/null
  done >> "$WORK/added.txt" 2>/dev/null
fi

# --- could this stage decide at all? -------------------------------------------------------
# A diff that parsed to no path at all is not "nothing changed" — it is "this stage did not
# understand the material", and the two must never produce the same output. Write nothing, exit
# 0, and let the skill's rule apply: no `triggers.txt` means run every pass (attest ADR-0067).
touch "$WORK/paths.txt" 2>/dev/null
if [ -s "$WORK/untracked.txt" ]; then
  sed 's/^UNTRACKED\t//' "$WORK/untracked.txt" >> "$WORK/paths.txt"
fi
if [ ! -s "$WORK/paths.txt" ]; then
  rm -f "$OUT"
  rm -rf "$WORK" 2>/dev/null
  exit 0
fi
sort -u "$WORK/paths.txt" > "$WORK/paths-sorted.txt" 2>/dev/null && mv "$WORK/paths-sorted.txt" "$WORK/paths.txt"

# Everything outside the record directory. `.attest/` is an OUTPUT of the gate: a diff that only
# commits a record has nothing to audit, and scanning it finds the taxonomy words the records
# themselves print — measured, that doubles the compliance hits, every one of them the scan's
# own vocabulary.
grep -v '^\.attest/' "$WORK/paths.txt" > "$WORK/paths-real.txt"
grep -v '^\.attest/' "$WORK/added.txt" > "$WORK/added-real.txt"

: > "$OUT"

# --- records-only short-circuit -----------------------------------------------------------
# Reached only when paths WERE parsed and every one of them is a record. That is the one case
# where skipping the reviewer is right: the diff is the gate's own output.
if [ ! -s "$WORK/paths-real.txt" ]; then
  say reviewer   skip "records only"
  say decision   skip "records only"
  say compliance skip "records only"
  say business   skip "records only"
  rm -rf "$WORK" 2>/dev/null
  exit 0
fi

# --- reviewer -------------------------------------------------------------------------------
say reviewer run "$(wc -l < "$WORK/paths-real.txt" | tr -d ' ') path(s) outside .attest/"

# --- /decision audit ------------------------------------------------------------------------
# A dependency manifest, a lockfile, a container or infra file, a workflow, a hook, or the
# settings that wire them: these are where a choice lands in a file rather than in prose. Plus
# an added import line — the cheapest visible shape of "something new was taken on". §2.2 of the
# proposal asked for "imports a module no file in the tree imported before"; that needs a
# tree-wide grep per import, so this takes the wider, cheaper rule and accepts the over-trigger:
# a pass that runs when it need not costs one context, and the other direction costs a finding.
DEC_PATH='(^|/)(package\.json|package-lock\.json|yarn\.lock|pnpm-lock\.yaml|pyproject\.toml|requirements[^/]*\.txt|uv\.lock|poetry\.lock|Pipfile(\.lock)?|Cargo\.(toml|lock)|go\.(mod|sum)|[^/]*\.csproj|Gemfile(\.lock)?|pom\.xml|build\.gradle[^/]*|composer\.json|Dockerfile[^/]*|docker-compose[^/]*\.ya?ml|[^/]*\.tf|[^/]*\.bicep)$|^\.github/workflows/|^\.claude/hooks/|^\.claude/settings\.json$'
DEC_LINE='^[^:]*:[0-9][0-9]*:[[:space:]]*(import |from [^ ]* import |require\(|use [A-Za-z]|using [A-Za-z]|#include )'

: > "$M/trigger-decision.txt"
grep -E "$DEC_PATH" "$WORK/paths-real.txt" 2>/dev/null | sed 's/$/:1:(dependency, infra or wiring file)/' >> "$M/trigger-decision.txt"
grep -E "$DEC_LINE" "$WORK/added-real.txt" 2>/dev/null >> "$M/trigger-decision.txt"
if [ -s "$M/trigger-decision.txt" ]; then
  say decision run "$(wc -l < "$M/trigger-decision.txt" | tr -d ' ') hit(s) — see trigger-decision.txt"
else
  rm -f "$M/trigger-decision.txt"
  say decision skip "no trigger"
fi

# --- /compliance audit (only where the skill is installed) ---------------------------------
# The ladder's floor — special-category data, national identifiers, an Art 5 practice — is
# **always a blocker**, and in light mode this pattern is the only thing that can bring a pass to
# look for one. So it has to reach every class `compliance/SKILL.md` names, and reach it in the
# shapes code is written in: a multi-word phrase typed with a literal space only ever matches
# prose, which is how `date of birth` missed `date_of_birth` and `dob`, and `social scoring`
# missed `trust_score`. The audit that reviewed this file found the gap (attest ADR-0067).
COMP_PAT='first_?name|last_?name|surname|e-?mail|phone|ip_?addr|device_?id|user_?agent|account_?id|user_?id|customer_?id|session_?id|cookie|street|postal|zip_?code|latitude|longitude|geoloc'
COMP_PAT="$COMP_PAT"'|date[ _-]?of[ _-]?birth|national[ _-]?id|passport|ssn|social[ _-]?security|tax[ _-]?id|birth[ _-]?number|personal[ _-]?number|id[ _-]?card'
COMP_PAT="$COMP_PAT"'|health|diagnos|biometric|fingerprint|genetic|ethnic|racial|religio|political[ _-]?opinion|trade[ _-]?union|sexual|gender'
COMP_PAT="$COMP_PAT"'|inference|predict|ranking|classif|scoring|automated[ _-]?decision|profiling|social[ _-]?scoring|emotion[ _-]?recognition|facial[ _-]?recognition|subliminal|scrap(e|ing)'
COMP_PAT="$COMP_PAT"'|openai|anthropic|embedding|analytics|telemetry|webhook|third[ _-]party|data[ _-]?(export|transfer|dump)|cross[ _-]border|sub[ _-]?processor'
# Two words are deliberately NOT here, and the reason is the same one: `race` and `dob` as bare
# words need a word boundary, `\b` is a GNU extension this script cannot rely on, and without
# one they match `traced` and `dobrý`. `racial` and `date_of_birth` carry those classes instead.
# Plain `export` and `transfer` are out too — in JavaScript every other line is an `export`, and
# a trigger that fires on everything is the four-subagent cost this stage exists to remove.

if [ ! -d ".claude/skills/compliance" ]; then
  say compliance not-installed "the project opted out of regulated scope"
else
  : > "$M/trigger-compliance.txt"
  grep -Ei "$COMP_PAT" "$WORK/added-real.txt" 2>/dev/null >> "$M/trigger-compliance.txt"
  if grep -q '^COMPLIANCE\.md$' "$WORK/paths-real.txt" 2>/dev/null; then
    printf 'COMPLIANCE.md:1:(the posture document itself changed)\n' >> "$M/trigger-compliance.txt"
  fi
  if [ -s "$M/trigger-compliance.txt" ]; then
    say compliance run "$(wc -l < "$M/trigger-compliance.txt" | tr -d ' ') hit(s) — see trigger-compliance.txt"
  else
    rm -f "$M/trigger-compliance.txt"
    say compliance skip "no trigger"
  fi
  # The posture check is a mechanical fact, so it is stated here and costs no subagent: an
  # absent or still-template COMPLIANCE.md declares nothing, and no later audit may read that
  # silence as "declared" (attest ADR-0030).
  if [ ! -r "COMPLIANCE.md" ] || has_placeholder "COMPLIANCE.md"; then
    printf 'posture none · COMPLIANCE.md absent or still the template — nothing declared\n' >> "$OUT"
  fi
fi

# --- /business audit ------------------------------------------------------------------------
# Runs only against a document that says something. The words it turns on are the project's to
# name, in one HTML comment under Non-goals: `<!-- gate-watch: socket, telemetry, upload -->`.
# Absent, a generic set applies — the shapes that cross a boundary in most projects.
BUS_GENERIC='socket|https?://|fetch\(|curl |wget |requests\.|urllib|axios|smtp|telemetry|analytics|tracking|upload'

if ! declared "BUSINESS.md"; then
  say business skip "nothing declared — run /business"
else
  : > "$M/trigger-business.txt"
  watch=$(sed -n 's/.*<!--[[:space:]]*gate-watch:[[:space:]]*\(.*\)-->.*/\1/p' BUSINESS.md 2>/dev/null | head -1)
  pat=""
  if [ -n "${watch:-}" ]; then
    pat=$(printf '%s' "$watch" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^$' | paste -sd '|' -)
  fi
  # A typo in the comment the kit tells people to write — an unbalanced bracket is enough — would
  # make `grep -E` fail and, with errors discarded, silently turn off the pass the project asked
  # for. Compile it once against nothing: if it will not compile, fall back and say which set is
  # in force (attest ADR-0067).
  # Exit 1 is "no match", which empty input always gives; only exit 2 or above is "I cannot
  # compile that". Testing for non-zero would fall back on every valid list there is.
  if [ -n "$pat" ]; then
    printf '' | grep -Eq "$pat" 2>/dev/null
    if [ $? -ge 2 ]; then
      printf 'note · the gate-watch list in BUSINESS.md is not a valid pattern; the generic set is in force\n' >> "$OUT"
      pat=""
    fi
  fi
  [ -n "$pat" ] || pat="$BUS_GENERIC"
  grep -Ei "$pat" "$WORK/added-real.txt" 2>/dev/null >> "$M/trigger-business.txt"
  if grep -q '^BUSINESS\.md$' "$WORK/paths-real.txt" 2>/dev/null; then
    printf 'BUSINESS.md:1:(the declaration itself changed)\n' >> "$M/trigger-business.txt"
  fi
  # A new top-level directory is scope movement that no keyword describes.
  awk -F/ 'NF > 1 { print $1 }' "$WORK/paths-real.txt" 2>/dev/null | sort -u | while IFS= read -r d; do
    case "$d" in .*) continue ;; esac
    if [ "$(git log --oneline -1 -- "$d" 2>/dev/null | wc -l | tr -d ' ')" = "0" ]; then
      printf '%s:1:(new top-level directory)\n' "$d"
    fi
  done >> "$M/trigger-business.txt" 2>/dev/null
  if [ -s "$M/trigger-business.txt" ]; then
    say business run "$(wc -l < "$M/trigger-business.txt" | tr -d ' ') hit(s) — see trigger-business.txt"
  else
    rm -f "$M/trigger-business.txt"
    say business skip "no trigger"
  fi
fi

rm -rf "$WORK" 2>/dev/null
exit 0
