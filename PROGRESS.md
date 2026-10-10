# PROGRESS.md — attest

## Current state
- Epic #28 (cut attest to its core) closed on 2026-10-09: its 16 issues shipped as
  `v0.12.1`…`v1.0.0` (released 2026-09-30) and 15 are closed; the guard work that followed
  shipped as `v1.1.0`…`v1.7.0`. Its closing comment holds the measured numbers; two targets
  were missed, live documents and shell lines with smoke.
- Kit 1.9.0: `install.sh` copies 10 files and 2 lines, writes no document and says how to know
  the hooks are wired; one `/gate` and one read-only `auditor` before a push, 1,296 words; CI
  smoke 0 failed on ubuntu under dash and on macOS. The guard reads 458 lines (capped, DECISIONS
  2026-10-10); README leads with the declaration; `.attest/` holds ship records only.

## Next
- Promo plan of 2026-10-10 (`local/first-push-protocol.md`): measure install → first guarded
  push on kit 1.9.0, n ≥ 3 (the dev portal via `--upgrade`, two public repositories with their
  own settings.json), then README's cost table, then #43's two list submissions (awesome-claude-code
  takes only its web form, from a human) and one community post.
- Guard backlog: #71, #74, #86 fixed; #82, #81, #76, #85 narrowed; #79, #80 are limits
  (DECISIONS 2026-10-10). #72's final state has not run on a real Mac.
- Per PR (the maintainer's auto-memory; the standing grant ended with #28): a time-boxed reviewer
  on hook changes, ship ritual, PR, CI; PRs stacked, merged by the maintainer in one go.
