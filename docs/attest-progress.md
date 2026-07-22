# attest — live status (thread-carrier)

> **This is attest's own status — not part of the kit.** `install.sh` never copies `docs/`.
> The `PROGRESS.md` at the repo root is an empty **template** for *your* project; attest's own
> status lives here, because ADR-0006 (and the Phase 7 devlog) record what happens when the two
> are confused. Decisions → `attest-decisions.md` · history → `attest-devlog.md`.

## Current state

The post-audit fix series is **complete** — 20 commits on `fix/post-audit-series` (17
planned + 3 closing the adversarial series review's 23 confirmed findings), landing on
`main` via PR; once merged, `origin/main` carries the full series. It closed everything a
66-agent adversarial audit confirmed (2026-07-22) plus
the previously planned fixes: install.sh honesty (gitignore-newline corruption, idempotent
re-runs, junk filter, inert-hooks warning, python3 preflight, dynamic NEXT), the `/business`
half-filled dispatch gap, `/decision`'s missing template predicate and the `DECISIONS.md`
example trap, **`/gate`** (ADR-0011), template-cleanup CI (ADR-0012), the README payoff +
adoption gradient (ADR-0013), the **local-app** archetype (ADR-0014), Python-tooling-only-
into-Python-projects (ADR-0015), a smoke test, and GUIDE PART 8 realigned with ADR-0010.

Repo is **private** on GitHub (`radozaprazny/attest`), template button on. Going public is
a separate, deliberate step.

Baseline stays green — neither tool is on `PATH`, use `uvx`:

```bash
uvx ruff@0.15.21 check . && uvx ruff@0.15.21 format --check .
uvx --from shellcheck-py shellcheck install.sh scripts/smoke.sh
./scripts/smoke.sh
```

## Next

- **Decide on going public** — before flipping visibility: re-run `/audit-history full`,
  and consider a README demo GIF (open nice-to-have; never fabricate a transcript).
- Dogfood `/gate` on the next real change to attest itself.

## Notes / standing constraints

- **`docs/attest-decisions.md` is append-only.** Check every commit: `git diff -U0
  docs/attest-decisions.md | grep -c '^-[^-]'` must be **0**. ADR-0001…0015 stay
  byte-identical once landed.
- **`init-tier` grep hits are deliberate** where they survive: the append-only ADR log
  (verbatim history, ADR-0009 narrates the rename) and the devlog's Phase 2 narrative.
  A hit there is correct, not a miss — do not "fix" them.
- `_shared/` relies on verified-but-undocumented behaviour: a dir under `.claude/skills/`
  with no `SKILL.md` is silently ignored by skill discovery. If that changes, move the file
  and update the references.
- **`template-cleanup.yml` must stay inert in attest** — the double guard (`is_template` +
  hard repo-name check) is load-bearing; never simplify it (ADR-0012).
- The repo is a **template**: the root docs are the product; attest's own records live in
  `docs/` and `scripts/` and are deleted downstream by the cleanup workflow.
