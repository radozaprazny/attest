# PROGRESS.md — attest

## Current state
- Epic #28 (cut attest to its core): D1–D6 decided, D3 declined → a lean `/checkpoint` (#36).
- Wave 1 shipped: #44 `v0.12.1`, #29 `v0.13.0`, #30 `v0.14.0`, #33 `v0.15.0`, #32 `v0.16.0`,
  #31 `v0.16.1` (root documents are attest's own; history frozen in `docs/archive/`).
- #34 → kit 0.18.0: one `/gate` and one read-only `auditor` replace the four passes.
- Wave 2 (#35–#38) → kit 0.19.0: `/business` 386 words, `/decision` 298, `/compliance` 1,179
  (template inline, always installed), `/checkpoint` 294; only CLAUDE.md lands as a document;
  the session hook prints one line when no non-goals are declared.
- #39 → kit 0.20.0: `install.sh` (141 lines) copies 10 files and appends 2 lines, writes no
  document or GUIDE, names a missing git, prints a jq merge for a settings.json it will not
  edit, and `--upgrade` replaces or removes only what git holds; `templates/` is gone.
- Smoke 661 passed, 0 failed (664 with jq on PATH, as on CI); the count grows by one per
  committed ship record.

## Next
- Wave 3: #40, #41, #42 → #43 (v1.0.0 and anything published: ask first). #40 and #41
  carry the README and GUIDE lines #34–#39 left stale (listed on those issues).
- Each issue's body is its spec; re-read its comments before starting.
- Per PR (the grant and the ship ritual: the maintainer's auto-memory): reviewer on hook
  changes (time-boxed), ship ritual, PR, CI, hand over the merge, tag after merge.
- The pre-epic backlog under Next in `docs/archive/attest-progress.md` is not in issues yet:
  file what still applies once v1.0.0 is out, and drop the rest.
