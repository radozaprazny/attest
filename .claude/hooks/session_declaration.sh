#!/bin/sh
# SessionStart hook: put the project's own boundaries in front of the agent BEFORE it writes
# code, not after (attest ADR-0028). Reads the non-goals out of BUSINESS.md and the live state
# out of PROGRESS.md and prints them; SessionStart stdout is added to the session's context.
#
# A non-goal violation is always a blocker on the shared ladder — but /gate can only find one
# once the code exists. This hook is the prevention half of that rule, and it is a hook rather
# than a skill precisely because a skill can be forgotten and a session start cannot.
#
# POSIX sh, no interpreter beyond /bin/sh and no JSON parsing: SessionStart hands nothing on
# stdin that this needs. Fail-open throughout — an unreadable document prints nothing and the
# session starts exactly as it would have.

set -u

ROOT="${CLAUDE_PROJECT_DIR:-.}"
# Per-section caps, not one cap over the whole block: this text is prepended to EVERY session,
# so it must be cheap — but a single trailing `head` would drop whichever section came last and
# the closing tag with it, silently. Each section is trimmed on its own and says when it was.
NG_MAX=24              # non-goals: the binding half, so it gets the largest share
ST_MAX=8               # current state
NX_MAX=8               # next steps

# Where this project actually keeps the two documents. The defaults are the kit's names; a
# repo that ships those as templates keeps its live ones elsewhere (attest's own are
# docs/attest-*.md — the same distinction /gate scopes with $DOCS). Override per project in
# .claude/settings.json, or export them; a path is relative to the project root.
BUSINESS="${ATTEST_BUSINESS:-BUSINESS.md}"
CARRIER="${ATTEST_THREAD_CARRIER:-PROGRESS.md}"

# ...and what those sections are CALLED. The defaults are the kit's English headings, which is
# a SILENT failure for a project whose documents are written in another language: the hook
# reads the file, matches nothing, prints nothing — and from inside the session that is
# indistinguishable from a hook which was never registered. That is the same ambiguity ADR-0034
# removed for the ship guard, and a heading is the same class of assumption as the paths above,
# so it gets the same knob (attest ADR-0047).
#
# Each value is an awk regex matched against the whole `## …` heading line, so a plain literal
# works ("Stav" finds "## Stav k 7. 9."). The SECTION ITSELF must still be at level 2: the body
# runs until the next `## `, so a level-3 heading is where a section's own subheadings live and
# treating one as a section start would end its parent at the first subsection.
NG_PAT="${ATTEST_NONGOALS_HEADING:-[Nn]on-goals}"
ST_PAT="${ATTEST_STATE_HEADING:-[Cc]urrent state}"
NX_PAT="${ATTEST_NEXT_HEADING:-^##[[:space:]]*[Nn]ext}"

# section <file> <heading-regex> — the body between a matching "## …" heading and the next one.
# Unfilled template bodies are dropped: a placeholder line is <angle-bracketed> or an HTML
# comment, and a section holding nothing else has not been declared yet, so it says nothing.
section() {
  [ -r "$1" ] || return 0
  # The pattern travels in the ENVIRONMENT, not through `awk -v`. `-v` runs its value through
  # escape processing first, so a user escaping a metacharacter the obvious way — `Stav \(WIP\)`
  # — hands awk `Stav (WIP)`, which is a grouping and matches something else entirely; the
  # escape has to be DOUBLED to survive, which nobody guesses. The resulting non-match is
  # silent, and awk's own warning about it goes to the stderr this call discards. ENVIRON[]
  # passes the bytes through untouched, so one backslash means one backslash (attest ADR-0047).
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

# trunc <text> <max> — at most <max> lines, and say so when there were more. Never silent.
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
echo "Loaded from this repo's own control documents at session start. Treat it as binding."
if [ -n "$NONGOALS" ]; then
  echo
  echo "NON-GOALS ($BUSINESS) — building one of these is a blocker, not a judgement call."
  echo "If a request needs one, say so and stop rather than working around it:"
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
