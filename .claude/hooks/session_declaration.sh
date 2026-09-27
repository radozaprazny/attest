#!/bin/sh
# attest SessionStart hook: prints the non-goals from BUSINESS.md and where the work stands from
# PROGRESS.md, so both are in context before the first edit, and nothing when neither declares
# anything. Knobs: ATTEST_BUSINESS, ATTEST_THREAD_CARRIER, and ATTEST_NONGOALS_HEADING,
# ATTEST_STATE_HEADING and ATTEST_NEXT_HEADING, each an awk regex for its heading.

set -u

ROOT="${CLAUDE_PROJECT_DIR:-.}"
NG_MAX=24              # non-goals: the binding half, so it gets the largest share
ST_MAX=8               # current state
NX_MAX=8               # next steps

BUSINESS="${ATTEST_BUSINESS:-BUSINESS.md}"
CARRIER="${ATTEST_THREAD_CARRIER:-PROGRESS.md}"

NG_PAT="${ATTEST_NONGOALS_HEADING:-[Nn]on-goals}"
ST_PAT="${ATTEST_STATE_HEADING:-[Cc]urrent state}"
NX_PAT="${ATTEST_NEXT_HEADING:-^##[[:space:]]*[Nn]ext}"

section() {
  [ -r "$1" ] || return 0
  # The pattern travels through the environment, so no quoting in it can break the awk program.
  # Placeholder lines (<…>, HTML comments) are dropped: an unfilled template declares nothing.
  ATTEST_HEADING_PAT="$2" awk '
    BEGIN { pat = ENVIRON["ATTEST_HEADING_PAT"] }
    /^##[^#]/ { inside = ($0 ~ pat) ? 1 : 0; next }
    inside {
      if ($0 ~ /^[[:space:]]*$/)    { pending = 1; next }
      if ($0 ~ /^[[:space:]]*<!--/) { next }
      if ($0 ~ /^[[:space:]]*[-*][[:space:]]*<[^>]*>[[:space:]]*$/) { next }
      if ($0 ~ /^[[:space:]]*<[^>]*>[[:space:]]*$/)                 { next }
      if (pending && n > 0) { out[++n] = "" }
      pending = 0
      out[++n] = $0
    }
    END { for (i = 1; i <= n; i++) print out[i] }
  ' "$1"
}

trunc() {
  printf '%s\n' "$1" | awk -v m="$2" '
    NR <= m { print }
    END { if (NR > m) printf "  … (%d more line(s) — read the file itself)\n", NR - m }
  '
}

NONGOALS="$(section "$ROOT/$BUSINESS" "$NG_PAT" 2>/dev/null || true)"
STATE="$(section "$ROOT/$CARRIER" "$ST_PAT" 2>/dev/null || true)"
NEXT="$(section "$ROOT/$CARRIER" "$NX_PAT" 2>/dev/null || true)"

[ -n "$NONGOALS$STATE$NEXT" ] || exit 0

echo "<project-declaration>"
echo "Read from this repository's own control documents at session start."
if [ -n "$NONGOALS" ]; then
  echo
  echo "NON-GOALS ($BUSINESS) — what this project declares it does not do."
  echo "A change that builds one contradicts the declaration; this project treats that as a"
  echo "blocker rather than a judgement call, and expects it named rather than worked around:"
  trunc "$NONGOALS" "$NG_MAX"
fi
if [ -n "$STATE$NEXT" ]; then
  echo
  echo "WHERE THE WORK STANDS ($CARRIER) — /checkpoint owns this file; keep it current."
  [ -n "$STATE" ] && trunc "$STATE" "$ST_MAX"
  [ -n "$NEXT" ] && { echo "Next:"; trunc "$NEXT" "$NX_MAX"; }
fi
echo "</project-declaration>"

exit 0
