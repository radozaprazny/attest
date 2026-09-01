# attest — live status (thread-carrier)

> **This is attest's own status — not part of the kit.** `install.sh` never copies `docs/`.
> The `PROGRESS.md` at the repo root is an empty **template** for *your* project; attest's own
> status lives here, because ADR-0006 (and the Phase 7 devlog) record what happens when the two
> are confused. Decisions → `attest-decisions.md` · history → `attest-devlog.md`.

## Current state

The **lean-kit series (phase 11)** is **merged** — PR #4, merge commit `8360fd5`; `main` carries
it. It came from a design pass that asked one question of every component — *would a new adopter
miss this if it were gone?* — and removed the four that answered no. Six ADRs: **0027** no
formatter · **0028** a hook must prevent, not remind · **0029** three bare rungs · **0030**
`/compliance` is opt-in · **0031** the installer reports capabilities · **0032** a late gate
record says so. Shipping it produced two more: **0033** a ship record is written before the push
and committed under a later sha · **0034** the guard leaves a trace, for the pass as well as the
ask (narrowing ADR-0026 — whatever writes into `.attest/tmp/` deletes its own files, not the
directory). Rationale → `attest-decisions.md`; narrative → `attest-devlog.md` Phase 11. Phase 10
is merged (PR #3, `ce439a5`).

**ADR-0035** landed on `feat/visibility-guard`, PR #5 (merge commit `4ed24da`). Merging PR #4
passed the guard in silence, which looked like a missing `gh pr merge` pattern; measuring found
the larger gap was elsewhere. The guard covers the **visibility flip** (`gh repo edit
--visibility`, `gh repo create`) — the one action whose blast radius is the whole history and
which no revert undoes — each `case` arm states what the prompt will claim the command does, and
the absence of `gh pr merge` is a written decision rather than a hole.

**ADR-0036** is committed on `fix/carrier-tense`: this file went false at the merge three times
running, because a carrier lives inside the branch it describes and so can never describe its own
merge. `/checkpoint` now asks for claims the merge leaves standing — branch-scoped and past
tense — since staleness is recoverable and a wrong line is not. This paragraph is written that
way; so is the one above it.

The kit now needs **`git` and `/bin/sh`** — nothing else. Of what a default install puts in your
repo, **0** items edit your code, **0** are language-bound, **0** are inert. **Kit version
0.3.0** (`.claude/skills/_shared/audit-ladder.md`).

Baseline green; shape claims measured 2026-08-31, suite re-run 2026-09-01 — shellcheck is not on `PATH`, use
`uvx`:

```bash
uvx --from shellcheck-py shellcheck install.sh scripts/*.sh .claude/hooks/*.sh   # clean
./scripts/smoke.sh                                    # 118 passed, 0 failed
./install.sh "$EMPTY"                                 # 16 files + 2 .gitignore lines = 18 items
./install.sh --compliance "$EMPTY"                    # 20 items; a re-run reports "changed nothing"
git diff -U0 origin/main -- docs/attest-decisions.md | grep -c '^-[^-]'   # 4 — the sanctioned
                                                      # status flips only (0005, 0015, 0021, 0024)
```

There is no linter step for another language because the kit no longer contains one. Both new
hooks answer correctly when driven by hand: `ship_guard.sh` returns `ask` on `git push` naming
the current HEAD and stays silent on `ls`; `session_declaration.sh` emits the declaration block
once a carrier is set.

Repo is **private** on GitHub (`radozaprazny/attest`), template button on. Going public is
a separate, deliberate step.

## Next

- **Dogfood the declaration hook** — `ATTEST_THREAD_CARRIER=docs/attest-progress.md` is now set in
  `.claude/settings.local.json` (gitignored), so the next session start here is the first live
  run.
- **Enable branch protection** on `main` — now load-bearing, not housekeeping: ADR-0035 names
  branch protection plus required CI as *the* merge boundary, precisely because the ship guard
  deliberately does not cover merges. Until it is on, that boundary does not exist anywhere.
- **Decide on going public** — the guard now asks at the flip itself (ADR-0035). The right
  answer to that prompt is an `/audit-history full` run, not an approval. A README demo GIF
  stays an open nice-to-have; never fabricate a transcript.
- **Still never exercised in anger:** `/checkpoint` alone (it cannot be, on a template —
  ADR-0006).

## Notes / standing constraints

- **attest's own regulatory posture: out of scope.** No personal data, no model, no automated
  decision, no placement on any market — the kit is markdown and shell that runs on the
  author's machine. Recorded here because ADR-0030 makes *"out of scope, because …"* a
  declaration and an absent file not one, and attest has no filled `BUSINESS.md` of its own to
  put it in. The root `COMPLIANCE.md` stays a template for consumers; it is not attest's
  posture. (Found by the kit's own `/compliance audit` on the phase-11 gate: attest was holding
  exactly the state its new rule forbids.)
- **The `SessionStart` hook is silent in attest's own checkout** unless you set
  `ATTEST_THREAD_CARRIER=docs/attest-progress.md` in `.claude/settings.local.json` (which is
  gitignored). The shipped `.claude/settings.json` stays generic on purpose — it is the
  consumer's file, and attest's own paths must never ride out in it. Same ADR-0006 tension
  `/gate` solves with `$DOCS`. Attest has no `docs/attest-business.md`, so only the carrier
  half applies here. It **is** now set locally. `smoke.sh` unsets both overrides at the top for
  that reason: with the carrier exported, the declaration fixtures read this file instead of the
  documents the test wrote, and four assertions failed for a purely ambient reason.
- **A ship record never names the commit that contains it** — `3481531` carries the record for
  `8a7d45a`, and that is now the declared rule, not an accident (ADR-0033). Read `.attest/` by the
  sha *in the name*, never by the commit the file sits in, and never make the two line up.
- **Write a ship record and push in two separate steps** — a `PreToolUse` guard is evaluated
  before the command it guards runs, so one step doing both is judged against a state where the
  record does not exist yet and the guard asks, correctly, while looking wrong. Now also in
  `/audit-history` itself, so it is the kit's rule and not a local habit.
- **The ship guard fires on real Bash tool calls** — proven 2026-08-31 by an isolated `git push`
  that logged a `pass` line with no hook invoked by hand. A push that raises no prompt is the
  guard being auto-approved by the permission mode, not a dead hook; a push leaving **no line**
  in `.attest/tmp/ship-guard.log` would be the real bug. Its designed over-match is visible in
  the same log: a tool call merely *containing* the text `git push` in a payload fires it.
- **`docs/attest-decisions.md` is append-only.** Check every commit: `git diff -U0
  docs/attest-decisions.md | grep -c '^-[^-]'` must be **0**. ADR-0001…0036 stay
  byte-identical once landed — except the one sanctioned mutation, flipping a superseded
  entry's `Status` (ADR-0003). Phase 11 flipped four: 0005, 0015, 0021, 0024.
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
