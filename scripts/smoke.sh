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
rerun_out=$("$KIT/install.sh" "$T1")
if printf '%s' "$rerun_out" | grep -q '^INSTALLED (0)'; then
  ok "second run installs nothing"
else
  fail "second run installs nothing"
fi
check "second run minted no attest-GUIDE.md" test ! -e "$T1/attest-GUIDE.md"
if printf '%s' "$rerun_out" | grep -q 'NOT wired'; then
  fail "re-run does not false-warn about unwired hooks"
else
  ok "re-run does not false-warn about unwired hooks"
fi

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
mkdir -p "$K2/.claude/hooks/__pycache__"
touch "$K2/.claude/hooks/__pycache__/x.pyc" "$K2/.claude/hooks/.DS_Store" \
      "$K2/.claude/skills/x.swp" "$K2/.claude/skills/y~"
T3="$WORK/junk"; mkdir -p "$T3"
"$K2/install.sh" "$T3" >/dev/null
found=$(find "$T3" \( -name '*.pyc' -o -name '.DS_Store' -o -name '*.swp' -o -name '*~' \) | wc -l)
if [ "$found" -eq 0 ]; then ok "no junk landed"; else fail "no junk landed ($found found)"; fi

# --- 5. existing settings.json → the inert-hooks warning must fire ---------------------
echo "install.sh — inert hooks warning:"
T4="$WORK/settings"; mkdir -p "$T4/.claude"
echo '{}' > "$T4/.claude/settings.json"
settings_out=$("$KIT/install.sh" "$T4")
if printf '%s' "$settings_out" | grep -q 'NOT wired'; then
  ok "warning printed when settings.json is kept"
else
  fail "warning printed when settings.json is kept"
fi

# --- 6. Python tooling only lands in Python projects -----------------------------------
echo "install.sh — Python detection:"
T5="$WORK/js"; mkdir -p "$T5"; echo 'console.log(1)' > "$T5/app.js"
"$KIT/install.sh" "$T5" >/dev/null
check "JS target gets no ruff.toml" test ! -e "$T5/ruff.toml"
if grep -q ruff_cache "$T5/.gitignore"; then
  fail "JS target gets no .ruff_cache ignore line"
else
  ok "JS target gets no .ruff_cache ignore line"
fi
T6="$WORK/py"; mkdir -p "$T6"; touch "$T6/pyproject.toml"
"$KIT/install.sh" "$T6" >/dev/null
check "Python target gets ruff.toml"           test -e "$T6/ruff.toml"
check "Python target gets .ruff_cache ignored" grep -q ruff_cache "$T6/.gitignore"

# --- verdict ---------------------------------------------------------------------------
echo
echo "smoke: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
