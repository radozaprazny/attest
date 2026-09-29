# PROGRESS.md — attest

## Current state
- Epic #28 (cut attest to its core): D1–D6 decided, D3 declined → a lean `/checkpoint` (#36).
- Wave 1 shipped: #44 `v0.12.1`, #29 `v0.13.0`, #30 `v0.14.0`, #33 `v0.15.0`, #32 `v0.16.0`,
  #31 `v0.16.1` (root documents are attest's own; history frozen in `docs/archive/`).
- #34 → kit 0.18.0: one `/gate` (798 words) and one read-only `auditor` (498) replace the four
  passes; `scripts/fixture.sh` plants 4 faults, all found. The reviewer, doc-auditor, ladder,
  triggers.sh, audit-history and the audit modes are gone; README and GUIDE follow in #40, #41.
- Smoke 606 passed, 0 failed; the count grows by one per committed ship record.
- How to work (the standing grant, the ship ritual): the maintainer's auto-memory.

## Next
- #35, #36, #37, #38 in one PR, a commit each. Wave 3: #39 → #40, #41, #42 → #43 (v1.0.0
  and anything published: ask first).
- Each issue's body is its spec; re-read its comments before starting.
- Per PR: reviewer on hook changes (time-boxed), ship ritual, PR, CI, hand over the merge,
  tag after merge.
- The pre-epic backlog under Next in `docs/archive/attest-progress.md` is not in issues yet:
  file what still applies once v1.0.0 is out, and drop the rest.
