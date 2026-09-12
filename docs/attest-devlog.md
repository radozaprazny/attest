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
  critic; a 21-commit series closed them all — three commits closing what a second,
  28-agent adversarial review of the series' own diff confirmed (23 findings, none
  refuted; among them a template-cleanup timing hole that would have destroyed a user's
  own README, and a false re-run warning), and a final one closing the pre-merge
  reviewer's findings. Highlights: install.sh had never been
  re-runnable (idempotency, `.gitignore`-newline corruption, junk filter, an inert-hooks
  warning for projects with their own `settings.json`); `/business` had a half-filled
  dispatch gap that licensed overwriting hand-written sections — the Phase 7 bug class,
  finished — and gained a sixth archetype (`local-app`, ADR-0014); `/decision` was the one
  sibling without the Phase 7 template predicate, and the shipped `DECISIONS.md` carried a
  visible example entry its own append-only rule forbade deleting; **`/gate`** shipped
  (ADR-0011), making the ladder's consumer list true; template-cleanup CI (ADR-0012),
  README payoff (ADR-0013), Python-only ruff install (ADR-0015). *Test: `scripts/smoke.sh`
  — 21 assertions over the hooks and every install.sh defect class found — green.*
- **9 — enforcement over rhetoric.** An external analysis verified the kit's claims almost
  to the line — and named the real gap: "gate", "block" and the name *attest* promised
  **mechanism**, the kit delivered **discipline**. The series that followed closed the
  distance where it could and renamed it where it could not: `/gate` now appends a dated
  **run record** under `.attest/` — SHA, kit version, passes, verdict — so an audit leaves
  evidence, not assurance (ADR-0016); the gate's three document audits run in a new
  `doc-auditor` agent with no Bash/Edit/Write — "the audit writes nothing" became a
  capability, not a promise (ADR-0017), while the reviewer keeps Bash for tests and now
  says so honestly; the kit carries a `Kit version:` inside the shared ladder and
  `install.sh` tells every skipped kit file apart — *identical* vs **DIFFERS** — so stale
  installs stopped being silent (ADR-0018); attest gates itself in a live CI — ruff,
  shellcheck, smoke on every push (ADR-0019); PART 8's promote-globally advice now carves
  out the audit family (a promoted copy loses the project-relative ladder exactly where
  promotion aims); template-cleanup's sentinel comment stopped claiming more than the two
  markers it checks, and the README states plainly that the cleanup is an ordinary,
  revertible commit and that README's "gated" means *verdict + record*, with the
  discipline of honoring it left named as the user's. Corrections to this log: the
  phase-8 series was **21** commits, not 20 (written before the final reviewer fix
  landed), and its second review's findings were closed by three commits plus that one.
  *Test: `scripts/smoke.sh` grew to 23 assertions (identical-vs-DIFFERS re-run signals) —
  green.*
- **Phase 10 — the audit fix series** (2026-08-11). A full multi-agent audit of the repo
  (six finder lenses over shell, hooks/config, CI, skills, docs and end-to-end installation;
  every finding then handed to an adversarial verifier that had to re-derive it from the
  file or refute it) returned **two majors and ~22 minors** — one finding refuted, none
  critical. Both majors were the same failure of imagination: *code that judged a file by a
  predicate its own earlier run had made true*. `install.sh` asked "does this project
  configure ruff?" of a `ruff.toml` **it had installed**, so every re-run into a Python
  project called the kit's own file the user's and quietly exempted it from the ADR-0018
  drift ladder (ADR-0020). And `template-cleanup` asked whether the repo still *looked* like
  an untouched template, then acted wholesale — `rm -rf docs scripts`, `cat > LICENSE` —
  which is only safe on the day the repo is generated; repo-creation pushes do not reliably
  fire, so a user's own files could be in those directories by the time it ran, and the
  in-file comment said so rather than preventing it (ADR-0022). The fix in both cases was to
  ask the *target's* bytes: `cmp` before a message, a content check before every `rm` or
  rewrite, attest's files removed by name and never a directory wholesale. The cleanup also
  moved out of the YAML into `scripts/template-cleanup.sh` — until then the one destructive
  thing in the repo was the one thing neither shellcheck nor smoke ever touched, first
  executing for real in a stranger's repository. The rest of the series: the format hook
  stopped reformatting files outside the project (ADR-0024), `ci.yml.example` finally
  reaches the consumers it addresses (ADR-0021), the ownership contract settled the
  `/decision` ↔ `/compliance` collision it had used as its own motivating example
  (ADR-0023), and `/gate` began handing its document audits enough git material to scope
  themselves to "since the last audit" — the anti-re-flag rule had been unenforceable in
  the gate path since the doc-auditor lost Bash.
  *Test: `scripts/smoke.sh` grew from 23 to **61** assertions — the new ones cover exactly
  the branches the defects sat in, including fourteen on the cleanup — green.*

- **Phase 11 — the subtraction pass (2026-08-28).** The first series that made the kit
  *smaller*. Every component was put to one question — *would a new adopter miss this if it
  were gone?* — and four answered no. The formatter went first (ADR-0027): it was the only
  thing in the kit that edited the user's code, the only thing bound to one language, and the
  root of five other decisions (ADR-0015, 0020's worked example, 0024, a Python-detection
  predicate, a cleanup parity branch, a `.gitignore` line, a paragraph in the shipped
  `CLAUDE.md`). Removing one hook deleted a whole subsystem — and with it the kit's last
  interpreter dependency. Then the two remaining hooks, both of which merely *reminded*:
  a compaction nudge that fires when it is already too late to act, and a session-length
  warning measuring transcript lines as a proxy for context pressure that Claude Code shows
  natively. What replaced them is the interesting half (ADR-0028): the same two event slots,
  spent on **prevention**. A non-goal is *always a blocker* on the ladder, yet the agent only
  met the non-goals when `/gate` ran — after the code existed; now `SessionStart` loads them
  before the first edit. `/audit-history` was the ship gate, yet nothing connected it to the
  command that ships; now a `PreToolUse` guard on `Bash` asks at exactly that moment, using a
  run record keyed to the **current** HEAD sha, so the question is *"was this state audited"*
  rather than *"was this repo ever audited"*. The rest was honesty about what the kit had been
  shipping to people who did not need it: `COMPLIANCE.md` and `/compliance` became opt-in
  because at install time nobody knows the archetype yet and an empty posture file reads as
  *"declared"* (ADR-0030); the two `.example` files went, and the installer stopped printing
  23 paths and started printing what you can now do (ADR-0031); the severity ladder lost the
  per-skill alias that only restated the owner column (ADR-0029). Into an empty directory a
  default install went from 23 items to 18 — the count is the least of it: none of the
  survivors edit your code, none are language-bound, none are inert. `python3` stopped being
  a requirement at all.
  *Test: `scripts/smoke.sh` grew from 61 to **104** assertions — the new ones cover both hooks
  end to end (silence on unfilled templates, the sha-specific ship check, valid JSON for a
  hostile command), the opt-in flag in both orders, and the report's changed-nothing path —
  green; shellcheck clean over the installer, the hooks, the smoke test and the cleanup.*

- **Phase 12 — the guard learns to tell the truth about itself (2026-09-04).** An outside
  analysis of `v0.4.0` — eight lenses, 65 findings — arrived and turned out to be worth taking
  seriously: ten of its sharpest claims were reproduced here, on a different OS than it was
  written on, and all ten held. Its value was not the count but the reframing. The ship guard
  *could* be bypassed, which was never a secret; what nobody had noticed was that a bypass
  **left no line in the log**, so a miss and an unregistered hook were the same observation —
  the exact ambiguity ADR-0034 had introduced the log to remove. And the guard matched a
  *filename*, so an empty record opened the door and so did one whose verdict was `blocker`,
  while its own prompt offered to "ship unaudited": two claims collapsed into one word. Four
  entries came out of it (ADR-0037…0040) and the order mattered — trace first, because until a
  miss is visible no later fix is measurable. The other two findings were quieter and neither
  was about the guard: a Windows checkout opened from WSL hands `dash` CRLF hooks, which exit 2,
  and a `PreToolUse` exit 2 does not fail — it **blocks every Bash call in the session**; and
  attest had been shipping twelve of its own audit records, one carrying the maintainer's
  address, into every repo generated from the template button.
  *Test: the kit's own gate then caught the fix. The first sweep deleted records on any non-zero
  `git cat-file`, which outside a repository is every record including the adopter's — the exact
  inversion of the invariant its own ADR had just written down — and the first version of the
  test ran outside a repository too, so a green suite covered a destructive bug. `scripts/smoke.sh`
  118 → **156** assertions; that fixture is now a real repository with its own commit.*

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

### The first run outside a sandbox — 2026-09-11, and the first ✅ anyone had seen

A new personal project, kit 0.8.0, installed into a repo with **no code in it yet**. Before its first real commit the gate ran **five times on one
HEAD**, dirty tree, documents only:

| run (UTC) | blocker | major | minor | nit | verdict |
|---|---|---|---|---|---|
| 19:42:58 | 0 | 3 | 7 | 2 | ⚠️ |
| 20:14:48 | 0 | 0 | 7 | 2 | ✅ |
| 20:30:52 | 0 | 0 | 4 | 3 | ✅ |
| 20:45:09 | 0 | 0 | 3 | 2 | ✅ |
| 20:56:12 | 0 | 0 | 3 | 2 | ✅ |

Commit at 21:03:31. **73 minutes** across the five runs and **81** from the first run to the
commit; **49** of those 81 fell after the gate had already said ✅. The series ended because the
author stopped it by hand.

- **Run 1 earned its keep.** Three real findings at `major`, all of them in documents: a command
  whose failure mode the text had not noticed, a secret written where it would have been
  committed, and an ignore rule that did not cover what it was for. What they were, specifically,
  belongs to that project and not to this page — the same reason a run record carries counts and
  not contents (ADR-0049).
- **Runs 2–5 mostly found what the previous round's fixes had introduced** — the author's
  account, and it matches what two of this repo's own records say about their own series
  (ADR-0062).
- **Nothing said stop.** The record said ✅ while the verdict text recommended repairing minors
  before committing, pointing especially at `DECISIONS.md` and its append-only rule. Both
  halves were defensible, which is why the loop ran: ✅ *permitted* a commit and nothing
  declared the round over.
- **The first commit was 442 added lines, all of them documents**, four ADRs, and no code.

Why this was new information: the sandboxes above tested whether the audits **detect**, with
planted faults and a known answer key. Nothing had tested whether the loop **ends** — and it
could not have been seen here, because all ten of this repo's own runs had returned ⚠️, so the
state after a ✅ had never occurred. The kit's first real adopter reached it in an afternoon.

What it changed: ADR-0061 (the round ends at ✅, and the gate's last line is an instruction),
ADR-0062 (a fix subtracts before it adds), ADR-0063 (ids from every ref — the same session
blindness, in another form), ADR-0065 (what day one costs), ADR-0066 (a skeleton is skipped
before the subagent).

**What this is not.** One series, one project, one afternoon: `n=1`. The counts and the
timestamps are read off the five records; everything about what the verdict *text* said is the
author's account, because a record deliberately carries no prose (ADR-0049). The neatest claim
of the series — that the one round which removed claims rather than adding them was the first to
introduce no new inaccuracy — is an observation, not a measurement, and is recorded as one.

## Notes

- `disable-model-invocation: true` skills cost ~0 when idle — the description is not preloaded.
- The audits are deterministic on their **primary** finding and vary on secondary ones across
  runs; treat a blocker as reliable and a minor as advisory.
- Resolved: the history question got its ADR and its answer — squashed to a single root
  commit at first release (ADR-0008); the phase-by-phase record survives in prose, here and
  in the decision log.

  *Shipping it taught two more things, both about the guard.* Opening the PR meant writing the
  first real ship record — and a record keyed to the HEAD being pushed can never sit in the
  commit it names, so ADR-0033 wrote the rule down rather than leave the next reader to
  re-derive it from a filename that looks off by one commit. Then a push at a sha no record
  named went through with **no prompt**, and nothing in the repo could say whether the hook had
  fired and the permission mode answered for it, or whether the hook had never been registered
  at all. A gate whose firing leaves no trace is precisely the thing this kit exists to replace,
  so ADR-0034 gave the guard a log — the pass as well as the ask — which in turn narrowed
  ADR-0026: `.attest/tmp/` is shared scratch now, and whoever writes there deletes their own
  files, not the directory. The suite grew 104 → 111, and one of the new runs exposed a fourth
  defect that was nobody's design: `smoke.sh` inherited `ATTEST_THREAD_CARRIER` from the
  developer's own settings and read the maintainer's live document instead of its fixtures. It
  unsets both overrides now.

  *And a third, from the merge itself.* PR #4 merged without the guard saying a word, which read
  as a missing `gh pr merge` pattern — until measuring what the list actually covered turned up
  `gh repo edit --visibility public` and `gh repo create`, equally silent, on a repo whose own
  `Next` list says *"decide on going public"*. ADR-0035 took the visibility flip and refused the
  merge, for a reason worth keeping: the guard's prompt would have claimed the merge *"sends data
  off the machine"* when every byte was already on the remote, no record could ever name a merge
  commit that does not exist yet, and most merges never touch the machine at all — so matching
  the CLI form would have sold a coverage the hook cannot have. A declared gap beats a
  believed-but-false gate; the merge boundary is branch protection, which is server-side. The
  `case` arms now each carry what the prompt will claim, so the two reasons can never be
  substituted for one another. Suite 111 → 118, one of them pinning that the merge stays silent.

  *Then the carrier itself.* `docs/attest-progress.md` went false at the merge three times in a
  row — *"uncommitted"* after PR #3, *"open as PR #4"* after PR #4, *"in progress"* after PR #5 —
  each time written correctly and falsified by the very next event. The shape is the same one
  ADR-0033 had already named in a different place: the carrier lives inside the branch it
  describes, so it can never describe its own merge. It matters more here, because the
  `SessionStart` hook loads the file as *binding* context, so the falsehood is read into the next
  session as a rule. ADR-0036's answer is not a reminder but a form: state what is true of the
  **branch**, in a tense the merge leaves standing — *"committed on `feat/x`; PR #7 opened"*,
  never *"in progress"*. It needs no action at all to stay true, which is the only property that
  survives someone forgetting; staleness is recoverable, and a wrong line is not, because nobody
  can tell it from a current one.
