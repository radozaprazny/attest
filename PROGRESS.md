# PROGRESS.md — attest

## Current state
- Epic #28 (cut attest to its core) closed on 2026-10-09: its 16 issues shipped as
  `v0.12.1`…`v1.0.0` (released 2026-09-30) and 15 are closed; the guard work that followed
  shipped as `v1.1.0`…`v1.7.0`. Its closing comment holds the measured numbers; two targets
  were missed, live documents and shell lines with smoke.
- Kit 1.8.0: `install.sh` copies 10 files and 2 lines and writes no document; one `/gate` and
  one read-only `auditor` before a push, 1,296 words; CI smoke 0 failed on ubuntu under dash
  and on macOS. The guard reads 458 lines; GUIDE 2,579 words of a 2,600 budget.

## Next
- #43 stays open for the two list submissions, postponed by the maintainer (awesome-claude-code
  takes only its web form, from a human): their links into PR #63, then close it by hand.
- Guard backlog after `fix/guard-backlog` (nine commits, one PR): #71, #74 and #86 fixed;
  #82 (its time), #81, #76 and #85 (the awks named) narrowed, the rest stated as limits on the
  issues. Left: #79 and #80, each a rewrite of a scan; #72's final state has not run on a real Mac.
- Per PR (the maintainer's auto-memory; the standing grant ended with #28): a time-boxed reviewer
  on hook changes, ship ritual, PR, CI; PRs stacked, merged by the maintainer in one go.
