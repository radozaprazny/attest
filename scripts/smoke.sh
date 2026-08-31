#!/usr/bin/env bash
# smoke.sh — attest's own smoke test. Not part of the kit: install.sh never copies
# scripts/, and template-cleanup deletes it in generated repos.
#
# Covers the classes of defect the real audits actually found: hooks crashing on odd
# payloads, a non-idempotent installer, .gitignore corruption, junk files landing, and
# hooks installing silently inert. Run it from anywhere: ./scripts/smoke.sh

set -euo pipefail

# The hooks honour two environment overrides (ADR-0028). A maintainer who sets either for this
# checkout — which docs/attest-progress.md tells them to do, so the SessionStart hook is not
# silent here — would otherwise have that ambient value reach every fixture below, and the
# assertions pinning the DEFAULT document paths would fail against files no test wrote. The
# suite controls its own environment; the tests that want an override set it per invocation.
unset ATTEST_BUSINESS ATTEST_THREAD_CARRIER

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0

ok()   { PASS=$((PASS + 1)); echo "  ok: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "FAIL: $1" >&2; }

check() { # check <description> <command...>
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$desc"; else fail "$desc"; fi
}

says() { # says <description> <text> <pattern> — assert the output contains a pattern
  if printf '%s' "$2" | grep -q "$3"; then ok "$1"; else fail "$1"; fi
}

says_not() { # says_not <description> <text> <pattern> — assert it does not
  if printf '%s' "$2" | grep -q "$3"; then fail "$1"; else ok "$1"; fi
}

# run_install <args...> — capture the run's output. Never aborts the suite: a non-zero exit
# just leaves the caller's assertions to fail and be counted, so the verdict still prints.
run_install() { "$KIT/install.sh" "$@" 2>&1 || true; }

DECL="$KIT/.claude/hooks/session_declaration.sh"
GUARD="$KIT/.claude/hooks/ship_guard.sh"

# --- 0. the kit carries no interpreter dependency --------------------------------------
echo "kit shape:"
py_count=$(find "$KIT/.claude" -name '*.py' | wc -l)
if [ "$py_count" -eq 0 ]; then ok "no .py anywhere under .claude/"; else fail "no .py anywhere under .claude/ ($py_count found)"; fi
check "no formatter config ships"  test ! -e "$KIT/ruff.toml"
check "no inert .example files ship" test ! -e "$KIT/.mcp.json.example"

# --- 1. hooks: fail-open on every payload ----------------------------------------------
echo "hooks — fail-open:"
for hook in "$DECL" "$GUARD"; do
  name="$(basename "$hook")"
  check "$name survives an empty payload"    sh -c "echo '{}' | sh '$hook'"
  check "$name survives garbage stdin"       sh -c "echo 'not json' | sh '$hook'"
  check "$name survives no stdin at all"     sh -c "sh '$hook' </dev/null"
  check "$name survives a missing project"   sh -c "echo '{}' | CLAUDE_PROJECT_DIR='$WORK/nowhere' sh '$hook'"
done

# --- 2. the declaration hook: silent until something is declared -----------------------
echo "hooks — SessionStart declaration:"
D0="$WORK/decl-empty"; mkdir -p "$D0"
out=$(CLAUDE_PROJECT_DIR="$D0" sh "$DECL")
if [ -z "$out" ]; then ok "silent in a project with no documents"; else fail "silent in a project with no documents"; fi
# The shipped skeletons are <placeholder> text: a fresh install must add no session noise.
D1="$WORK/decl-template"; mkdir -p "$D1"; cp "$KIT/BUSINESS.md" "$KIT/PROGRESS.md" "$D1/"
out=$(CLAUDE_PROJECT_DIR="$D1" sh "$DECL")
if [ -z "$out" ]; then ok "silent while the documents are still the shipped templates"; else fail "silent while the documents are still the shipped templates"; fi
# ...and speaks as soon as a non-goal is real
D2="$WORK/decl-filled"; mkdir -p "$D2"
printf '# B\n\n## Non-goals\n\n- no network access at runtime\n\n## What success looks like\n\n- <ph>\n' > "$D2/BUSINESS.md"
printf '# P\n\n## Current state\n\nEngine wired.\n\n## Next\n\n- tune it\n' > "$D2/PROGRESS.md"
out=$(CLAUDE_PROJECT_DIR="$D2" sh "$DECL")
says     "carries the declared non-goal into the session" "$out" 'no network access at runtime'
says     "carries the live state and the next step"       "$out" 'Engine wired'
says     "…and the next step"                             "$out" 'tune it'
says_not "drops the placeholder sections"                 "$out" '<ph>'
# The cap must trim EACH section, not the block: a single trailing `head` silently dropped
# whichever section came last, plus the closing tag. Fixture deliberately overruns it.
D3="$WORK/decl-huge"; mkdir -p "$D3"
{ echo '# B'; echo; echo '## Non-goals'; echo; i=1
  while [ "$i" -le 60 ]; do echo "- non-goal number $i"; i=$((i + 1)); done; } > "$D3/BUSINESS.md"
printf '# P\n\n## Current state\n\nstate marker\n\n## Next\n\n- next marker\n' > "$D3/PROGRESS.md"
huge=$(CLAUDE_PROJECT_DIR="$D3" sh "$DECL")
says "an overrunning section is trimmed"              "$huge" 'non-goal number 24'
says "…and says how much it dropped"                  "$huge" 'more line(s)'
says_not "…and really does drop it"                   "$huge" 'non-goal number 25'
says "the later section survives the trim"            "$huge" 'state marker'
says "…including the one after that"                  "$huge" 'next marker'
says "the block is always closed"                     "$huge" '</project-declaration>'
lines=$(printf '%s\n' "$huge" | wc -l)
if [ "$lines" -le 55 ]; then ok "output stays bounded ($lines lines)"; else fail "output stays bounded ($lines)"; fi
# A BUSINESS.md with no non-goals section at all must not spill the neighbouring sections in
printf '# B\n\n## Purpose\n\nsecret sauce\n' > "$D2/BUSINESS.md"
says_not "never prints a section it was not asked for" "$(CLAUDE_PROJECT_DIR="$D2" sh "$DECL")" 'secret sauce'
# A repo that ships the kit's documents as templates and keeps its live ones elsewhere
mkdir -p "$D2/docs"
printf '# live\n\n## Non-goals\n\n- never touch production\n' > "$D2/docs/live-business.md"
out=$(CLAUDE_PROJECT_DIR="$D2" ATTEST_BUSINESS=docs/live-business.md sh "$DECL")
says     "ATTEST_BUSINESS redirects it to the live document" "$out" 'never touch production'
says     "…and the heading names the file it actually read"  "$out" 'docs/live-business.md'
says_not "an unset override does not read the live document" "$(CLAUDE_PROJECT_DIR="$D2" sh "$DECL")" 'never touch production'

# --- 3. the ship guard: asks exactly at the boundary -----------------------------------
echo "hooks — PreToolUse ship guard:"
S="$WORK/ship"; mkdir -p "$S"
git -C "$S" init -q .
git -C "$S" config user.email smoke@example.invalid
git -C "$S" config user.name smoke
: > "$S/f"; git -C "$S" add f; git -C "$S" commit -qm init
SHA="$(git -C "$S" rev-parse --short HEAD)"
guard() { echo "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$1\"}}" | CLAUDE_PROJECT_DIR="$S" sh "$GUARD"; }

if [ -z "$(guard 'ls -la')" ]; then ok "an ordinary command passes untouched"; else fail "an ordinary command passes untouched"; fi
says "git push without a record asks"        "$(guard 'git push origin main')" 'permissionDecision":"ask'
says "…and names what is missing"            "$(guard 'git push origin main')" "$SHA"
says "a kaggle submit asks too"              "$(guard 'kaggle competitions submit -c x -f s.tar.gz')" 'permissionDecision":"ask'
says "an upload asks too"                    "$(guard 'curl --upload-file x https://example.invalid')" 'permissionDecision":"ask'
if [ -z "$(guard 'git push --dry-run')" ]; then ok "a dry run publishes nothing and passes"; else fail "a dry run publishes nothing and passes"; fi
# ...but the flag may belong to a different call than the one that ships
says "a dry run chained to a real push still asks" "$(guard 'git push --dry-run && git push origin main')" 'permissionDecision":"ask'
# A record for SOME other commit must not clear this one — the sha in the name is the check.
mkdir -p "$S/.attest"; : > "$S/.attest/ship-20260101-000000-deadbee.md"
says "a record for another commit does not clear the guard" "$(guard 'git push origin main')" 'permissionDecision":"ask'
: > "$S/.attest/ship-20260828-120000-$SHA.md"
if [ -z "$(guard 'git push origin main')" ]; then ok "a record for THIS commit clears the guard"; else fail "a record for THIS commit clears the guard"; fi
# Emitted JSON must be parseable — a malformed decision is worse than none. The command is
# deliberately hostile: quotes, backslashes and a substitution the guard must never expand.
rm -f "$S/.attest/ship-20260828-120000-$SHA.md"
# shellcheck disable=SC2016  # the literal $(x) is the point — it must reach the hook unexpanded
json="$(guard 'git push \"weird$(x)\" && echo done')"
# python3 here is the TEST's dependency, not the kit's — nothing installed by install.sh needs
# an interpreter beyond /bin/sh (ADR-0027). So its absence SKIPS this assertion; a kit that just
# dropped that dependency must not fail its own suite for lacking it.
if ! command -v python3 >/dev/null 2>&1; then
  ok "the ask payload is valid JSON (skipped: no python3 to parse it with)"
elif printf '%s' "$json" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; then
  ok "the ask payload is valid JSON even for a hostile command"
else
  fail "the ask payload is valid JSON even for a hostile command"
fi

# --- 3b. the guard leaves a trace, so "did it fire" is a fact (ADR-0034) ---------------
echo "hooks — ship guard trace:"
G="$WORK/trace"; mkdir -p "$G"
git -C "$G" init -q .
git -C "$G" config user.email smoke@example.invalid
git -C "$G" config user.name smoke
: > "$G/f"; git -C "$G" add f; git -C "$G" commit -qm init
GSHA="$(git -C "$G" rev-parse --short HEAD)"
tguard() { echo "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$1\"}}" | CLAUDE_PROJECT_DIR="$G" sh "$GUARD"; }
LOG="$G/.attest/tmp/ship-guard.log"

tguard 'ls -la' >/dev/null
check "an unmatched command leaves no trace at all"  test ! -e "$LOG"
tguard 'git push origin main' >/dev/null
check "an ask is traced"                             test -f "$LOG"
says "…with its decision and the sha it judged"      "$(cat "$LOG")" "ask $GSHA"
check "the trace sits in the ignored scratch, not beside the records" test ! -e "$G/.attest/ship-guard.log"
# The pass is the case that looked like a dead hook, so it must be traced too.
: > "$G/.attest/ship-20260831-000000-$GSHA.md"
tguard 'git push origin main' >/dev/null
says "a pass is traced too"                          "$(tail -1 "$LOG")" "pass $GSHA"
if [ "$(grep -c . "$LOG")" -eq 2 ]; then ok "one line per matched command, no more"; else fail "one line per matched command, no more"; fi
# Fail-open: a scratch it cannot write costs the line, never the decision.
rm -f "$G/.attest/ship-20260831-000000-$GSHA.md"
chmod 500 "$G/.attest/tmp"
says "an unwritable scratch still yields a decision" "$(tguard 'git push origin main')" 'permissionDecision":"ask'
chmod 700 "$G/.attest/tmp"

# --- 4. fresh install, then a re-run that must change nothing --------------------------
echo "install.sh — idempotency:"
T1="$WORK/fresh"; mkdir -p "$T1"
"$KIT/install.sh" "$T1" >/dev/null
check "fresh install lands the shared ladder" test -f "$T1/.claude/skills/_shared/audit-ladder.md"
check "fresh install lands /gate"             test -f "$T1/.claude/skills/gate/SKILL.md"
check "fresh install lands the ship guard"   test -f "$T1/.claude/hooks/ship_guard.sh"
check "fresh install lands the declaration hook" test -f "$T1/.claude/hooks/session_declaration.sh"
check "fresh install lands the settings that wire them" test -f "$T1/.claude/settings.json"
check "nothing at all lands under .github/" test ! -e "$T1/.github"
check "attest's own README does not land"   test ! -e "$T1/README.md"
check "attest's own LICENSE does not land"  test ! -e "$T1/LICENSE"
# The skill set is enumerated from the kit, not hardcoded: a skill added upstream must install.
mkdir -p "$WORK/kit-extra"; cp -r "$KIT/.claude" "$KIT"/*.md "$KIT/install.sh" "$WORK/kit-extra/"
mkdir -p "$WORK/kit-extra/.claude/skills/newthing"; echo '# new' > "$WORK/kit-extra/.claude/skills/newthing/SKILL.md"
T1b="$WORK/fresh-extra"; mkdir -p "$T1b"
extra_out=$("$WORK/kit-extra/install.sh" "$T1b" 2>&1 || true)
check "a skill added to the kit installs without an edit to install.sh" test -f "$T1b/.claude/skills/newthing/SKILL.md"
says  "…and shows up in the command list" "$extra_out" '/newthing'
rerun_out=$(run_install "$T1")
says     "a re-run says it changed nothing, in one line" "$rerun_out" 'changed nothing'
says_not "…without listing every group again"            "$rerun_out" 'Documents'
check "second run minted no attest-GUIDE.md" test ! -e "$T1/attest-GUIDE.md"
says_not "re-run does not false-warn about unwired hooks" "$rerun_out" 'NOT wired'
# A locally modified kit-owned file must be called out as drift, not skipped silently
echo '# local modification' >> "$T1/.claude/skills/gate/SKILL.md"
drift_out=$(run_install "$T1")
says "a drifted kit file is called out as DIFFERS" "$drift_out" 'gate/SKILL.md — yours kept, but it DIFFERS'
says "…under a heading that says nothing was overwritten" "$drift_out" 'NEEDS YOU'

# --- 4b. an abort mid-run must still account for what landed ---------------------------
echo "install.sh — partial install:"
TP="$WORK/partial"; mkdir -p "$TP"; touch "$TP/.claude"   # a file where a directory must go
partial_out=$(run_install "$TP")
says "an aborted install says it is PARTIAL"        "$partial_out" 'ABORTED'
says "an aborted install lists what already landed" "$partial_out" '+ CLAUDE.md'
if "$KIT/install.sh" "$TP" >/dev/null 2>&1; then
  fail "an aborted install exits non-zero"
else
  ok "an aborted install exits non-zero"
fi

# --- 4c. the self-install guard covers ancestry, not just equality ---------------------
# Ancestry is exercised against a COPY of the kit inside $WORK, never the real checkout's
# parent: if a guard ever regresses, a passing-by-accident test must not install the kit
# into someone's actual projects directory.
echo "install.sh — self-install guard:"
ANC="$WORK/anc"; mkdir -p "$ANC"
cp -r "$KIT/.claude" "$ANC/kit-copy" 2>/dev/null || true
mkdir -p "$ANC/kit-copy"; cp "$KIT/install.sh" "$KIT"/*.md "$ANC/kit-copy/"
for bad in "$ANC/kit-copy" "$ANC/kit-copy/docs" "$ANC"; do
  mkdir -p "$bad"
  label="the kit itself"
  [ "$bad" = "$ANC/kit-copy/docs" ] && label="a directory inside the kit"
  [ "$bad" = "$ANC" ] && label="a directory containing the kit"
  if "$ANC/kit-copy/install.sh" "$bad" >/dev/null 2>&1; then
    fail "refuses to install into $label"
  else
    ok "refuses to install into $label"
  fi
done
# TARGET=/ is asserted by MESSAGE, not by exit code: an unguarded run aborts on EACCES and
# would pass an exit-code test for entirely the wrong reason.
says "refuses TARGET=/ as an ancestor of the kit" "$(run_install /)" \
  'refusing to install the kit into a directory that contains it'
says "rejects an unknown option rather than treating it as a path" "$(run_install --nope "$WORK/fresh")" \
  'unknown option'

# --- 5. a .gitignore without a trailing newline survives intact ------------------------
echo "install.sh — .gitignore:"
T2="$WORK/nonl"; mkdir -p "$T2"
printf 'node_modules' > "$T2/.gitignore"
"$KIT/install.sh" "$T2" >/dev/null
check "user's rule kept as its own line"  grep -qx 'node_modules' "$T2/.gitignore"
check "kit's ignore line landed whole"    grep -qx '.claude/settings.local.json' "$T2/.gitignore"

# --- 6. junk in the kit tree never installs --------------------------------------------
echo "install.sh — junk filter:"
K2="$WORK/kitcopy"; mkdir -p "$K2"
cp -r "$KIT/.claude" "$K2/"; cp "$KIT"/*.md "$K2/" 2>/dev/null || true
cp "$KIT/install.sh" "$K2/"
mkdir -p "$K2/.claude/hooks/__pycache__"
touch "$K2/.claude/hooks/__pycache__/x.pyc" "$K2/.claude/hooks/.DS_Store" \
      "$K2/.claude/skills/x.swp" "$K2/.claude/skills/y~"
T3="$WORK/junk"; mkdir -p "$T3"
"$K2/install.sh" "$T3" >/dev/null
found=$(find "$T3" \( -name '*.pyc' -o -name '.DS_Store' -o -name '*.swp' -o -name '*~' \) | wc -l)
if [ "$found" -eq 0 ]; then ok "no junk landed"; else fail "no junk landed ($found found)"; fi
# ...and the filter did not achieve that by installing nothing at all
check "the legitimate kit files still landed" test -f "$T3/.claude/skills/gate/SKILL.md"

# --- 7. an existing settings.json: warn only when a hook is really unwired -------------
echo "install.sh — inert hooks warning:"
T4="$WORK/settings"; mkdir -p "$T4/.claude"
echo '{}' > "$T4/.claude/settings.json"
settings_out=$(run_install "$T4")
says "warning printed when settings.json registers no hooks" "$settings_out" 'NOT wired'
# ...and the same file must not also appear as "untouched": one file, one framing (ADR-0031)
says_not "an unwired settings.json is not also listed as untouched" \
  "$(printf '%s' "$settings_out" | sed -n '/YOURS, UNTOUCHED/,/NEEDS YOU/p')" 'settings.json'
# A settings.json that differs from the kit's but registers both hooks HAS them wired —
# the categorical warning would be false (an older kit stanza is the common case).
T4b="$WORK/settings-wired"; mkdir -p "$T4b/.claude"
sed '1a\
  "_note": "an older kit stanza",' "$KIT/.claude/settings.json" > "$T4b/.claude/settings.json"
wired_out=$(run_install "$T4b")
says_not "no false unwired warning when both hooks are registered" "$wired_out" 'NOT wired'
says     "a differing but wired settings.json is reported as such" "$wired_out" 'registers both'

# --- 8. compliance is opt-in, and adding it later is just a re-run ---------------------
echo "install.sh — compliance opt-in:"
T5="$WORK/optin"; mkdir -p "$T5"
optin_out=$(run_install "$T5")
check "no COMPLIANCE.md by default"       test ! -e "$T5/COMPLIANCE.md"
check "no /compliance skill by default"   test ! -e "$T5/.claude/skills/compliance/SKILL.md"
says  "the report says why it is absent"  "$optin_out" 'compliance — not installed'
for d in CLAUDE.md PROGRESS.md BUSINESS.md DECISIONS.md; do
  check "the non-optional document $d is there" test -f "$T5/$d"
done
later_out=$(run_install --compliance "$T5")
check "--compliance on a re-run adds the document" test -f "$T5/COMPLIANCE.md"
check "…and the skill"                             test -f "$T5/.claude/skills/compliance/SKILL.md"
says  "…and the command is listed"                 "$later_out" 'Commands.*/compliance'
says_not "…without dragging anything into NEEDS YOU" "$later_out" 'NEEDS YOU'
check "a re-run without the flag does not remove it" test -f "$T5/COMPLIANCE.md"
T5b="$WORK/optin-first"; mkdir -p "$T5b"
run_install --compliance "$T5b" >/dev/null
check "the flag works on a first install too" test -f "$T5b/.claude/skills/compliance/SKILL.md"

# --- 9. GUIDE.md collision: the kit's manual lands beside yours, and says when it is stale
echo "install.sh — GUIDE collision:"
T9="$WORK/ownguide"; mkdir -p "$T9"; echo '# my own guide' > "$T9/GUIDE.md"
guide_out=$(run_install "$T9")
check "your own GUIDE.md is untouched"  grep -qx '# my own guide' "$T9/GUIDE.md"
check "the kit's manual lands beside it" test -f "$T9/attest-GUIDE.md"
says  "the NEXT steps point at the file the manual is actually in" "$guide_out" 'attest-GUIDE.md PART 9'
# The commonest upgrade path: the target's GUIDE.md is the kit's own, from an older version.
T9b="$WORK/staleguide"; mkdir -p "$T9b"
{ echo '# GUIDE.md — reference guide'; echo 'old copy'; } > "$T9b/GUIDE.md"
says "an outdated kit GUIDE.md is pointed out, never overwritten" "$(run_install "$T9b")" 'GUIDE.md — an older kit version'
check "…and it is left exactly as it was" grep -qx 'old copy' "$T9b/GUIDE.md"
echo '# stale' >> "$T9/attest-GUIDE.md"
says "a stale attest-GUIDE.md gets the refresh hint" "$(run_install "$T9")" 'attest-GUIDE.md — an older kit version'

# --- 10. template-cleanup removes attest's files and nothing of yours ------------------
echo "template-cleanup:"
GEN="$WORK/generated"; mkdir -p "$GEN"
cp -r "$KIT/.claude" "$GEN/"; cp "$KIT"/*.md "$GEN/"; cp "$KIT/install.sh" "$GEN/"
cp "$KIT/LICENSE" "$GEN/"; mkdir -p "$GEN/docs" "$GEN/scripts" "$GEN/.github/workflows"
cp "$KIT"/docs/*.md "$GEN/docs/"; cp "$KIT/scripts/smoke.sh" "$KIT/scripts/template-cleanup.sh" "$GEN/scripts/"
cp "$KIT/.github/workflows/ci.yml" "$GEN/.github/workflows/"
# what the user added before the workflow ever ran
echo 'my notes' > "$GEN/docs/design.md"; echo 'echo deploy' > "$GEN/scripts/deploy.sh"
(cd "$GEN" && bash scripts/template-cleanup.sh >/dev/null)
check "attest's own docs are gone"        test ! -e "$GEN/docs/attest-devlog.md"
check "attest's installer is gone"        test ! -e "$GEN/install.sh"
check "attest's own CI is gone"           test ! -e "$GEN/.github/workflows/ci.yml"
check "YOUR docs survive"                 test -f "$GEN/docs/design.md"
check "YOUR scripts survive"              test -f "$GEN/scripts/deploy.sh"
check "the kit itself is left in place"   test -f "$GEN/.claude/skills/gate/SKILL.md"
check "the declaration hook is left in place" test -f "$GEN/.claude/hooks/session_declaration.sh"
check "the ship guard is left in place"      test -f "$GEN/.claude/hooks/ship_guard.sh"
# The template path keeps compliance on purpose: a generated repo has no install.sh to re-run,
# so removing it would be the one state a user cannot undo. /business closes the gap instead.
check "compliance is left for /business to rule on" test -f "$GEN/COMPLIANCE.md"
check "attest's LICENSE became a skeleton" grep -q '<YEAR>' "$GEN/LICENSE"
check "attest's README became a stub"      grep -q '^# <your project>' "$GEN/README.md"
# Files of your own that happen to carry attest's names must survive too.
GEN2="$WORK/generated-own-license"; cp -r "$GEN" "$GEN2"
cp "$KIT/install.sh" "$GEN2/"; cp "$KIT/README.md" "$GEN2/"
echo 'Apache-2.0 — mine' > "$GEN2/LICENSE"
mkdir -p "$GEN2/scripts" "$GEN2/.github/workflows"
echo 'name: my ci' > "$GEN2/.github/workflows/ci.yml"
echo '# my own smoke test' > "$GEN2/scripts/smoke.sh"
(cd "$GEN2" && bash scripts/template-cleanup.sh >/dev/null)
check "YOUR LICENSE is never overwritten"  grep -qx 'Apache-2.0 — mine' "$GEN2/LICENSE"
check "YOUR ci.yml survives"               grep -qx 'name: my ci' "$GEN2/.github/workflows/ci.yml"
check "YOUR smoke.sh survives"             grep -qx '# my own smoke test' "$GEN2/scripts/smoke.sh"
# And an already-cleaned repo is a no-op, not an error
GEN3="$WORK/generated-clean"; mkdir -p "$GEN3"
cp "$KIT/scripts/template-cleanup.sh" "$GEN3/"; echo '# my project' > "$GEN3/README.md"
if (cd "$GEN3" && bash template-cleanup.sh >/dev/null) && [ -f "$GEN3/README.md" ]; then
  ok "an already-cleaned repo is a no-op"
else
  fail "an already-cleaned repo is a no-op"
fi

# --- verdict ---------------------------------------------------------------------------
echo
echo "smoke: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
