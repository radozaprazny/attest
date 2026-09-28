#!/bin/sh
# attest SessionStart hook: prints BUSINESS.md's non-goals and PROGRESS.md's Current state and
# Next from the project root, so they are in context before the first edit. With no non-goals it
# still prints one line, so a wired hook never looks like a missing one. For documents in another
# language, ATTEST_NONGOALS_HEADING, ATTEST_STATE_HEADING and ATTEST_NEXT_HEADING each take an
# awk regex for the heading.

set -u

ROOT="${CLAUDE_PROJECT_DIR:-.}"
NG_PAT="${ATTEST_NONGOALS_HEADING:-[Nn]on-goals}"
ST_PAT="${ATTEST_STATE_HEADING:-[Cc]urrent state}"
NX_PAT="${ATTEST_NEXT_HEADING:-^##[[:space:]]*[Nn]ext}"

# section <file> <heading-pattern> <cap>: the lines under each `## ` heading the pattern matches,
# blank runs collapsed to one, cut after <cap> NON-EMPTY lines; the notice counts only those too.
# The pattern travels through the environment, so no quoting in it can break the awk program.
# Placeholder lines (<…>, HTML comments outside code fences, however many lines) are dropped: an
# unfilled template declares nothing. A line is cut at 400 bytes (characters under gawk in a UTF-8
# locale), and only a regular file is read (a FIFO hangs).
section() {
  [ -f "$1" ] && [ -r "$1" ] || return 0
  DECL_PAT="$2" awk -v cap="$3" '
    BEGIN { pat = ENVIRON["DECL_PAT"] }
    { sub(/\r$/, "") }
    com { if (/-->/) com = 0; next }
    /^[[:space:]]*(```|~~~)/ { fence = !fence }
    !fence && /^[[:space:]]*<!--/ { if (!/-->/) com = 1; next }
    /^##[^#]/ { inside = ($0 ~ pat) ? 1 : 0; next }
    !inside { next }
    /^[[:space:]]*$/ { gap = 1; next }
    /^[[:space:]]*([-*][[:space:]]*)?<[^>]*>[[:space:]]*$/ { next }
    ++n > cap { next }
    { if (gap && n > 1) print ""; gap = 0; print (length($0) > 400 ? substr($0, 1, 400) " …" : $0) }
    END { if (n > cap) printf "  … (%d more line(s) — read the file itself)\n", n - cap
      if (com) print "  … (an unclosed <!-- hides the rest — read the file itself)" }
  ' "$1"
}

NONGOALS="$(section "$ROOT/BUSINESS.md" "$NG_PAT" 24 2>/dev/null || true)"
STATE="$(section "$ROOT/PROGRESS.md" "$ST_PAT" 8 2>/dev/null || true)"
NEXT="$(section "$ROOT/PROGRESS.md" "$NX_PAT" 8 2>/dev/null || true)"

[ -n "$NONGOALS" ] || echo "attest: no non-goals found in BUSINESS.md — /gate still checks secrets and personal data before a push; /business declares yours."
[ -n "$NONGOALS$STATE$NEXT" ] || exit 0

echo "<project-declaration>"
echo "Read from this repository's own control documents at session start."
if [ -n "$NONGOALS" ]; then
  echo
  echo "NON-GOALS (BUSINESS.md) — what this project declares it does not do."
  echo "A change that builds one contradicts the declaration; this project treats that as a"
  echo "blocker rather than a judgement call, and expects it named rather than worked around:"
  printf '%s\n' "$NONGOALS"
fi
if [ -n "$STATE$NEXT" ]; then
  echo
  echo "WHERE THE WORK STANDS (PROGRESS.md) — /checkpoint keeps it current."
  [ -n "$STATE" ] && printf '%s\n' "$STATE"
  [ -n "$NEXT" ] && { echo "Next:"; printf '%s\n' "$NEXT"; }
fi
echo "</project-declaration>"

exit 0
