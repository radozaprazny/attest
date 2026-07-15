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
  done < <(find "$KIT/$dir" -type f -print0)
}

# ensure_ignore <line> — append to .gitignore, never overwrite it
ensure_ignore() {
  local line="$1"
  touch "$TARGET/.gitignore"
  if grep -qxF "$line" "$TARGET/.gitignore" 2>/dev/null; then
    return 0
  fi
  printf '%s\n' "$line" >> "$TARGET/.gitignore"
  note_installed ".gitignore += $line"
}

has_ruff_config() {
  # matches [tool.ruff], indented, and the quoted [tool."ruff"] form — all valid TOML
  [ -f "$TARGET/ruff.toml" ] || [ -f "$TARGET/.ruff.toml" ] ||
    grep -Eq '^[[:space:]]*\[tool\.("?)ruff\1' "$TARGET/pyproject.toml" 2>/dev/null
}

echo "attest → $TARGET"
echo

# --- the five control documents (templates; yours win if they exist) -----------------
for doc in CLAUDE.md PROGRESS.md BUSINESS.md DECISIONS.md COMPLIANCE.md; do
  copy_if_absent "$doc" "document"
done

# --- the reference guide: this one always lands ---------------------------------------
# The installed skills reference "GUIDE PART 1/2/3" at runtime — the shared audit ladder and
# the audit-ownership contract exist ONLY there, so an install without it leaves every audit's
# severity undefined. If you already have a GUIDE.md of your own, ours goes in beside it.
if [ ! -e "$TARGET/GUIDE.md" ] && [ ! -L "$TARGET/GUIDE.md" ]; then
  cp "$KIT/GUIDE.md" "$TARGET/GUIDE.md"
  note_installed "GUIDE.md"
elif [ ! -e "$TARGET/attest-GUIDE.md" ] && [ ! -L "$TARGET/attest-GUIDE.md" ]; then
  cp "$KIT/GUIDE.md" "$TARGET/attest-GUIDE.md"
  note_installed "attest-GUIDE.md (you have your own GUIDE.md — the skills' \"GUIDE PART N\" references mean this file)"
else
  note_skipped "GUIDE.md" "both GUIDE.md and attest-GUIDE.md exist — the skills' \"GUIDE PART N\" refs may dangle"
fi

# --- .claude/ — per file, so your own skills/commands/settings are never touched ------
copy_tree_if_absent ".claude/skills"
copy_tree_if_absent ".claude/agents"
copy_tree_if_absent ".claude/hooks"
copy_tree_if_absent ".claude/commands"
copy_if_absent ".claude/settings.json" "settings"

# --- ruff: skip if the project already configures it ---------------------------------
# ruff resolves ruff.toml > .ruff.toml > pyproject.toml and does NOT merge, so copying ours
# in would silently hijack an existing config while leaving it on disk as dead code.
if has_ruff_config; then
  note_skipped "ruff.toml" "you already configure ruff (ours would silently override it)"
else
  copy_if_absent "ruff.toml" "config"
fi

# --- optional MCP example -------------------------------------------------------------
copy_if_absent ".mcp.json.example" "example"

# --- .gitignore: append the lines the kit needs, never replace the file ----------------
ensure_ignore ".claude/settings.local.json"
ensure_ignore ".ruff_cache/"

# --- report ---------------------------------------------------------------------------
echo "INSTALLED (${#INSTALLED[@]}):"
if [ ${#INSTALLED[@]} -eq 0 ]; then echo "  (nothing — everything was already present)"; fi
for i in "${INSTALLED[@]:-}"; do [ -n "$i" ] && echo "  + $i"; done

echo
echo "SKIPPED (${#SKIPPED[@]}) — left untouched, merge by hand if you want the kit's version:"
if [ ${#SKIPPED[@]} -eq 0 ]; then echo "  (nothing)"; fi
for s in "${SKIPPED[@]:-}"; do [ -n "$s" ] && echo "  · $s"; done

cat <<'EOF'

NEXT
  1. Restart Claude Code — .claude/ is a new top-level directory, so the skills only load
     on a fresh session. Until then /init-tier does not exist.
  2. Fill CLAUDE.md — it is loaded every turn and ships with <placeholders>. No skill owns
     it; `/init` is the fastest way.
  3. /init-tier   — declare intent + archetype (BUSINESS.md)
     /compliance  — only if you are in regulated scope (COMPLIANCE.md)
  4. Everything else: GUIDE.md PART 9 (the whole loop).

Not installed on purpose: README.md and LICENSE describe attest, not your project.
EOF
