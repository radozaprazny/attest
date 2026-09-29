# PROGRESS.md — attest

## Current state
- Epic #28 (cut attest to its core): D1–D6 decided, D3 declined → a lean `/checkpoint` (#36).
- Wave 1 shipped: #44 `v0.12.1`, #29 `v0.13.0`, #30 `v0.14.0`, #33 `v0.15.0`, #32 `v0.16.0`.
- #31 → kit 0.16.1: the root documents are attest's own; adopter templates sit in `templates/`
  until #39; the ADR log (ADR-0001…0078), the progress log and the devlog are frozen in
  `docs/archive/`.
- Smoke 626 passed, 0 failed; the count grows by one per committed ship record.
- How to work (the standing grant, the ship ritual): the maintainer's auto-memory.

## Next
- Wave 2: #34 (a) then (b) → #35, #36, #37, #38. Wave 3: #39 → #40, #41, #42 → #43
  (v1.0.0 and anything published: ask first).
- Each issue's body is its spec; re-read its comments before starting.
- Per PR: reviewer on hook changes (time-boxed), ship ritual, PR, CI, hand over the merge,
  tag after merge.
- The pre-epic backlog under Next in `docs/archive/attest-progress.md` is not in issues yet:
  file what still applies once v1.0.0 is out, and drop the rest.
