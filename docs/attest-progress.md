# attest — live status (thread-carrier)

> **This is attest's own status — not part of the kit.** `install.sh` never copies `docs/`.
> The `PROGRESS.md` at the repo root is an empty **template** for *your* project; attest's own
> status lives here, because ADR-0006 (and the Phase 7 devlog) record what happens when the two
> are confused. Decisions → `attest-decisions.md` · history → `attest-devlog.md`.

## Current state

The **enforcement series (phase 9)** is **merged** — PR #2, merge commit `a53ef0f`
(2026-07-22). `main` carries it; the feature branch is gone.

In progress: the **audit fix series (phase 10)**, uncommitted in the working tree. It comes
from a full multi-agent audit of the repo (2026-08-10) that returned two majors and ~22 minors
after adversarial verification. What it changes, by ADR:

- **ADR-0020** — `install.sh` judges a present kit file by content, not by a predicate its own
  presence satisfies. Fixes the `ruff.toml` re-run misreport (and its exemption from the
  ADR-0018 drift ladder) and the false *"hooks NOT wired"* warning for an older kit
  `settings.json`. `has_ruff_config` lost its `\1` backreference (undefined in POSIX ERE; it
  also matched `[tool.ruffle]`).
- **ADR-0021** — `ci.yml.example` now reaches consumers: `install.sh` copies it and the
  cleanup leaves it. Attest's own `ci.yml` still stays behind.
- **ADR-0022** — the template cleanup removes attest's files **by name** from
  `scripts/template-cleanup.sh`, each rewrite guarded by a content check on its own target.
  A late run can no longer take your `docs/`, `scripts/` or `LICENSE` with it, and the only
  destructive code in the repo is now shellcheck'd and smoke-tested.
- **ADR-0023** — the ownership contract resolves the `/decision` ↔ `/compliance` edge, and a
  reviewer `nit` has a defined path through the `/gate` merge and its run record.
- **ADR-0024** — the format hook acts only inside `CLAUDE_PROJECT_DIR` and runs ruff with
  `--no-cache`.

Also in the series, without an ADR: `/gate` hands the document audits dated logs plus the
`.attest/` record names (so *"since the last audit"* is answerable without git) and tells the
caller to write them in **one** Bash invocation; `/compliance audit`'s cheap trigger check is
defined and its no-hit return string fixed; `install.sh` reports what landed when it aborts
mid-run, refuses install into an ancestor/descendant of the kit, points NEXT at
`attest-GUIDE.md` when that is where the manual went, and gives a stale `attest-GUIDE.md` the
same refresh hint `GUIDE.md` gets; both workflows pin actions by SHA and `ci.yml` drops to
`permissions: contents: read`; the shipped `DECISIONS.md` header is no longer a fused
sentence. Not visible in the diff (git does not track empty directories): the leftover empty
`init-tier/` directory from the ADR-0009 rename was deleted from the working tree.

The series went through the `reviewer` subagent before commit, which returned three majors —
`template-cleanup.sh` deleted `ci.yml` and `scripts/smoke.sh` with no content guard although
both are names the kit itself invites; `template-cleanup.yml`, the one workflow holding a
write token, was still on a mutable action tag; and `decision/SKILL.md` still asserted the
ownership the new ladder edge had just reversed. All three are fixed above; the first is covered by two new
assertions, and the other two are one-line changes no harness can test. A second reviewer
pass then caught the one fix in the batch that had no assertion behind it — a `"${VAR%/}"/*`
case pattern whose quoted null made the `TARGET=/` guard silently never fire. Fixed, and now
asserted by refusal message rather than by exit code. A third pass confirmed closure by
**mutation** (guards stripped → all four assertions fail) rather than by inspection, and the
last uncovered fix — the cleanup's prune-list parity with `has_python_markers` — gained a
fixture with vendored `.py` files under `node_modules/` and `.venv/` on both adoption paths.

`/gate` then ran for the first time in this repo's history (2026-08-19, record
`.attest/gate-20260819-080558-a53ef0f.md`): ⚠️ *commit after changes* — 0 blocker, 1 major,
8 minor, 5 nit, with the business pass degraded (attest has no `BUSINESS.md` of its own) and
compliance out of scope. Its major was a regression the two `reviewer` rounds had missed and
that ADR-0022 itself introduced: `template-cleanup.yml` invoked `scripts/template-cleanup.sh`
with no existence guard, so a repo whose owner deleted `scripts/` by hand before the first run
would exit 127, skip the commit step, and keep a failing workflow that can never delete
itself. Guarded now. The rest of its findings produced ADR-0025 (SHA pinning), ADR-0026
(`.attest/tmp/` carve-out plus its ignore line), cross-references from ADR-0023 → 0004/0005
and ADR-0024 → 0015, a one-invocation clean-tree branch in the gate's scoping command, and
`$DOCS` scoping so a template repo logs its real decision log instead of the shipped skeleton.

**Kit version is now 0.2.0** (`.claude/skills/_shared/audit-ladder.md`).

Repo is **private** on GitHub (`radozaprazny/attest`), template button on. Going public is
a separate, deliberate step.

Baseline stays green — neither tool is on `PATH`, use `uvx`:

```bash
uvx ruff@0.15.21 check . && uvx ruff@0.15.21 format --check .
uvx --from shellcheck-py shellcheck install.sh scripts/*.sh
./scripts/smoke.sh          # 61 assertions
```

## Next

- **Commit the fix series** — the gate has run; stage
  `.attest/gate-20260819-080558-a53ef0f.md` **with** the commit it gates, then commit per ADR
  as one series and open the PR. Re-run `/gate` afterwards only if the tree changes again.
- **Enable branch protection** on `main` once the `ci` workflow is green — without it the
  CI reports but does not block (noted in ADR-0019).
- **Decide on going public** — before flipping visibility: re-run `/audit-history full`,
  and consider a README demo GIF (open nice-to-have; never fabricate a transcript).
- **Still never exercised in anger:** `/checkpoint` alone (it cannot be, on a template —
  ADR-0006). `/gate` and `doc-auditor` are no longer on that list.

## Notes / standing constraints

- **`docs/attest-decisions.md` is append-only.** Check every commit: `git diff -U0
  docs/attest-decisions.md | grep -c '^-[^-]'` must be **0**. ADR-0001…0026 stay
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
- **The template cleanup must stay inert in attest** — the job guards (`is_template` + the
  hard repo-name check per ADR-0012, the fork check, the payload null check) and the
  content guards inside `scripts/template-cleanup.sh` are all load-bearing; never simplify
  any of them. The script is exercised by `smoke.sh`; keep it that way.
- The repo is a **template**: the root docs are the product; attest's own records live in
  `docs/` and `scripts/` and are deleted downstream by the cleanup workflow.
