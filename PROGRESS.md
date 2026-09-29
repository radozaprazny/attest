# PROGRESS.md — attest

## Current state
- Epic #28 (cut attest to its core): D1–D6 decided, D3 declined → a lean `/checkpoint` (#36).
- Waves 1–2 and #39 shipped as `v0.12.1`…`v0.20.0`: one `/gate`, one read-only `auditor`,
  lean skills, `install.sh` copies 10 files and 2 lines and writes no document.
- #40 → `v0.21.0`: README 676 words of prose, a real prompt and record, measured cost; METHOD
  1,455 words for one gate.
- #41 → kit 0.22.0: GUIDE 2,294 words, repo-only, no ADR citations, an 8-row permission-mode
  table; the NO RECORD prompt says "ship record".
- Smoke 673 passed, 0 failed; the count grows by one per committed ship record.

## Next
- #42 (table-driven smoke, budgets incl. README and GUIDE, dash + macOS CI, pinned shellcheck)
  → #43 (v1.0.0 and anything published: ask first).
- #56: a backslash, `$'…'` or a process substitution hides a push from the ship guard.
- Per PR (the grant and the ship ritual: the maintainer's auto-memory): reviewer on hook
  changes (time-boxed), ship ritual, PR, CI, hand over the merge, tag after merge.
- Pre-epic backlog (`docs/archive/attest-progress.md`, Next): the triage waits on the
  maintainer; file what applies once v1.0.0 is out.
