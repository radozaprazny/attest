#!/usr/bin/env bash
# install.sh — install the attest kit into a project.
#
# Never clobbers. Every file is copy-if-absent; anything already present is left exactly as
# it is and reported as SKIPPED for you to merge by hand. Nothing here is attest's identity:
# README.md and LICENSE describe *attest* and are deliberately not installed.
#
#   ./install.sh <path-to-your-project>

set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET="${1:-}"

[ -n "$TARGET" ] || { echo "usage: ./install.sh <path-to-your-project>" >&2; exit 2; }
[ -d "$TARGET" ] || { echo "install.sh: no such directory: $TARGET" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd -P)"   # -P: resolve symlinks, so the self-install guard holds
[ "$TARGET" != "$KIT" ] || { echo "install.sh: refusing to install the kit into itself" >&2; exit 2; }

INSTALLED=()
SKIPPED=()

note_installed() { INSTALLED+=("$1"); }
note_skipped()   { SKIPPED+=("$1 — $2"); }

# copy_if_absent <relative-path> [reason-noun]
copy_if_absent() {
  local rel="$1" what="${2:-file}"
  # -L too: a dangling symlink is not -e, but cp must not write through it either
  if [ -e "$TARGET/$rel" ] || [ -L "$TARGET/$rel" ]; then
    note_skipped "$rel" "already exists (your $what kept)"
  else
    mkdir -p "$(dirname "$TARGET/$rel")"
    cp "$KIT/$rel" "$TARGET/$rel"
    note_installed "$rel"
  fi
}

# copy_tree_if_absent <relative-dir> — per-file, never a blanket cp -r
copy_tree_if_absent() {
  local dir="$1" rel
  [ -d "$KIT/$dir" ] || return 0
  while IFS= read -r -d '' src; do
    rel="${src#"$KIT"/}"   # quoted: $KIT is a literal here, not a glob
    copy_if_absent "$rel" "version"
  done < <(find "$KIT/$dir" -type f \
      ! -name '*.pyc' ! -name '.DS_Store' ! -name '*.swp' ! -name '*~' \
      ! -path '*/__pycache__/*' -print0)
}

# ensure_ignore <line> — append to .gitignore, never overwrite it
ensure_ignore() {
  local line="$1"
  # Never write through a symlinked .gitignore: touch would follow it (creating a file
  # outside the project, or aborting the whole run on an unwritable path).
  if [ -L "$TARGET/.gitignore" ]; then
    note_skipped ".gitignore += $line" "your .gitignore is a symlink — append it yourself"
    return 0
  fi
  touch "$TARGET/.gitignore"
  if grep -qxF "$line" "$TARGET/.gitignore" 2>/dev/null; then
    return 0
  fi
  # If the file's last byte is not a newline, appending would glue our line onto the
  # user's last rule — breaking theirs and losing ours. Complete their line first.
  if [ -s "$TARGET/.gitignore" ] && [ -n "$(tail -c1 "$TARGET/.gitignore")" ]; then
    echo >> "$TARGET/.gitignore"
  fi
  printf '%s\n' "$line" >> "$TARGET/.gitignore"
  note_installed ".gitignore += $line"
}

has_ruff_config() {
  # matches [tool.ruff], indented, and the quoted [tool."ruff"] form — all valid TOML
  [ -f "$TARGET/ruff.toml" ] || [ -f "$TARGET/.ruff.toml" ] ||
    grep -Eq '^[[:space:]]*\[tool\.("?)ruff\1' "$TARGET/pyproject.toml" 2>/dev/null
}

has_python_markers() {
  # .claude/ excluded: the kit's own hooks are .py and would make every target "Python".
  # -print -quit short-circuits on the first hit; vendor/VCS dirs pruned for speed.
  [ -f "$TARGET/pyproject.toml" ] || [ -f "$TARGET/setup.py" ] || [ -f "$TARGET/setup.cfg" ] ||
    [ -f "$TARGET/requirements.txt" ] ||
    [ -n "$(find "$TARGET" -name '*.py' -not -path "$TARGET/.claude/*" \
        -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/.venv/*' \
        -print -quit 2>/dev/null)" ]
}

echo "attest → $TARGET"
echo

# --- the five control documents (templates; yours win if they exist) -----------------
CLAUDE_INSTALLED=0
[ -e "$TARGET/CLAUDE.md" ] || CLAUDE_INSTALLED=1
for doc in CLAUDE.md PROGRESS.md BUSINESS.md DECISIONS.md COMPLIANCE.md; do
  copy_if_absent "$doc" "document"
done

# --- the reference guide: this one always lands ---------------------------------------
# GUIDE.md is the kit's reference manual, not a runtime dependency: the shared audit ladder and
# the ownership contract live in .claude/skills/_shared/audit-ladder.md, which installs with the
# skills that read it (ADR-0010). The "GUIDE PART N" references in the skills are documentation
# pointers — a dangling one costs a reader a lookup, not an audit its severity.
if [ ! -e "$TARGET/GUIDE.md" ] && [ ! -L "$TARGET/GUIDE.md" ]; then
  cp "$KIT/GUIDE.md" "$TARGET/GUIDE.md"
  note_installed "GUIDE.md"
  # A leftover attest-GUIDE.md from an earlier dual-install would now shadow nothing —
  # point it out (never delete it ourselves).
  if [ -e "$TARGET/attest-GUIDE.md" ] || [ -L "$TARGET/attest-GUIDE.md" ]; then
    note_skipped "attest-GUIDE.md" "leftover from an earlier install — GUIDE.md is now the kit's; delete it if you no longer keep your own guide"
  fi
elif cmp -s "$KIT/GUIDE.md" "$TARGET/GUIDE.md"; then
  # A re-run: the GUIDE.md present is the kit's own prior install — not the user's.
  note_skipped "GUIDE.md" "already the kit's version (re-run)"
elif head -n1 "$TARGET/GUIDE.md" 2>/dev/null | grep -qF '# GUIDE.md — reference guide'; then
  # The kit's own manual from an older install — never clobber, but say what to do.
  note_skipped "GUIDE.md" "an older kit version — copy $KIT/GUIDE.md over it by hand to refresh"
elif [ ! -e "$TARGET/attest-GUIDE.md" ] && [ ! -L "$TARGET/attest-GUIDE.md" ]; then
  cp "$KIT/GUIDE.md" "$TARGET/attest-GUIDE.md"
  note_installed "attest-GUIDE.md (you have your own GUIDE.md — the skills' \"GUIDE PART N\" references mean this file)"
elif cmp -s "$KIT/GUIDE.md" "$TARGET/attest-GUIDE.md"; then
  note_skipped "attest-GUIDE.md" "already the kit's version (re-run)"
else
  note_skipped "GUIDE.md" "both GUIDE.md and attest-GUIDE.md exist — the skills' \"GUIDE PART N\" refs point at whichever is ours"
fi

# --- .claude/ — per file, so your own skills/agents/hooks/settings are never touched --
copy_tree_if_absent ".claude/skills"
copy_tree_if_absent ".claude/agents"
copy_tree_if_absent ".claude/hooks"
# Warn about unwired hooks only when the kept settings.json actually differs from the
# kit's (a byte-identical file — a re-run — has the hooks wired already). Same
# present-predicate as copy_if_absent (-e or -L), so a dangling symlink still warns.
SETTINGS_KEPT=0
if [ -e "$TARGET/.claude/settings.json" ] || [ -L "$TARGET/.claude/settings.json" ]; then
  cmp -s "$KIT/.claude/settings.json" "$TARGET/.claude/settings.json" 2>/dev/null || SETTINGS_KEPT=1
fi
copy_if_absent ".claude/settings.json" "settings"

# --- ruff: only into Python projects, and never over an existing config ---------------
# ruff resolves ruff.toml > .ruff.toml > pyproject.toml and does NOT merge, so copying ours
# in would silently hijack an existing config while leaving it on disk as dead code. And a
# repo with no Python gets no Python residue (ADR-0015) — the format hook stays inert there.
if has_ruff_config; then
  note_skipped "ruff.toml" "you already configure ruff (ours would silently override it)"
elif ! has_python_markers; then
  note_skipped "ruff.toml" "no Python detected — see GUIDE PART 2 to swap the formatter unit"
else
  copy_if_absent "ruff.toml" "config"
fi

# --- optional MCP example -------------------------------------------------------------
copy_if_absent ".mcp.json.example" "example"

# --- .gitignore: append the lines the kit needs, never replace the file ----------------
ensure_ignore ".claude/settings.local.json"
if has_python_markers || [ -e "$TARGET/ruff.toml" ]; then
  ensure_ignore ".ruff_cache/"
fi

# --- report ---------------------------------------------------------------------------
echo "INSTALLED (${#INSTALLED[@]}):"
if [ ${#INSTALLED[@]} -eq 0 ]; then echo "  (nothing — everything was already present)"; fi
for i in "${INSTALLED[@]:-}"; do [ -n "$i" ] && echo "  + $i"; done

echo
echo "SKIPPED (${#SKIPPED[@]}) — left untouched, merge by hand if you want the kit's version:"
if [ ${#SKIPPED[@]} -eq 0 ]; then echo "  (nothing)"; fi
for s in "${SKIPPED[@]:-}"; do [ -n "$s" ] && echo "  · $s"; done

# --- honesty about what will NOT run ---------------------------------------------------
if [ "$SETTINGS_KEPT" = 1 ]; then
  cat <<'EOF'

⚠ Your .claude/settings.json was kept — so the kit's hooks are on disk but NOT wired:
  none of them will run until you merge this stanza into your .claude/settings.json:

EOF
  sed 's/^/    /' "$KIT/.claude/settings.json"
fi

if ! command -v python3 >/dev/null 2>&1; then
  cat <<'EOF'

⚠ python3 is not on PATH — the three hooks in .claude/hooks/ will fail on every matching
  event until it is installed (or delete their entries from .claude/settings.json).
EOF
fi

echo
echo "NEXT"
n=1
echo "  $n. Restart Claude Code if .claude/ (or .claude/skills/) is new to this project —"
echo "     skills only load on a fresh session. Until then /business does not exist."
n=$((n+1))
if [ "$CLAUDE_INSTALLED" = 1 ]; then
  echo "  $n. Fill CLAUDE.md — it is loaded every turn and ships with <placeholders>. No skill"
  echo "     owns it; /init is the fastest way."
  n=$((n+1))
fi
echo "  $n. /business    — declare intent + archetype (BUSINESS.md)"
echo "     /compliance  — only if you are in regulated scope (COMPLIANCE.md)"
n=$((n+1))
echo "  $n. Everything else: GUIDE.md PART 9 (the whole loop)."
echo
echo "Not installed on purpose: README.md and LICENSE describe attest, not your project."
