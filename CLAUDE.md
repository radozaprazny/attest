# CLAUDE.md — attest

Rules for working on attest itself. Status → PROGRESS.md · boundaries → BUSINESS.md · binding
choices → DECISIONS.md · backlog → GitHub issues · history → `docs/archive/`.

## Shell
- Hooks are POSIX `sh`; `install.sh` and `scripts/*.sh` are bash.
- Lint as CI does: `uvx --from shellcheck-py shellcheck install.sh scripts/*.sh .claude/hooks/*.sh`

## Verify
- `./scripts/smoke.sh` must end `0 failed`; a hook change comes with its smoke case.

## Commits
- Conventional Commits (`feat:`, `fix:`, `docs:`, `test:`, `chore:`, `refactor:`), imperative,
  ≤72 characters, one logical unit each.

## The one rule
A DECISIONS entry only for a change to METHOD, the record format or a hook contract; backlog in
GitHub issues, current state in a short PROGRESS.md; no devlog.
