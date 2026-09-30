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

## Next
- #43: the two list submissions, by the maintainer (awesome-claude-code takes only its web
  form, from a human); their links into PR #63, then close #43 by hand.
- #59: ship commands the list does not name (pnpm, docker compose, glab, gcloud, …).
- #62: bash as `/bin/sh` reports the killed watchdog on stderr.
- Per PR (the grant and the ship ritual: the maintainer's auto-memory): reviewer on hook
  changes (time-boxed), ship ritual, PR, CI, hand over the merge, tag after merge.
- Pre-epic backlog triaged on #43: #58 filed and fixed, two smoke items folded into #42.
