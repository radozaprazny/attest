# PROGRESS.md — attest

## Current state
- Epic #28 (cut attest to its core) is done but for its closing: its 16 issues shipped as
  `v0.12.1`…`v1.0.0` (released 2026-09-30) and 15 are closed; the guard work that followed
  shipped as `v1.1.0`…`v1.7.0`. What each changed is in its issue and PR.
- Kit 1.7.0: `install.sh` copies 10 files and 2 lines and writes no document; one `/gate` and
  one read-only `auditor` before a push, 1,296 words; CI smoke 0 failed on ubuntu under dash
  and on macOS.

## Next
- #28 closes on the maintainer's consent, after `epic28-measure.sh` on `main` with this change
  in: its numbers and its misses in a comment there.
- #43 stays open for the two list submissions, postponed by the maintainer (awesome-claude-code
  takes only its web form, from a human): their links into PR #63, then close it by hand.
- Backlog outside the epic, in issues: #71, #74, #76, #79, #80, #81, #82, #86, and #85 (a long
  command on macOS; #72's final state has not run on a real Mac).
- Per PR (the maintainer's auto-memory; the standing grant ends with #28): a time-boxed reviewer
  on hook changes, ship ritual, PR, CI; PRs stacked, merged by the maintainer in one go.
