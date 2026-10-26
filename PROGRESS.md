# PROGRESS.md — attest

## Current state
- Epic #28 (cut attest to its core) closed on 2026-10-09: its 16 issues shipped as
  `v0.12.1`…`v1.0.0` (released 2026-09-30) and 15 are closed; the guard work that followed
  shipped as `v1.1.0`…`v1.7.0`. Its closing comment holds the measured numbers; two targets
  were missed, live documents and shell lines with smoke.
- Kit 1.9.2: `install.sh` copies 10 files and 2 lines, writes no document and says how to know
  the hooks are wired; one `/gate` (one prompt, the record write) and one read-only `auditor`
  before a push, 1,297 words; CI smoke 0 failed on ubuntu under dash and on macOS. The guard
  reads 458 lines (capped, DECISIONS 2026-10-10); `.attest/` holds ship records only.

## Next
- Promo plan of 2026-10-10: install → first guarded push measured on kit 1.9.0, n = 3, now
  README's cost table (raw notes and an archive of the runs in `local/`). Both false asks it
  found are gone: `/gate`'s first command in 1.9.1, a push after `git remote -v` in 1.9.2 (#95).
  Next #43's two list submissions (awesome-claude-code takes only its web form, from a human)
  and one post.
- Guard backlog: #71, #74, #81, #86 fixed; #76, #82, #85 closed as shipped in part, their rest
  limits (DECISIONS 2026-10-10); #79, #80 are limits. Open: #98, a push split by a line
  continuation passes on HEAD's record (pre-existing, from #95's review). Needs a Mac: #72's
  final state and #85's profile on macOS's awk, asked of the community in #97.
- Per PR (the maintainer's auto-memory; the standing grant ended with #28): a time-boxed reviewer
  on hook changes, ship ritual, PR, CI; PRs stacked, merged by the maintainer in one go.
