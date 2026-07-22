# attest — development log

> **This is attest's own build history — not part of the kit.** `install.sh` never copies it.
> If you generated your repo from the **template button** (which copies the whole tree),
> **delete `docs/` and `install.sh`** — see README "First 5 minutes".
>
> The `PROGRESS.md` at the repo root is an empty template for *your* project; this file is
> where attest's own record lives, so the kit never ships its author's status as yours. Kept
> because the reasoning is the interesting part — in particular Phase 7, where the kit found
> out it had never actually been installable. Decisions → `docs/attest-decisions.md`.

## What this is

attest started as a fork of a predecessor dev-kit and became a **compliance-native** one: a
spine of five living documents, each owned by a skill that both writes it and audits reality
against it. This log records how it got there and, more usefully, what was wrong.

## The phases

- **1 / 1.5 — make the docs true.** Every doc reference resolves to a real file; the kit
  passes its own ruff config; a `/agents` doc-lie removed.
- **2 — `/business` grew an archetype.** Added the project **archetype** (library / cli /
  service / data-pipeline / ai-system), which selects a tailored template + question set, plus
  a read-only `audit` mode. The skill was renamed `/init-tier` here to advertise the new
  archetype, and renamed **back** to `/business` later — the archetype survived, the name did
  not (ADR-0009). *Test: on a real repo, the archetype came out `service` — not
  `ai-system` — because the project has no server-side model, and the audit caught a planted
  false non-goal while clearing the true ones.*
- **3 — `/decision` + `DECISIONS.md`** (append-only ADR-lite), and the doc model evolved
  **straight to five** in one sweep: a single router line replaced the per-file table (see
  ADR-0002), GUIDE renumbered per-PART, and a shared audit ladder + ownership contract
  established (ADR-0004, ADR-0005). *Test: `/decision audit` flagged four real unrecorded
  decisions on a live repo and correctly did not re-flag the one already recorded.*
- **4 — `/audit-history`,** the leak gate: EU-first tiered taxonomy, `default` and `full`
  modes. *Test: a fixture with a secret planted in an old commit and deleted at HEAD — `full`
  caught it, which is the whole reason `full` exists.*
- **5 — `/compliance` + `COMPLIANCE.md`:** EU AI Act and GDPR as **two independent axes**,
  archetype as a trigger only (ADR-0001), self-assessment never a verdict, optional live
  verification via an EU-AI-Act MCP with an offline structural fallback.
- **6 — capstone:** GUIDE PART 9 (the setup / per-change loop / ship-gate workflow), README
  de-WIP'd, the reviewer-gate claim softened to what the kit actually does, MCP-JSON
  duplication resolved. A whole-kit adversarial consistency audit ran: EU-legal lens clean,
  two majors fixed.
- **7 — the kit/template boundary.** The interesting one; see below.
- **8 — the audit series.** A 66-agent adversarial audit (five dimensions, two independent
  verifiers per finding, a completeness critic) confirmed 28 findings plus 6 from the
  critic; a 20-commit series closed them all — the last three closing what a second,
  28-agent adversarial review of the series' own diff confirmed (23 findings, none
  refuted; among them a template-cleanup timing hole that would have destroyed a user's
  own README, and a false re-run warning). Highlights: install.sh had never been
  re-runnable (idempotency, `.gitignore`-newline corruption, junk filter, an inert-hooks
  warning for projects with their own `settings.json`); `/business` had a half-filled
  dispatch gap that licensed overwriting hand-written sections — the Phase 7 bug class,
  finished — and gained a sixth archetype (`local-app`, ADR-0014); `/decision` was the one
  sibling without the Phase 7 template predicate, and the shipped `DECISIONS.md` carried a
  visible example entry its own append-only rule forbade deleting; **`/gate`** shipped
  (ADR-0011), making the ladder's consumer list true; template-cleanup CI (ADR-0012),
  README payoff (ADR-0013), Python-only ruff install (ADR-0015). *Test: `scripts/smoke.sh`
  — 21 assertions over the hooks and every install.sh defect class found — green.*

## Phase 7 — what the first real install found

Phases 1–6 checked whether the kit was **internally** consistent. It was. Nobody had ever
**installed it anywhere**. The first real adoption into an existing project, plus a four-lens
adoption audit, broke it in about five minutes:

- **`PROGRESS.md` shipped attest's own phase log** — the only one of the five docs with real
  content instead of placeholders. And `/checkpoint` is contractually delta-only ("do not
  touch unchanged parts"), so it could never clear what it inherited: the one document
  designed to survive `/clear` would have told every downstream project's next session that
  it *was* attest, and complete. → moved here; the root ships a skeleton.
- **Every bootstrap mode was dead code.** Modes dispatched on file *existence* — and the
  template ships the files. So `/business` always entered update-mode and diffed
  `<placeholders>` against an empty repo. The entire designed onboarding (explore → archetype
  → 2–4 questions → write) had never once run on the primary path. → the predicate is now
  **"absent OR still `<placeholder>`"**.
- **`LICENSE` shipped MIT © the author** into every downstream repo, with no step anywhere
  telling anyone to replace it — and the documented clone path (`rm -rf .git`) erases the
  provenance that would explain it. → `install.sh` never copies it, and replacing it is step 2
  of the README's "First 5 minutes". *(A warning header inside `LICENSE` was tried first and
  reverted: it stopped GitHub detecting the licence at all — the repo showed "Other" — and it
  duplicated the README step. The onboarding instruction lives in the onboarding.)*
- **GUIDE PART 8's `cp` block was not an install.** Against a live project it would have
  destroyed ~294 lines of that project's own `CLAUDE.md` and `PROGRESS.md`, clobbered its
  `settings.json` and its `.claude/commands/`, and **silently hijacked its ruff config** —
  ruff resolves `ruff.toml` over `pyproject.toml` and does not merge, so the victim's rules
  survive on disk as dead code with no diff to notice. → `install.sh` (ADR-0007).
- **Truth pass while we were in there:** `/goal` was documented as a built-in command and does
  not exist; the hooks were called "harmless in a non-Python repo" but require `python3`; the
  PreCompact hook hardcoded `PROGRESS.md` (now `ATTEST_THREAD_CARRIER`, silent if absent); the
  EU-AI-Act MCP pointed at a PART 6 that never mentioned consuming one.

Root cause, one line: **attest was simultaneously the kit and the template and never separated
the two.** Almost every fix removed or corrected text; only `install.sh` was added.

## What the dogfood proved

Two sandboxes, each seeded with **known** planted faults, audited by agents told nothing about
them:

- **The audits detect.** 6/6 planted faults caught at the right severity, 0 false positives:
  a violated non-goal, an undocumented threshold, a secret alive only in history, personal
  data in a sample file. The pre-recorded decision was correctly *not* re-flagged, and routine
  dependencies were correctly ignored.
- **The ownership contract holds.** One hunk (a new dependency) was seen by all four audits;
  each flagged only its own aspect and named the others' ground, instead of triple-reporting.
  That contract exists because the design review predicted exactly that failure (ADR-0004).
- **The kit refuses to fabricate.** `/business` update-mode declined to delete a non-goal to
  match an uncommitted change, and escalated instead. `/decision` declined to invent the
  Options/Why of a threshold nobody had explained — arguing, unprompted, that *"an ADR for a
  choice you discard tomorrow is worse than no ADR, since the log is append-only and can only
  be superseded, never removed."*
- **Phase 7's fix works.** In a fresh sandbox installed via `install.sh`, `/business` opened
  with *"BUSINESS.md is still the shipped skeleton (all placeholders), so this is a Mode 1
  bootstrap"* — then explored, derived the archetype from the code, asked four questions only
  about what the code cannot show, and wrote the file. It touched nothing else and did not
  commit. That path had never run before.

## Notes

- `disable-model-invocation: true` skills cost ~0 when idle — the description is not preloaded.
- The audits are deterministic on their **primary** finding and vary on secondary ones across
  runs; treat a blocker as reliable and a minor as advisory.
- Resolved: the history question got its ADR and its answer — squashed to a single root
  commit at first release (ADR-0008); the phase-by-phase record survives in prose, here and
  in the decision log.
