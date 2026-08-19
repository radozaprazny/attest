#!/usr/bin/env bash
# install.sh — install the attest kit into a project.
#
# Never clobbers. Every file is copy-if-absent; anything already present is left exactly as
# it is and reported as SKIPPED for you to merge by hand. Nothing here is attest's identity:
# README.md and LICENSE describe *attest* and are deliberately not installed.
#
#   ./install.sh <path-to-your-project>

set -Eeuo pipefail   # -E: the ERR trap below must fire from inside functions too

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET="${1:-}"

[ -n "$TARGET" ] || { echo "usage: ./install.sh <path-to-your-project>" >&2; exit 2; }
[ -d "$TARGET" ] || { echo "install.sh: no such directory: $TARGET" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd -P)"   # -P: resolve symlinks, so the self-install guard holds
# Ancestry, not just equality: installing into a subdirectory of the kit (a mistyped
# tab-completion) or into a directory that contains it would litter the checkout with a
# second copy. The trailing slashes make the prefix test exact — and TARGET == KIT is the
# degenerate case of the first pattern.
# Both sides carry exactly one trailing slash, so the prefix test is exact and "/" (where
# pwd -P leaves no trailing component) behaves like any other directory. The prefixes are
# built as variables first: "${VAR%/}"/* would put a *quoted null* in the pattern, which bash
# matches literally — the guard would then silently never fire for TARGET=/.
KIT_P="${KIT%/}/"
TARGET_P="${TARGET%/}/"
case "$TARGET_P" in "$KIT_P"*)
  echo "install.sh: refusing to install the kit into itself (or into a directory inside it)" >&2; exit 2 ;;
esac
case "$KIT_P" in "$TARGET_P"*)
  echo "install.sh: refusing to install the kit into a directory that contains it" >&2; exit 2 ;;
esac

INSTALLED=()
SKIPPED=()

# An abort mid-run (unwritable path, .claude present as a regular file, disk full) leaves a
# partial install and skips the report below — so say what landed and that a re-run is safe.
on_abort() {
  local code=$?
  echo >&2
  echo "install.sh: ABORTED (exit $code) — this install is PARTIAL." >&2
  if [ "${#INSTALLED[@]}" -gt 0 ]; then
    echo "  landed before the failure:" >&2
    for i in "${INSTALLED[@]}"; do echo "    + $i" >&2; done
  else
    echo "  nothing had been written yet." >&2
  fi
  echo "  Fix the cause and re-run: every write is copy-if-absent, so a re-run resumes safely." >&2
}
trap on_abort ERR

note_installed() { INSTALLED+=("$1"); }
note_skipped()   { SKIPPED+=("$1 — $2"); }

# copy_if_absent <relative-path> [reason-noun]
copy_if_absent() {
  local rel="$1" what="${2:-file}"
  # A file this kit checkout does not have is not an error to abort on — an older kit, or a
  # partial copy, simply has nothing to install here.
  [ -e "$KIT/$rel" ] || return 0
  # -L too: a dangling symlink is not -e, but cp must not write through it either
  if [ -e "$TARGET/$rel" ] || [ -L "$TARGET/$rel" ]; then
    if cmp -s "$KIT/$rel" "$TARGET/$rel" 2>/dev/null; then
      note_skipped "$rel" "already exists (identical to the kit's — a re-run, nothing to merge)"
    elif [ "$what" = "version" ]; then
      # Kit-owned trees (skills/hooks/agents): a silently stale copy is how installs
      # freeze — say that it drifted and where the fresh copy sits (ADR-0018).
      note_skipped "$rel" "already exists (your version kept — DIFFERS from the kit's; diff against $KIT/$rel to upgrade)"
    else
      note_skipped "$rel" "already exists (your $what kept)"
    fi
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
  # matches [tool.ruff] and [tool.ruff.lint], indented, and the quoted [tool."ruff"] forms —
  # all valid TOML. The trailing [].] class is what keeps [tool.ruffle] out; the alternation
  # replaces a \1 backreference, which is a GNU extension and undefined in POSIX ERE (BSD).
  [ -f "$TARGET/.ruff.toml" ] ||
    grep -Eq '^[[:space:]]*\[tool\.(ruff|"ruff")[].]' "$TARGET/pyproject.toml" 2>/dev/null
}

has_python_markers() {
  # .claude/ excluded: the kit's own hooks are .py and would make every target "Python".
  # -print -quit short-circuits on the first hit; vendor/VCS dirs pruned for speed.
  [ -f "$TARGET/pyproject.toml" ] || [ -f "$TARGET/setup.py" ] || [ -f "$TARGET/setup.cfg" ] ||
    [ -f "$TARGET/requirements.txt" ] ||
    [ -n "$(find "$TARGET" \( -name .claude -o -name .git -o -name node_modules -o -name .venv \) \
        -prune -o -name '*.py' -print -quit 2>/dev/null)" ]
}

# The kit's one version marker lives inside the shared ladder, so it travels with every
# install (ADR-0018) — there is no separate VERSION file to copy or clean up.
KIT_VERSION="$(sed -n 's/^Kit version: \([^ ]*\).*/\1/p' "$KIT/.claude/skills/_shared/audit-ladder.md" 2>/dev/null || true)"
echo "attest${KIT_VERSION:+ $KIT_VERSION} → $TARGET"
echo

# --- the five control documents (templates; yours win if they exist) -----------------
CLAUDE_INSTALLED=0
{ [ -e "$TARGET/CLAUDE.md" ] || [ -L "$TARGET/CLAUDE.md" ]; } || CLAUDE_INSTALLED=1
for doc in CLAUDE.md PROGRESS.md BUSINESS.md DECISIONS.md COMPLIANCE.md; do
  copy_if_absent "$doc" "document"
done

# --- the reference guide: this one always lands ---------------------------------------
# GUIDE.md is the kit's reference manual, not a runtime dependency: the shared audit ladder and
# the ownership contract live in .claude/skills/_shared/audit-ladder.md, which installs with the
# skills that read it (ADR-0010). The "GUIDE PART N" references in the skills are documentation
# pointers — a dangling one costs a reader a lookup, not an audit its severity.
GUIDE_REF="GUIDE.md"   # which file the kit's manual ended up in — the NEXT steps cite it
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
  GUIDE_REF="attest-GUIDE.md"
  note_installed "attest-GUIDE.md (you have your own GUIDE.md — the skills' \"GUIDE PART N\" references mean this file)"
elif cmp -s "$KIT/GUIDE.md" "$TARGET/attest-GUIDE.md"; then
  GUIDE_REF="attest-GUIDE.md"
  note_skipped "attest-GUIDE.md" "already the kit's version (re-run)"
else
  # Your own GUIDE.md plus an attest-GUIDE.md that is neither current nor yours: it is the
  # kit's manual from an older install. Same refresh hint the GUIDE.md branch gets — without
  # it this path is the one place a stale manual can never be noticed (ADR-0018).
  GUIDE_REF="attest-GUIDE.md"
  note_skipped "attest-GUIDE.md" "an older kit version — copy $KIT/GUIDE.md over it by hand to refresh (your own GUIDE.md is untouched; the skills' \"GUIDE PART N\" refs mean attest-GUIDE.md)"
fi

# --- .claude/ — per file, so your own skills/agents/hooks/settings are never touched --
copy_tree_if_absent ".claude/skills"
copy_tree_if_absent ".claude/agents"
copy_tree_if_absent ".claude/hooks"
# Warn about unwired hooks only when the kept settings.json really leaves a hook unwired.
# "Differs from the kit's" is not the same question: an older kit stanza — or yours with the
# kit's hooks merged in — registers all three already, and the categorical warning would be
# false (ADR-0020). So ask the file which hooks it names. Same present-predicate as
# copy_if_absent (-e or -L): a dangling symlink names nothing and warns.
SETTINGS_STATE="absent"
if [ -e "$TARGET/.claude/settings.json" ] || [ -L "$TARGET/.claude/settings.json" ]; then
  if cmp -s "$KIT/.claude/settings.json" "$TARGET/.claude/settings.json" 2>/dev/null; then
    SETTINGS_STATE="identical"
  else
    SETTINGS_STATE="wired"
    for hook in format_py.py precompact_checkpoint_nudge.py stop_session_length_warn.py; do
      grep -qF "$hook" "$TARGET/.claude/settings.json" 2>/dev/null || SETTINGS_STATE="unwired"
    done
  fi
fi
copy_if_absent ".claude/settings.json" "settings"

# --- ruff: only into Python projects, and never over an existing config ---------------
# ruff resolves ruff.toml > .ruff.toml > pyproject.toml and does NOT merge, so copying ours
# in would silently hijack an existing config while leaving it on disk as dead code. And a
# repo with no Python gets no Python residue (ADR-0015) — the format hook stays inert there.
#
# An existing ruff.toml is judged FIRST and by content, not by the has_ruff_config predicate:
# after one install that file is usually the kit's own, and reporting it as "you already
# configure ruff" would both lie and exempt it from the identical-vs-DIFFERS drift ladder
# every other kit file gets (ADR-0018, ADR-0020).
if [ -e "$TARGET/ruff.toml" ] || [ -L "$TARGET/ruff.toml" ]; then
  if cmp -s "$KIT/ruff.toml" "$TARGET/ruff.toml" 2>/dev/null; then
    note_skipped "ruff.toml" "already exists (identical to the kit's — a re-run, nothing to merge)"
  else
    note_skipped "ruff.toml" "your ruff config kept — DIFFERS from the kit's (ours would have overridden it; diff against $KIT/ruff.toml to see what the kit ships)"
  fi
elif has_ruff_config; then
  note_skipped "ruff.toml" "you already configure ruff elsewhere (ours would silently override it)"
elif ! has_python_markers; then
  note_skipped "ruff.toml" "no Python detected — see GUIDE PART 2 to swap the formatter unit"
else
  copy_if_absent "ruff.toml" "config"
fi

# --- optional examples: yours to rename and adapt, never live as shipped ---------------
# "version" noun: both are kit-owned files, so an upstream change must show as DIFFERS
# rather than as a silent "your example kept" (ADR-0018).
copy_if_absent ".mcp.json.example" "version"
# The one file in .github/ written FOR the consumer. Everything else under .github/ is
# attest's own CI and stays behind (ADR-0021).
copy_if_absent ".github/workflows/ci.yml.example" "version"

# --- .gitignore: append the lines the kit needs, never replace the file ----------------
ensure_ignore ".claude/settings.local.json"
# The gate's run records under .attest/ are meant to be committed; only its scratch is not.
ensure_ignore ".attest/tmp/"
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
if [ "$SETTINGS_STATE" = "unwired" ]; then
  cat <<'EOF'

⚠ Your .claude/settings.json was kept and does not register all of the kit's hooks — the
  ones it leaves out are on disk but NOT wired, and will not run until you merge this
  stanza into your .claude/settings.json:

EOF
  sed 's/^/    /' "$KIT/.claude/settings.json"
elif [ "$SETTINGS_STATE" = "wired" ]; then
  cat <<EOF

· Your .claude/settings.json was kept. It differs from the kit's but registers all three
  hooks, so they will run. Diff it against $KIT/.claude/settings.json if you want the
  kit's current stanza.
EOF
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
echo "  $n. Everything else: $GUIDE_REF PART 9 (the whole loop)."
echo
echo "Not installed on purpose: README.md and LICENSE describe attest, not your project."
