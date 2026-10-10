#!/usr/bin/env bash
# install.sh — copy the attest kit into a project: 10 files, each only if absent, and 2 lines
# appended to .gitignore and .gitattributes. It writes no document; each skill writes its own.
#
#   ./install.sh [--upgrade] <path-to-your-project>
#
# --upgrade replaces the kit's own files where git holds your copy, naming each one first, and
# removes the paths an older kit left under the same condition. It never touches a document or
# .claude/settings.json.
set -Eeuo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
FILES=".claude/settings.json .claude/hooks/session_declaration.sh .claude/hooks/ship_guard.sh
  .claude/hooks/record_guard.sh .claude/agents/auditor.md .claude/skills/gate/SKILL.md
  .claude/skills/business/SKILL.md .claude/skills/decision/SKILL.md
  .claude/skills/compliance/SKILL.md .claude/skills/checkpoint/SKILL.md"
RETIRED=".claude/agents/reviewer.md .claude/agents/doc-auditor.md .claude/skills/_shared
  .claude/skills/audit-history .claude/skills/gate/triggers.sh"
TARGET=""; UPGRADE=0

usage() { echo "usage: ./install.sh [--upgrade] <path-to-your-project>"; exit "${1:-2}"; }
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --upgrade) UPGRADE=1 ;;
    -*) echo "install.sh: unknown option: $1" >&2; usage >&2 ;;
    *) [ -z "$TARGET" ] || { echo "install.sh: more than one target given" >&2; usage >&2; }
       TARGET="$1" ;;
  esac
  shift
done
[ -n "$TARGET" ] || usage >&2
[ -d "$TARGET" ] || { echo "install.sh: no such directory: $TARGET" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd -P)"
# Ancestry both ways, with trailing slashes so the prefix test is exact. The prefixes are
# variables because a quoted "${X%/}" inside the pattern would match TARGET=/ never.
KP="${KIT%/}/"; TP="${TARGET%/}/"
case "$TP" in "$KP"*) echo "install.sh: refusing to install the kit into itself (or into a directory inside it)" >&2; exit 2 ;; esac
case "$KP" in "$TP"*) echo "install.sh: refusing to install the kit into a directory that contains it" >&2; exit 2 ;; esac
cd "$TARGET"

LANDED=(); DONE=(); NEEDS=(); DIFFER=()
trap 'echo "install.sh: ABORTED — a PARTIAL install; landed first: ${LANDED[*]:-nothing}. Fix the cause and re-run: it resumes." >&2' ERR
need() { NEEDS+=("$1"); }
present() { [ -e "$1" ] || [ -L "$1" ]; }
# The kit's copy with CR removed: a CRLF hook exits 2 under dash, which blocks every Bash call.
kit() { tr -d '\r' < "$KIT/$1"; }
same() { kit "$1" | cmp -s - "$1" 2>/dev/null; }
# cp first, so the mode is the kit's; then the LF content; mv, so a symlink is replaced, not followed.
put() { mkdir -p "$(dirname "$1")"; cp "$KIT/$1" "$1.attest$$"; kit "$1" > "$1.attest$$"; mv -f "$1.attest$$" "$1"; }
tracked_clean() { [ "$GIT" = 1 ] && git ls-files --error-unmatch -- "$1" >/dev/null 2>&1 &&
  git diff --quiet HEAD -- "$1" 2>/dev/null && [ -z "$(git ls-files --others -- "$1")" ]; }

GIT=1
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then GIT=0
  need "git — no repository here: /gate and the ship guard judge a commit, so git init and commit once"
elif ! git rev-parse -q --verify HEAD >/dev/null 2>&1; then GIT=0
  need "git — no commit yet: /gate and the ship guard judge a commit, so commit once"
fi

T=0; for f in $FILES; do T=$((T + 1))
  if ! present "$f"; then put "$f"; LANDED+=("$f")
  elif [ "$f" != .claude/settings.json ] && ! same "$f"; then DIFFER+=("$f"); fi
done
OLD=(); for p in $RETIRED; do present "$p" && OLD+=("$p"); done

V="$(sed -n 's/^Kit version: \([^ ]*\).*/\1/p' "$KIT/.claude/skills/gate/SKILL.md" 2>/dev/null || true)"
banner() { [ -n "${B:-}" ] || { echo; echo "attest${V:+ $V}  →  $TARGET"; echo; B=1; }; }
if [ "$UPGRADE" = 1 ]; then
  for f in ${DIFFER[@]+"${DIFFER[@]}"}; do
    if tracked_clean "$f"; then
      banner; echo "  ✓ replaced $f — it differed from the kit's; yours is in HEAD: git diff HEAD -- $f"
      put "$f"; DONE+=("$f")
    else need "$f — kept: it differs from the kit's and git does not hold it; commit it, then re-run --upgrade"; fi
  done
  for p in ${OLD[@]+"${OLD[@]}"}; do
    if tracked_clean "$p"; then banner; rm -rf -- "$p"; DONE+=("$p")
      echo "  ✓ removed $p — retired; git checkout HEAD -- $p restores it"
    else need "$p — retired, kept: it has uncommitted changes or git does not track it"; fi
  done
  for g in GUIDE.md attest-GUIDE.md; do
    if head -n1 "$g" 2>/dev/null | grep -qF '# GUIDE.md — reference guide'; then
      need "$g — an older kit's manual; the kit no longer installs one, so delete it unless you keep it"
    fi
  done
  grep -qxF '.claude/skills/*/*.sh text eol=lf' .gitattributes 2>/dev/null &&
    need ".gitattributes — delete the line .claude/skills/*/*.sh text eol=lf: an older kit wrote it, and it rewrites your own scripts"
  grep -qF "\"\$CLAUDE_PROJECT_DIR/" .claude/settings.json 2>/dev/null &&
    need ".claude/settings.json — write \${CLAUDE_PROJECT_DIR:-.} for \$CLAUDE_PROJECT_DIR in its hook commands: unset, each hook exits 2 under dash"
elif [ $((${#DIFFER[@]} + ${#OLD[@]})) -gt 0 ]; then
  need "${#DIFFER[@]} kit file(s) differ from this kit, ${#OLD[@]} retired path(s) remain — $KIT/install.sh --upgrade $TARGET names each, and replaces only what git holds"
fi

# append <file> <line> — never over a symlink, never glued onto an unterminated last line.
# .gitattributes is matched on its pattern, so a rule of yours for the same glob wins.
append() {
  if [ -L "$1" ]; then need "$1 — a symlink; append the line $2 yourself"; return 0; fi
  if [ "$1" = .gitattributes ]; then
    awk -v p="${2%% *}" '$1 == p { f = 1 } END { exit !f }' "$1" 2>/dev/null && return 0
  else grep -qxF "$2" "$1" 2>/dev/null && return 0; fi
  if [ -s "$1" ] && [ -n "$(tail -c1 "$1")" ]; then echo >> "$1"; fi
  printf '%s\n' "$2" >> "$1"; LANDED+=("$1 += $2")
}
append .gitignore ".attest/tmp/"
append .gitattributes ".claude/hooks/* text eol=lf"

# A settings.json of yours is never edited. It is judged by what it wires: every hook file, the
# ship guard's MCP matcher, and PowerShell in a shell matcher (Windows routes shell there).
S=.claude/settings.json
if ! same "$S"; then
  for w in session_declaration.sh ship_guard.sh record_guard.sh mcp__github__ '"matcher"[[:space:]]*:[[:space:]]*"[^"]*PowerShell'; do
    grep -qE "$w" "$S" 2>/dev/null || { UNWIRED=1; break; }
  done
fi
if [ -n "${UNWIRED:-}" ]; then
  need "$S — yours, kept, and it does not wire every kit hook, so the unwired ones never run"
  if command -v jq >/dev/null 2>&1; then
    # shellcheck disable=SC2016  # a jq program: $k, $e, $a and $x are jq's, not the shell's
    j='.hooks //= {} | reduce ($k[0].hooks | to_entries[]) as $e (.; .hooks[$e.key] = ((.hooks[$e.key] // []) as $a | $a + [$e.value[] | select(. as $x | $a | all(. != $x))]))'
    need "  to append the kit's hook entries and change no other key, run from $TARGET:
      jq --slurpfile k $(printf '%q' "$KIT/$S") '$j' $S > $S.new && mv $S.new $S"
  else need "  no jq here: ask Claude to merge the hooks of $KIT/$S into it, changing no other key"; fi
  need "  then re-run this installer: wired when it no longer names $S; in claude, /hooks lists each hook with its source"
fi

if [ ${#LANDED[@]} -eq 0 ] && [ ${#DONE[@]} -eq 0 ] && [ ${#NEEDS[@]} -eq 0 ]; then
  echo "attest${V:+ $V} is already in $TARGET — this run changed nothing."; exit 0
fi
banner; C=(); for l in ${LANDED[@]+"${LANDED[@]}"}; do case "$l" in .claude/*) C+=("$l") ;; esac; done
# The summary line only for a whole install; a partial one names each file that landed.
if [ ${#C[@]} -eq "$T" ]; then echo "  ✓ $T kit file(s) landed under .claude/ — settings, 3 hooks, the auditor, /gate /business /decision /compliance /checkpoint"
else for l in ${C[@]+"${C[@]}"}; do echo "  ✓ landed $l"; done; fi
for l in ${LANDED[@]+"${LANDED[@]}"}; do case "$l" in .claude/*) ;; *) echo "  ✓ $l" ;; esac; done
if [ ${#NEEDS[@]} -gt 0 ]; then
  echo; echo "  NEEDS YOU"
  for l in "${NEEDS[@]}"; do case "$l" in " "*) echo "  $l" ;; *) echo "    · $l" ;; esac; done
fi
echo
echo "  NEXT"
if [ -n "${UNWIRED:-}" ]; then echo "  1  claude        start it once settings.json wires the hooks (NEEDS YOU, above): until then the unwired hooks do not run"
else echo "  1  claude        start it, or restart a session that was open: skills load at start"; fi
echo "  2  /business     writes BUSINESS.md; its non-goals reach every session and /gate"
echo "  3  /gate         before a push: audits what it sends, commits the record the guard reads"
echo "  4  /checkpoint   before /clear: writes PROGRESS.md for the next session"
echo
