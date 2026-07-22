# attest — live status (thread-carrier)

> **This is attest's own status — not part of the kit.** `install.sh` never copies `docs/`.
> The `PROGRESS.md` at the repo root is an empty **template** for *your* project; attest's own
> status lives here, because ADR-0006 (and the Phase 7 devlog) record what happens when the two
> are confused. Decisions → `attest-decisions.md` · history → `attest-devlog.md`.

## Current state

The **enforcement series (phase 9)** is **complete** — 5 commits on
`feat/enforcement-series`, awaiting a PR onto `main`.
Trigger: an external analysis (2026-07-22) that confirmed the kit's facts nearly to the
line and named the rhetoric-vs-enforcement gap as the main weakness. The series: `/gate`
run record under `.attest/` (ADR-0016), the `doc-auditor` capability-restricted agent for
the gate's document audits (ADR-0017), `Kit version:` in the shared ladder + install.sh
identical-vs-DIFFERS drift notes (ADR-0018), live CI on attest itself (ADR-0019,
`.github/workflows/ci.yml`), the PART 8 promotion carve-out for the audit family, the
template-cleanup sentinel comment de-overclaimed + README reversibility note, honest
README "gated" wording, and devlog corrections (phase-8 series was 21 commits; smoke is
now 23 assertions). The phase-8 post-audit series itself is merged on `main` (PR #1).

Repo is **private** on GitHub (`radozaprazny/attest`), template button on. Going public is
a separate, deliberate step.

Baseline stays green — neither tool is on `PATH`, use `uvx`:

```bash
uvx ruff@0.15.21 check . && uvx ruff@0.15.21 format --check .
uvx --from shellcheck-py shellcheck install.sh scripts/smoke.sh
./scripts/smoke.sh
```

## Next

- **Merge the enforcement series** — PR `feat/enforcement-series` → `main`, once the new
  `ci` workflow reports green on it.
- **Enable branch protection** on `main` once the `ci` workflow is green — without it the
  CI reports but does not block (noted in ADR-0019).
- **Decide on going public** — before flipping visibility: re-run `/audit-history full`,
  and consider a README demo GIF (open nice-to-have; never fabricate a transcript).
- Dogfood `/gate` on the next real change to attest itself — it now writes its first
  `.attest/` run record.

## Notes / standing constraints

- **`docs/attest-decisions.md` is append-only.** Check every commit: `git diff -U0
  docs/attest-decisions.md | grep -c '^-[^-]'` must be **0**. ADR-0001…0019 stay
  byte-identical once landed.
- **Cutting a release = bump the `Kit version:` line** in
  `.claude/skills/_shared/audit-ladder.md` (ADR-0018 — the ladder is the version's one
  home; there is no VERSION file).
- **`init-tier` grep hits are deliberate** where they survive: the append-only ADR log
  (verbatim history, ADR-0009 narrates the rename) and the devlog's Phase 2 narrative.
  A hit there is correct, not a miss — do not "fix" them.
- `_shared/` relies on verified-but-undocumented behaviour: a dir under `.claude/skills/`
  with no `SKILL.md` is silently ignored by skill discovery. If that changes, move the file
  and update the references.
- **`template-cleanup.yml` must stay inert in attest** — the guards (`is_template` + hard
  repo-name check per ADR-0012, plus the fork check) and the content sentinel are all
  load-bearing; never simplify any of them.
- The repo is a **template**: the root docs are the product; attest's own records live in
  `docs/` and `scripts/` and are deleted downstream by the cleanup workflow.
