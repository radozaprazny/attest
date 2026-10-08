# PROGRESS.md — attest

## Current state
- Epic #28 (cut attest to its core): D1–D6 decided, D3 declined → a lean `/checkpoint` (#36).
- Waves 1–2 and #39 shipped as `v0.12.1`…`v0.20.0`: one `/gate`, one read-only `auditor`,
  lean skills, `install.sh` copies 10 files and 2 lines and writes no document.
- Wave 3: #40 `v0.21.0` (README 676 prose words, METHOD 1,455), #41 `v0.22.0` (GUIDE 2,294,
  8-row permission-mode table), #56 + #58 kit 0.23.0 (a hidden ship command asks).
- #42 `v0.24.0`: one budget table, nine parallel smoke groups, hooks under dash asserted on
  ubuntu CI, macOS in CI, shellcheck pinned. Smoke 0 failed on both; its count grows by one
  per committed ship record.
- #43 `v1.0.0`, released 2026-09-30: Release notes 300 words with an 8-step migration note
  (run end to end from a scratch v0.12.0 install, PR #63), About text 100 characters, topics
  `secret-scanning`, `git-hooks`, `audit-trail`; the 2026-09-15 plan in `docs/archive/`.
- #62 `v1.1.0`: the leak scan and its watchdog stop by KILL and are reaped, so bash 3.2
  prints no `Terminated` line, and a parent that ignores TERM neither waits nor clears a slow
  scan.
- #59 + #65 → kit 1.2.0: the ship list reads pnpm, npm's prefixes of publish, compose, podman,
  skopeo, glab, gcloud, az, rclone, sftp, kaggle uploads and writing web calls (`gh api`,
  `curl`, `-InFile`); every part a first reading missed is read again.
- #69 `v1.3.0`: a guard call starts 31 processes, not 50, with no decision changed; ubuntu CI
  smoke 8.4 s on PR #70 and 9.0 s on main, back under its 10 s budget (10.7 s on PR #67).
- #68 → kit 1.4.0: a ship tool's name is read in any case, as a case-blind file system runs
  it: `NPM publish` asks as `npm publish` does; `GIT push` asks even on a clean record.
- #75 → kit 1.5.0: a record written through `.ATTEST/` or by `TEE` asks, in either guard.
- #73 → kit 1.6.0: a docker build that pushes asks (`--push`, a registry output, `push=`,
  `--cache-to` a registry); it is read after the second reading, so a hidden push still asks.

- #72 → kit 1.7.0: a long command the second reading reads whole costs in proportion to its
  length: the reading builds its strings in runs, and its mark is read by `case`, not by a prefix
  strip. A 66 KB heredoc, CPU seconds from `main` to now, with gawk: 4.0 → 0.4 under bash 3.2,
  macOS's `sh`; 0.73 → 0.18 under dash; with BWK awk 20231127 under dash 40 → 0.8. A real Mac
  needed 3.2 s on `main`; this state has not run on one.

## Next
- #28 closes once PR #84 (#72) is merged: `epic28-measure.sh` on main, its checklist, DECISIONS
  12 → 10 in a docs PR, and the maintainer's consent.
- Backlog outside the epic (the maintainer, 2026-10-04): #74 three PowerShell web calls, #76
  ship-list gaps, #71 a NUL in a record's findings line, #79 record writers the scan does not
  list, #80 hidden pushes the part loop misses, #81 docker sends #73 left out, #82 ship patterns
  that span the whole command (prose asks since #68, three words take cubic time).
- #43: the two list submissions, postponed by the maintainer (awesome-claude-code takes only
  its web form, from a human); their links into PR #63, then close #43 by hand.
- Per PR (the grant and the ship ritual: the maintainer's auto-memory): reviewer on hook
  changes (time-boxed), ship ritual, PR, CI; PRs stacked, merged by the maintainer in one go.
- Pre-epic backlog triaged on #43: #58 filed and fixed, two smoke items folded into #42.
