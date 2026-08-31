#!/usr/bin/env bash
# install.sh — install the attest kit into a project.
#
# Never clobbers. Every file is copy-if-absent; anything already present is left exactly as
# it is and reported for you to merge by hand. Nothing here is attest's identity: README.md
# and LICENSE describe *attest* and are deliberately not installed.
#
# The report is grouped by CAPABILITY, not by path (attest ADR-0031): what you can now do,
# what stayed yours, what did not land and why. The per-file detail prints only when there is
# something a human actually has to act on.
#
#   ./install.sh [--compliance] <path-to-your-project>

set -Eeuo pipefail   # -E: the ERR trap below must fire from inside functions too

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET=""
WANT_COMPLIANCE=0

usage() {   # usage [exit-code] — a requested --help is not an error, so it exits 0 on stdout
  local code="${1:-2}"
  if [ "$code" = 0 ]; then echo "usage: ./install.sh [--compliance] <path-to-your-project>"
  else echo "usage: ./install.sh [--compliance] <path-to-your-project>" >&2; fi
  exit "$code"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --compliance) WANT_COMPLIANCE=1 ;;
    -h|--help)    usage 0 ;;
    -*)           echo "install.sh: unknown option: $1" >&2; usage ;;
    *)            [ -z "$TARGET" ] || { echo "install.sh: more than one target given" >&2; usage; }
                  TARGET="$1" ;;
  esac
  shift
done

[ -n "$TARGET" ] || usage
[ -d "$TARGET" ] || { echo "install.sh: no such directory: $TARGET" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd -P)"   # -P: resolve symlinks, so the self-install guard holds
# Ancestry, not just equality: installing into a subdirectory of the kit (a mistyped
# tab-completion) or into a directory that contains it would litter the checkout with a
# second copy. The trailing slashes make the prefix test exact — and TARGET == KIT is the
# degenerate case of the first pattern. The prefixes are built as variables first:
# "${VAR%/}"/* would put a *quoted null* in the pattern, which bash matches literally — the
# guard would then silently never fire for TARGET=/.
KIT_P="${KIT%/}/"
TARGET_P="${TARGET%/}/"
case "$TARGET_P" in "$KIT_P"*)
  echo "install.sh: refusing to install the kit into itself (or into a directory inside it)" >&2; exit 2 ;;
esac
case "$KIT_P" in "$TARGET_P"*)
  echo "install.sh: refusing to install the kit into a directory that contains it" >&2; exit 2 ;;
esac

INSTALLED=()
KEPT=()               # yours, left exactly as they were — informational, never a warning
NEEDS_YOU=()          # the kit moved and your copy did not, or a hook is on disk but unwired
LINES=()              # the report, buffered: a run that changed nothing prints one line instead
LAST=""               # per-file outcome: new | same | kept | drift | none

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

note_needs_you() { NEEDS_YOU+=("$1 — $2"); }

# copy_if_absent <relative-path> [reason-noun] — sets LAST
copy_if_absent() {
  local rel="$1" what="${2:-file}"
  LAST="none"
  # A file this kit checkout does not have is not an error to abort on — an older kit, or a
  # partial copy, simply has nothing to install here.
  [ -e "$KIT/$rel" ] || return 0
  # -L too: a dangling symlink is not -e, but cp must not write through it either
  if [ -e "$TARGET/$rel" ] || [ -L "$TARGET/$rel" ]; then
    if cmp -s "$KIT/$rel" "$TARGET/$rel" 2>/dev/null; then
      LAST="same"
    elif [ "$what" = "version" ]; then
      # Kit-owned trees (skills/hooks/agents): a silently stale copy is how installs
      # freeze — say that it drifted and where the fresh copy sits (ADR-0018). This one
      # really is an action: the kit moved and your copy did not.
      LAST="drift"
      note_needs_you "$rel" "yours kept, but it DIFFERS from the kit's — diff against $KIT/$rel to upgrade"
    else
      # A DOCUMENT of yours that the kit also ships is the DESIGNED outcome, not a problem:
      # it is reported as kept, never as something to fix (ADR-0031). Only documents go in
      # that bucket — settings.json is judged by whether it leaves a hook unwired, and listing
      # it here too would print one file twice under opposite framings.
      # An `[ … ] && …` here would leave the function returning 1 for a non-document, which
      # `set -e` plus the ERR trap turns into a bogus "ABORTED, partial install".
      LAST="kept"
      if [ "$what" = "document" ]; then KEPT+=("$rel"); fi
    fi
  else
    mkdir -p "$(dirname "$TARGET/$rel")"
    cp "$KIT/$rel" "$TARGET/$rel"
    INSTALLED+=("$rel")
    LAST="new"
  fi
}

# Group accounting: every group ends up as one line. G_NEW counts what landed, G_ACT counts
# what the human must act on; the icon follows from those two, so no caller decides it.
G_NEW=0; G_ACT=0
group_reset() { G_NEW=0; G_ACT=0; }
group_add() {   # group_add <path> [noun] — copy and fold the outcome into the group
  copy_if_absent "$1" "${2:-version}"
  case "$LAST" in
    new)    G_NEW=$((G_NEW + 1)) ;;
    drift)  G_ACT=$((G_ACT + 1)) ;;
  esac
}
group_icon() { if [ "$G_ACT" -gt 0 ]; then echo "⚠"; elif [ "$G_NEW" -gt 0 ]; then echo "✓"; else echo "·"; fi; }
# say <icon> <label> <text> — only the label is padded, and it is always ASCII. Padding the
# content column instead would misalign the moment a "·" separator appeared in it: printf
# counts bytes, and every box-drawing character costs two or three of them (ADR-0031).
say() { LINES+=("$(printf '  %s  %-10s %s' "$1" "$2" "$3")"); }

# copy_tree_if_absent <relative-dir> — per-file, never a blanket cp -r
copy_tree_if_absent() {
  local dir="$1" rel
  [ -d "$KIT/$dir" ] || return 0
  while IFS= read -r -d '' src; do
    rel="${src#"$KIT"/}"   # quoted: $KIT is a literal here, not a glob
    group_add "$rel" "version"
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
    note_needs_you ".gitignore += $line" "your .gitignore is a symlink — append the line yourself"
    G_ACT=$((G_ACT + 1))
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
  INSTALLED+=(".gitignore += $line")
  G_NEW=$((G_NEW + 1))
}

# The kit's one version marker lives inside the shared ladder, so it travels with every
# install (ADR-0018) — there is no separate VERSION file to copy or clean up.
KIT_VERSION="$(sed -n 's/^Kit version: \([^ ]*\).*/\1/p' "$KIT/.claude/skills/_shared/audit-ladder.md" 2>/dev/null || true)"
echo
echo "attest${KIT_VERSION:+ $KIT_VERSION}  →  $TARGET"
echo

# --- documents ------------------------------------------------------------------------
# COMPLIANCE.md is NOT here: it is opt-in, decided after /business knows the archetype
# (ADR-0030). An empty posture file reads as "declared" to every later audit.
CLAUDE_INSTALLED=0
{ [ -e "$TARGET/CLAUDE.md" ] || [ -L "$TARGET/CLAUDE.md" ]; } || CLAUDE_INSTALLED=1
group_reset
for doc in CLAUDE.md PROGRESS.md BUSINESS.md DECISIONS.md; do
  copy_if_absent "$doc" "document"
  [ "$LAST" = "new" ] && G_NEW=$((G_NEW + 1))
done
DOC_LIST="CLAUDE · PROGRESS · BUSINESS · DECISIONS"
if [ "$WANT_COMPLIANCE" = 1 ]; then
  copy_if_absent "COMPLIANCE.md" "document"
  [ "$LAST" = "new" ] && G_NEW=$((G_NEW + 1))
  DOC_LIST="$DOC_LIST · COMPLIANCE"
fi
say "$(group_icon)" "Documents" "$DOC_LIST — templates, you fill them in"

# --- skills ------------------------------------------------------------------------------
# Enumerate the kit's skills rather than listing them: a hardcoded list means a skill added
# upstream installs nowhere and nobody finds out (the same failure ADR-0018 exists to prevent).
# `compliance` is the one opt-in member — every other directory ships (ADR-0030).
group_reset
CMDS=""
for dir in "$KIT"/.claude/skills/*/; do
  [ -d "$dir" ] || continue
  sk="$(basename "$dir")"
  if [ "$sk" = "compliance" ] && [ "$WANT_COMPLIANCE" = 0 ]; then
    continue
  fi
  copy_tree_if_absent ".claude/skills/$sk"
  # _shared holds the ladder, not a skill — it installs, but it is not a command you can type.
  [ "$sk" = "_shared" ] || CMDS="$CMDS /$sk"
done
say "$(group_icon)" "Commands" "${CMDS# }"

# --- subagents ---------------------------------------------------------------------------
group_reset
copy_tree_if_absent ".claude/agents"
say "$(group_icon)" "Checks" "reviewer · doc-auditor — the read-only subagents /gate runs"

# --- hooks + their wiring ----------------------------------------------------------------
# Warn about unwired hooks only when the kept settings.json really leaves one unwired: an
# older stanza — or yours with the kit's hooks merged in — registers them already, and a
# categorical warning would be false (ADR-0020). So ask the file which hooks it names.
KIT_HOOKS=()
for h in "$KIT"/.claude/hooks/*; do
  [ -f "$h" ] && KIT_HOOKS+=("$(basename "$h")")
done
SETTINGS_STATE="absent"
if [ -e "$TARGET/.claude/settings.json" ] || [ -L "$TARGET/.claude/settings.json" ]; then
  if cmp -s "$KIT/.claude/settings.json" "$TARGET/.claude/settings.json" 2>/dev/null; then
    SETTINGS_STATE="identical"
  else
    SETTINGS_STATE="wired"
    for hook in "${KIT_HOOKS[@]:-}"; do
      grep -qF "$hook" "$TARGET/.claude/settings.json" 2>/dev/null || SETTINGS_STATE="unwired"
    done
  fi
fi
group_reset
copy_tree_if_absent ".claude/hooks"
copy_if_absent ".claude/settings.json" "settings"
# No `drift` arm: copy_if_absent only ever sets it for a "version" file. Whether a KEPT
# settings.json is an action is decided by SETTINGS_STATE below, not by the copy.
case "$LAST" in new) G_NEW=$((G_NEW + 1)) ;; esac
if [ "$SETTINGS_STATE" = "unwired" ]; then
  G_ACT=$((G_ACT + 1))
  note_needs_you ".claude/settings.json" "your settings kept, and they leave one of the kit's hooks unwired — see the stanza below"
fi
say "$(group_icon)" "Guards" "non-goals into every session · a ship gate before anything leaves"

# --- the reference guide: this one always lands -------------------------------------------
# GUIDE.md is the kit's reference manual, not a runtime dependency: the shared audit ladder and
# the ownership contract live in .claude/skills/_shared/audit-ladder.md, which installs with the
# skills that read it (ADR-0010). The "GUIDE PART N" references in the skills are documentation
# pointers — a dangling one costs a reader a lookup, not an audit its severity.
GUIDE_REF="GUIDE.md"   # which file the kit's manual ended up in — the NEXT steps cite it
GUIDE_ICON="·"
if [ ! -e "$TARGET/GUIDE.md" ] && [ ! -L "$TARGET/GUIDE.md" ]; then
  cp "$KIT/GUIDE.md" "$TARGET/GUIDE.md"
  INSTALLED+=("GUIDE.md"); GUIDE_ICON="✓"
  # A leftover attest-GUIDE.md from an earlier dual-install would now shadow nothing —
  # point it out (never delete it ourselves).
  if [ -e "$TARGET/attest-GUIDE.md" ] || [ -L "$TARGET/attest-GUIDE.md" ]; then
    note_needs_you "attest-GUIDE.md" "leftover from an earlier install — GUIDE.md is now the kit's; delete it if you no longer keep your own guide"
  fi
elif cmp -s "$KIT/GUIDE.md" "$TARGET/GUIDE.md"; then
  : # a re-run: the GUIDE.md present is the kit's own prior install
elif head -n1 "$TARGET/GUIDE.md" 2>/dev/null | grep -qF '# GUIDE.md — reference guide'; then
  GUIDE_ICON="⚠"
  note_needs_you "GUIDE.md" "an older kit version — copy $KIT/GUIDE.md over it by hand to refresh"
elif [ ! -e "$TARGET/attest-GUIDE.md" ] && [ ! -L "$TARGET/attest-GUIDE.md" ]; then
  cp "$KIT/GUIDE.md" "$TARGET/attest-GUIDE.md"
  GUIDE_REF="attest-GUIDE.md"; GUIDE_ICON="✓"
  INSTALLED+=("attest-GUIDE.md")
  KEPT+=("GUIDE.md (yours — the kit's manual landed beside it as attest-GUIDE.md, which is what the skills' \"GUIDE PART N\" references mean)")
elif cmp -s "$KIT/GUIDE.md" "$TARGET/attest-GUIDE.md"; then
  GUIDE_REF="attest-GUIDE.md"
else
  # Your own GUIDE.md plus an attest-GUIDE.md that is neither current nor yours: it is the
  # kit's manual from an older install. Same refresh hint the GUIDE.md branch gets — without
  # it this path is the one place a stale manual can never be noticed (ADR-0018).
  GUIDE_REF="attest-GUIDE.md"; GUIDE_ICON="⚠"
  note_needs_you "attest-GUIDE.md" "an older kit version — copy $KIT/GUIDE.md over it by hand to refresh (your own GUIDE.md is untouched; the skills' \"GUIDE PART N\" refs mean attest-GUIDE.md)"
fi
say "$GUIDE_ICON" "Manual" "$GUIDE_REF — the whole loop is PART 9"

# --- .gitignore: append the lines the kit needs, never replace the file --------------------
group_reset
ensure_ignore ".claude/settings.local.json"
# The run records under .attest/ are meant to be committed; only the shared scratch is not —
# the gate's fallback material and the ship guard's decision log both live there (ADR-0034).
ensure_ignore ".attest/tmp/"
if [ "$G_NEW" -gt 0 ] || [ "$G_ACT" -gt 0 ]; then
  say "$(group_icon)" "Ignored" ".claude/settings.local.json · .attest/tmp/"
fi

# --- what deliberately did not land --------------------------------------------------------
if [ "$WANT_COMPLIANCE" = 0 ]; then
  say "·" "Opt-in" "compliance — not installed; /business tells you whether you need it"
fi
say "·" "Not ours" "README.md · LICENSE — they describe attest, not your project"

# --- the report ------------------------------------------------------------------------------
# A re-run that changed nothing says so in one line. Eight rows of "·" is a wall that reads as
# "something happened" and has to be parsed before you learn that nothing did (ADR-0031).
if [ ${#INSTALLED[@]} -eq 0 ] && [ ${#KEPT[@]} -eq 0 ] && [ ${#NEEDS_YOU[@]} -eq 0 ]; then
  echo "  ·  Everything was already in place — this run changed nothing."
else
  for l in "${LINES[@]}"; do echo "$l"; done
fi

if [ ${#KEPT[@]} -gt 0 ]; then
  echo
  echo "  YOURS, UNTOUCHED (${#KEPT[@]}) — the kit ships these too and did not overwrite them:"
  for k in "${KEPT[@]}"; do echo "    · $k"; done
fi

if [ ${#NEEDS_YOU[@]} -gt 0 ]; then
  echo
  echo "  NEEDS YOU (${#NEEDS_YOU[@]}) — nothing was overwritten; these are yours to merge:"
  for s in "${NEEDS_YOU[@]}"; do echo "    · $s"; done
fi

if [ "$SETTINGS_STATE" = "unwired" ]; then
  cat <<'EOF'

  ⚠ The hooks it leaves out are on disk but NOT wired, and will never run. Merge this in:

EOF
  sed 's/^/      /' "$KIT/.claude/settings.json"
elif [ "$SETTINGS_STATE" = "wired" ]; then
  echo
  echo "  · Your .claude/settings.json was kept. It differs from the kit's but registers both"
  echo "    hooks, so they will run."
fi

# --- next ------------------------------------------------------------------------------------
echo
echo "  NEXT"
n=1
printf '  %d  %-24s %s\n' "$n" "Restart Claude Code" "skills only load on a fresh session"
n=$((n + 1))
if [ "$CLAUDE_INSTALLED" = 1 ]; then
  printf '  %d  %-24s %s\n' "$n" "Fill CLAUDE.md" "loaded every turn, ships with <placeholders>; /init is quickest"
  n=$((n + 1))
fi
printf '  %d  %-24s %s\n' "$n" "/business" "purpose, archetype, non-goals — the hooks read these"
n=$((n + 1))
printf '  %d  %-24s %s\n' "$n" "/decision" "the choices you have already made"
n=$((n + 1))
printf '  %d  %-24s %s\n' "$n" "$GUIDE_REF PART 9" "everything else, end to end"
echo
