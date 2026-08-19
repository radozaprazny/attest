#!/usr/bin/env bash
# smoke.sh — attest's own smoke test. Not part of the kit: install.sh never copies
# scripts/, and template-cleanup deletes it in generated repos.
#
# Covers the classes of defect the first real audits actually found: hook crashes on
# odd payloads, a non-idempotent installer, .gitignore corruption, junk files landing,
# and hooks installing silently inert. Run it from anywhere: ./scripts/smoke.sh

set -euo pipefail

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

# run_install <target...> — capture the run's output. Never aborts the suite: a non-zero exit
# just leaves the caller's assertions to fail and be counted, so the verdict still prints.
run_install() { "$KIT/install.sh" "$@" 2>&1 || true; }

# --- 1. hooks: fail-open on every payload, sane output on the real one -----------------
echo "hooks:"
for hook in format_py.py precompact_checkpoint_nudge.py stop_session_length_warn.py; do
  check "$hook survives an empty payload"   sh -c "echo '{}' | python3 '$KIT/.claude/hooks/$hook'"
  check "$hook survives garbage stdin"      sh -c "echo 'not json' | python3 '$KIT/.claude/hooks/$hook'"
done
check "format hook no-ops on a non-.py file" \
  sh -c "echo '{\"tool_input\":{\"file_path\":\"/tmp/x.txt\"}}' | python3 '$KIT/.claude/hooks/format_py.py'"

carrier_dir="$WORK/carrier"; mkdir -p "$carrier_dir"
# python3 for the backdated mtime — GNU touch -d 'relative' is not portable to BSD/macOS
python3 -c "import os,time,sys; p=sys.argv[1]; open(p,'a').close(); t=time.time()-1800; os.utime(p,(t,t))" \
  "$carrier_dir/PROGRESS.md"
out=$(echo '{"trigger":"auto"}' | CLAUDE_PROJECT_DIR="$carrier_dir" \
  python3 "$KIT/.claude/hooks/precompact_checkpoint_nudge.py")
if printf '%s' "$out" | grep -q systemMessage; then
  ok "precompact hook nudges on a stale thread-carrier"
else
  fail "precompact hook nudges on a stale thread-carrier"
fi

# --- 2. fresh install, then a re-run that must change nothing --------------------------
echo "install.sh — idempotency:"
T1="$WORK/fresh"; mkdir -p "$T1"
"$KIT/install.sh" "$T1" >/dev/null
check "fresh install lands the shared ladder" test -f "$T1/.claude/skills/_shared/audit-ladder.md"
check "fresh install lands /gate"             test -f "$T1/.claude/skills/gate/SKILL.md"
check "fresh install lands the CI example"    test -f "$T1/.github/workflows/ci.yml.example"
rerun_out=$(run_install "$T1")
says     "second run installs nothing"                 "$rerun_out" '^INSTALLED (0)'
check "second run minted no attest-GUIDE.md" test ! -e "$T1/attest-GUIDE.md"
says_not "re-run does not false-warn about unwired hooks" "$rerun_out" 'NOT wired'
says     "re-run reports untouched kit files as identical, not as drift" \
  "$rerun_out" 'gate/SKILL.md — already exists (identical'
# A locally modified kit-owned file must be called out as drift, not skipped silently
echo '# local modification' >> "$T1/.claude/skills/gate/SKILL.md"
drift_out=$(run_install "$T1")
says "a drifted kit file is called out as DIFFERS" \
  "$drift_out" 'gate/SKILL.md — already exists (your version kept — DIFFERS'

# --- 2b. an abort mid-run must still account for what landed ---------------------------
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

# --- 2c. the self-install guard covers ancestry, not just equality ---------------------
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

# --- 3. a .gitignore without a trailing newline survives intact ------------------------
echo "install.sh — .gitignore:"
T2="$WORK/nonl"; mkdir -p "$T2"
printf 'node_modules' > "$T2/.gitignore"
"$KIT/install.sh" "$T2" >/dev/null
check "user's rule kept as its own line"  grep -qx 'node_modules' "$T2/.gitignore"
check "kit's ignore line landed whole"    grep -qx '.claude/settings.local.json' "$T2/.gitignore"

# --- 4. junk in the kit tree never installs --------------------------------------------
echo "install.sh — junk filter:"
K2="$WORK/kitcopy"; mkdir -p "$K2"
cp -r "$KIT/.claude" "$K2/"; cp "$KIT"/*.md "$K2/" 2>/dev/null || true
cp "$KIT/install.sh" "$K2/"; cp "$KIT/ruff.toml" "$K2/" 2>/dev/null || true
cp "$KIT/.mcp.json.example" "$K2/" 2>/dev/null || true
mkdir -p "$K2/.github/workflows"
cp "$KIT/.github/workflows/ci.yml.example" "$K2/.github/workflows/" 2>/dev/null || true
mkdir -p "$K2/.claude/hooks/__pycache__"
touch "$K2/.claude/hooks/__pycache__/x.pyc" "$K2/.claude/hooks/.DS_Store" \
      "$K2/.claude/skills/x.swp" "$K2/.claude/skills/y~"
T3="$WORK/junk"; mkdir -p "$T3"
"$K2/install.sh" "$T3" >/dev/null
found=$(find "$T3" \( -name '*.pyc' -o -name '.DS_Store' -o -name '*.swp' -o -name '*~' \) | wc -l)
if [ "$found" -eq 0 ]; then ok "no junk landed"; else fail "no junk landed ($found found)"; fi
# ...and the filter did not achieve that by installing nothing at all
check "the legitimate kit files still landed" test -f "$T3/.claude/skills/gate/SKILL.md"

# --- 5. an existing settings.json: warn only when a hook is really unwired -------------
echo "install.sh — inert hooks warning:"
T4="$WORK/settings"; mkdir -p "$T4/.claude"
echo '{}' > "$T4/.claude/settings.json"
settings_out=$(run_install "$T4")
says "warning printed when settings.json registers no hooks" "$settings_out" 'NOT wired'
# A settings.json that differs from the kit's but registers all three hooks HAS them wired —
# the categorical warning would be false (an older kit stanza is the common case).
T4b="$WORK/settings-wired"; mkdir -p "$T4b/.claude"
sed '1a\
  "_note": "an older kit stanza",' "$KIT/.claude/settings.json" > "$T4b/.claude/settings.json"
wired_out=$(run_install "$T4b")
says_not "no false unwired warning when all three hooks are registered" "$wired_out" 'NOT wired'
says     "a differing but wired settings.json is reported as such" "$wired_out" 'registers all three'

# --- 6. Python tooling only lands in Python projects -----------------------------------
echo "install.sh — Python detection:"
T5="$WORK/js"; mkdir -p "$T5/node_modules" "$T5/.venv"; echo 'console.log(1)' > "$T5/app.js"
# A vendored .py must not make a JS project "Python" — the same prune list has to hold on
# the template path too (asserted in section 9).
: > "$T5/node_modules/vendored.py"; : > "$T5/.venv/lib.py"
"$KIT/install.sh" "$T5" >/dev/null
check "JS target with only vendored .py files gets no ruff.toml" test ! -e "$T5/ruff.toml"
if grep -q ruff_cache "$T5/.gitignore"; then
  fail "JS target gets no .ruff_cache ignore line"
else
  ok "JS target gets no .ruff_cache ignore line"
fi
T6="$WORK/py"; mkdir -p "$T6"; touch "$T6/pyproject.toml"
"$KIT/install.sh" "$T6" >/dev/null
check "Python target gets ruff.toml"           test -e "$T6/ruff.toml"
check "Python target gets .ruff_cache ignored" grep -q ruff_cache "$T6/.gitignore"
# The kit's own ruff.toml must go through the drift ladder on a re-run, not be misread as
# the user's config — that exemption made kit updates to it unreportable.
py_rerun=$(run_install "$T6")
says     "re-run calls the kit's own ruff.toml identical" "$py_rerun" 'ruff.toml — already exists (identical'
says_not "re-run does not misreport it as your own config" "$py_rerun" 'ruff.toml — you already configure'
echo '# mine now' >> "$T6/ruff.toml"
says "a modified ruff.toml is called out as DIFFERS" "$(run_install "$T6")" 'ruff.toml — your ruff config kept — DIFFERS'
# has_ruff_config: [tool.ruff] counts, [tool.ruffle] does not
T7="$WORK/pyproject-ruff"; mkdir -p "$T7"; printf '[tool.ruff]\nline-length = 88\n' > "$T7/pyproject.toml"
says "[tool.ruff] in pyproject is respected" "$(run_install "$T7")" 'you already configure ruff elsewhere'
check "…and no ruff.toml is dropped on top of it" test ! -e "$T7/ruff.toml"
T8="$WORK/pyproject-ruffle"; mkdir -p "$T8"; printf '[tool.ruffle]\nx = 1\n' > "$T8/pyproject.toml"
run_install "$T8" >/dev/null
check "[tool.ruffle] is not mistaken for ruff config" test -e "$T8/ruff.toml"

# --- 7. GUIDE.md collision: the kit's manual lands beside yours, and says when it is stale
echo "install.sh — GUIDE collision:"
T9="$WORK/ownguide"; mkdir -p "$T9"; echo '# my own guide' > "$T9/GUIDE.md"
guide_out=$(run_install "$T9")
check "your own GUIDE.md is untouched"  grep -qx '# my own guide' "$T9/GUIDE.md"
check "the kit's manual lands beside it" test -f "$T9/attest-GUIDE.md"
says  "the NEXT steps point at the file the manual is actually in" "$guide_out" 'attest-GUIDE.md PART 9'
echo '# stale' >> "$T9/attest-GUIDE.md"
says "a stale attest-GUIDE.md gets the refresh hint" "$(run_install "$T9")" 'attest-GUIDE.md — an older kit version'

# --- 8. the format hook only touches files inside the project --------------------------
echo "hooks — format containment:"
SHIM="$WORK/bin"; mkdir -p "$SHIM"
printf '#!/bin/sh\necho "$@" >> "%s/ruff-calls.log"\n' "$WORK" > "$SHIM/ruff"
chmod +x "$SHIM/ruff"
PROJ="$WORK/proj"; mkdir -p "$PROJ"; : > "$PROJ/in.py"; : > "$WORK/out.py"
for f in "$PROJ/in.py" "$WORK/out.py"; do
  echo "{\"tool_input\":{\"file_path\":\"$f\"}}" |
    PATH="$SHIM:$PATH" CLAUDE_PROJECT_DIR="$PROJ" python3 "$KIT/.claude/hooks/format_py.py"
done
calls=$(cat "$WORK/ruff-calls.log" 2>/dev/null || true)
says     "the hook formats a file inside the project"     "$calls" 'in\.py'
says_not "the hook leaves files outside the project alone" "$calls" 'out\.py'
says     "the hook runs ruff without minting a cache"      "$calls" '\-\-no-cache'

# --- 9. template-cleanup removes attest's files and nothing of yours -------------------
echo "template-cleanup:"
GEN="$WORK/generated"; mkdir -p "$GEN"
cp -r "$KIT/.claude" "$GEN/"; cp "$KIT"/*.md "$GEN/"; cp "$KIT/install.sh" "$KIT/ruff.toml" "$GEN/"
cp "$KIT/LICENSE" "$GEN/"; mkdir -p "$GEN/docs" "$GEN/scripts" "$GEN/.github/workflows"
cp "$KIT"/docs/*.md "$GEN/docs/"; cp "$KIT/scripts/smoke.sh" "$KIT/scripts/template-cleanup.sh" "$GEN/scripts/"
cp "$KIT/.github/workflows/ci.yml" "$KIT/.github/workflows/ci.yml.example" "$GEN/.github/workflows/"
# what the user added before the workflow ever ran
echo 'my notes' > "$GEN/docs/design.md"; echo 'echo deploy' > "$GEN/scripts/deploy.sh"
# Vendored .py files: the cleanup's prune list must match install.sh's has_python_markers,
# or the two adoption paths disagree about whether this repo is Python (ADR-0015 parity).
mkdir -p "$GEN/node_modules" "$GEN/.venv"; : > "$GEN/node_modules/vendored.py"; : > "$GEN/.venv/lib.py"
(cd "$GEN" && bash scripts/template-cleanup.sh >/dev/null)
check "attest's own docs are gone"        test ! -e "$GEN/docs/attest-devlog.md"
check "attest's installer is gone"        test ! -e "$GEN/install.sh"
check "attest's own CI is gone"           test ! -e "$GEN/.github/workflows/ci.yml"
check "YOUR docs survive"                 test -f "$GEN/docs/design.md"
check "YOUR scripts survive"              test -f "$GEN/scripts/deploy.sh"
check "the CI example is left for you"    test -f "$GEN/.github/workflows/ci.yml.example"
check "the kit itself is left in place"   test -f "$GEN/.claude/skills/gate/SKILL.md"
check "attest's LICENSE became a skeleton" grep -q '<YEAR>' "$GEN/LICENSE"
check "attest's README became a stub"      grep -q '^# <your project>' "$GEN/README.md"
check "no-Python repo keeps no ruff.toml (vendored .py does not count)" test ! -e "$GEN/ruff.toml"
# Files of your own that happen to carry attest's names must survive too: ci.yml is exactly
# what the stub README tells you to make out of ci.yml.example, and smoke.sh is a generic name.
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
