# Proposal — a gate that ends: a finish line, triggers, two cadences, a bounded loop

> **Status: part A recorded, parts B and C still proposals.** Written 2026-09-12 from the nine
> `/gate` records under `.attest/`, the gate skill and its passes, and a measurement over the
> last 40 non-merge commits on `main` (at `332a40b`). **§2.1 is now ADR-0055 and is implemented**
> — the entry in `docs/attest-decisions.md` is the decision, and the draft in §5 is kept only as
> the proposal it came from. **Everything else here is still undecided**: §2.2–2.4 change no
> file yet, the drafts for ADR-0057 and ADR-0058 are `DRAFT` (renumbered: 0056 was taken by the
> relation fix this proposal's own first gate run produced), the change list in §4 is a plan and
> not a diff, and the seven questions in §6 are open. Delete this file once B and C are decided
> too; what survives it is the ADR log.

## 0. In ten lines

The gate takes four to five rounds and still ends ⚠️ because three of its four passes are
judgment over prose, and a loop over a judge that varies between runs has no finish line. The
proposal, in the order it should be built:

1. **A finish line** — **done, ADR-0055.** The verdict flips on **blocker** or **major**, and on
   nothing else. Minor and nit stay listed and counted, and are what the ladder already calls
   them: advisory.
2. **Stage 0 in shell.** Before any subagent, one POSIX script reads the diff and decides which
   passes it needs. A one-file fix costs one subagent, not four. `/gate` becomes that light gate.
3. **Two cadences.** `/gate full` runs every pass over the whole branch, once, before a push,
   beside `/audit-history`. That is the run that found both September blockers.
4. **A bounded loop, only where a command is the judge.** `/gate fix` loops the reviewer and the
   project's own checks, fixes reviewer-owned blockers and majors in code, at most three rounds,
   and hands every document finding to the human as a decision.

`/gate` keeps its read-only contract. Every round keeps its own record. No new hook, no new
skill, no interpreter dependency.

## 1. Evidence

### 1.1 The nine runs

| record | HEAD | rounds on this tree | blocker | major | minor | nit | verdict |
|---|---|---|---|---|---|---|---|
| gate-20260819-080558 | a53ef0f | 1 | 0 | 1 | 8 | 5 | ⚠️ |
| gate-20260828-125725 | ce439a5 | 1 of 4 | 0 | 4 | 13 | 4 | ⚠️ |
| gate-20260828-144100 (late) | ce439a5 | 2 of 4 | 0 | 2 | 10 | 1 | ⚠️ |
| gate-20260828-143838 | ce439a5 | 3 of 4 | 0 | 3 | 9 | 1 | ⚠️ |
| gate-20260828-145255 | ce439a5 | 4 of 4 | 0 | 5 | 12 | 2 | ⚠️ |
| gate-20260904-110554 | 93fc862 | 1 of 2 | 1 | 5 | 14 | 4 | ⚠️ |
| gate-20260906-113757 | 93fc862 | 2 of 2 | 0 | 4 | 13 | 4 | ⚠️ |
| gate-20260907-103000 | d91f69f | 1 of 2, whole PR #10 | 2 | 2 | 7 | 1 | ⚠️ |
| gate-20260907-110842 | d91f69f | 2 of 2 | 0 | 2 | 8 | 2 | ⚠️ |

Three things the records say about themselves:

- **Rounds do not converge.** On `ce439a5` the major count went 4, 2, 3, 5 across four full
  runs. Two records state in their own notes that the fixes made after one round opened the
  holes the next one found (`gate-20260828-144100`, `gate-20260907-110842`).
- **The code half converges; the prose half does not.** By the fourth run on `ce439a5` the
  reviewer's verdict on the code had been clean twice running, and every remaining finding was
  in instruction prose (`gate-20260828-145255`, note).
- **No run has ever returned ✅**, and what flips the line is defined nowhere
  (`docs/attest-progress.md`, P1: *"define what flips the verdict to ⚠️"*). A loop with no stop
  condition stops when the judge tires. That is what "four or five times and still not enough"
  is.

### 1.2 Why this is not the CI loop

The loop that works in CI has a machine as its judge: exit `0` or not, the same answer twice
for the same input, cheap to ask again. The gate's `reviewer` has that in part (it runs the
tests and the lint). The three document audits do not, and the records show them finding
different things on the same tree. Asking a judgment pass until it says yes does not make the
tree right; it makes the yes worthless. `METHOD.md` already says this in its own words: *"treat
a blocker as reliable and a minor as advisory."*

### 1.3 What a run costs today

Four subagents, always (`.claude/skills/gate/SKILL.md`, step 2), each reading the whole diff,
its skill section, the ladder and its control document. Two details make it worse than it looks:

- `/compliance audit`'s "cheap trigger check" is done **by the subagent**
  (`.claude/skills/compliance/SKILL.md`, *"The trigger check"*). Its cheapness is in what it
  returns, not in what it costs: the context is spent before the check runs.
- `/business audit` and `/decision audit` have **no trigger at all**; both run the full pass on
  every diff. On attest, `/business` ran *degraded* on all nine runs because `BUSINESS.md` is
  the shipped template, and each of those was still a subagent context.

Measured on the last 40 non-merge commits on `main` (script in §A; `.attest/` excluded from the
keyword scans, because a record is an output, not ground):

| | commits |
|---|---|
| total | 40 |
| touch only `.attest/` (committing a record) | 10 |
| touch only `*.md` | 24 |
| would trigger `/decision audit` (manifest, workflow, hook, settings) | 12 |
| would trigger `/compliance audit` (keyword on an added line) | 12 |
| would trigger `/business audit` (keyword on an added line) | 7 |
| would trigger at least one document audit | 18 |

Had every one of those commits been gated as the skill stands, that is 160 subagent runs. With
stage 0 it is 30 reviewer runs plus 31 document-audit runs: 61. Attest is the **worst case** for
keyword triggers, because its diffs are prose *about* personal data, models and non-goals; a
code repository sits well below that.

## 2. Design

### 2.1 The finish line

One rule, in `_shared/audit-ladder.md` next to the nit rule from ADR-0023: **the verdict line is
⚠️ *commit after changes* iff at least one blocker or major remains after the merge.** Minor
and nit never flip it. Minors stay in the verdict and in the record's counts; they are, by the
ladder's own word, advisory.

Honesty check against the records: this rule alone would not have turned a single one of the
nine runs green, because every one carried a major. What it changes is (a) that "13 minors" no
longer reads as a red gate, (b) that a loop has a condition a merge step can evaluate, and
(c) what a ⚠️ asks of you: fix the blockers and majors, decide about the rest. On adopter
projects, where a typical run returns minors, it turns most gates ✅ in one round.

### 2.2 Stage 0 — triggers in shell, and the light gate

After step 1 has written `$M`, one POSIX sh script, `.claude/skills/gate/triggers.sh`, reads
`$M/diff.patch`, `$M/status.txt` and the untracked files the status names (they are not in the
diff), and writes `$M/triggers.txt`: one line per pass, `run` or `skip`, with a reason and, for
a `run`, a `$M/trigger-<pass>.txt` holding the `file:line` hits the subagent starts from. No
model is involved; the stage costs nothing. Step 2 launches only the passes marked `run`.

| pass | `run` when | otherwise |
|---|---|---|
| `reviewer` | the material is non-empty and touches anything outside `.attest/` | `skipped — records only` |
| `/decision audit` | a dependency manifest or lockfile, a workflow, a Dockerfile / compose / infra file, `.claude/settings.json` or a hook changed; or an added line imports a module no file in the tree imported before | `skipped — no trigger` |
| `/compliance audit` (when installed) | an added line outside `.attest/` hits the Mode 3 list (personal-data field names, model / inference / scoring words, export / transfer / SDK / telemetry, Art 5 phrases), or `COMPLIANCE.md` changed | `skipped — no trigger`. Step 0's posture check moves here: "no posture declared" is a mechanical fact (file absent or still the template) and is reported as a standing line, without a subagent |
| `/business audit` | `BUSINESS.md` is filled, and an added line hits the project's watch list (§6, Q1) or the generic set (network, telemetry, upload), or a new top-level directory or entry point appeared, or `BUSINESS.md` changed | `skipped — no trigger`; or `nothing declared — run /business` without a subagent when the file is absent or still the template |

A diff that touches only `.attest/` short-circuits the whole gate: `skipped — records only`.

What the light gate cannot see, said plainly: a hunk that violates a non-goal without using a
word on any list. The `.gitattributes` blocker of 2026-09-07 was found by `/business audit`
reading `*.sh text eol=lf`; no keyword set flags that. This is why §2.3 exists, and why the light
gate is never the only gate.

### 2.3 Two cadences — `/gate` per commit, `/gate full` per push

`/gate full` runs every installed pass unconditionally over `<base>..HEAD` plus the working
tree, as the 2026-09-07 run did by hand, and belongs to the **ship** cadence beside
`/audit-history`. That run is the evidence: two earlier dirty-tree runs over the same series
missed both blockers, and the run over the whole PR found them. The complete judgment then
happens once, where the diff is the one that ships, and full gates stop being run four times
over one tree.

The record gains two lines, `mode: light | full` and `triggers: reviewer run · decision skip
(no trigger) · …`, so a skipped pass reads as *skipped*, never as *ran clean*. "Skipped",
"degraded" and "not installed" are three different facts and stay three different words.

### 2.4 `fix` — a bounded loop on the machine layer

`/gate fix` (also `/gate full fix`) is the one mode that edits, and it edits **code only**:

1. Run the gate as above; merge; verdict.
2. If the `reviewer` owns a blocker or a major, fix it in the main context: the author's own
   edit, visible in the session.
3. Run the project's own checks in shell, the commands `CLAUDE.md` names (here: shellcheck and
   `scripts/smoke.sh`). Red → back to 2, same round.
4. Re-run stage 0 on the fix hunks. If a document trigger hits on them, that pass runs once, on
   the hunks. This is the whole "graph": a fix re-opens only the ground it touched.
5. Launch the `reviewer` in **re-review mode**: previous findings, the fix hunks, the touched
   files. It confirms each finding addressed, looks for regressions, runs the checks again.
6. Finish line reached → stop. Otherwise round *n+1*, **at most three rounds**. Still red after
   three → stop, record it, and say *split the change*.

Every round is a gate run and appends its own record with `round: n/3 · mode: fix`. ADR-0016
stands untouched, and so does the record guard. Document findings are **never** fixed by this
mode: a violated non-goal, an unrecorded decision, regulated ground come back in the final
verdict under *for you to decide*, with the owning skill's write mode as the next step. That is
the split the kit rests on: what a command can verify may loop; what a declaration governs needs
the person.

Not a Stop hook, not `/loop`: ADR-0028 removed the nags on purpose. The loop is an explicit
command with a cap, never something that fires by itself.

### 2.5 What stays exactly as it is

- `/gate` and `/gate full` write nothing but the record (ADR-0016).
- One file per run, append-only; new lines in the record, no new exception (ADR-0016, 0032, 0049).
- `doc-auditor` has no Bash; stage 0 runs in the main context's shell before any subagent
  exists (ADR-0017).
- The ownership contract and the three bare rungs (ADR-0023, 0029, 0030).
- No interpreter dependency: the trigger script is POSIX sh, shellchecked in CI, LF-pinned
  (ADR-0027, 0039; `smoke.sh` §0 asserts no `.py` under `.claude/`).
- No new hook, no new skill directory: two words on a command that exists.

## 3. Cost and feel

Estimate, in subagent runs per small commit (one context each; the unit is what is comparable,
not tokens):

| | today | after §2.1–2.3 | after §2.4 (`fix`) |
|---|---|---|---|
| subagent runs, first round | 4 | 1 + 0–3 by trigger (attest's history: ~2) | same |
| rounds run by hand | 4–5 | 1–2 | 0; ≤ 3 inside the command |
| subagent runs per commit | 16–20 | 2–6 | 3–8 |
| full gate over the whole branch | every round | once per push, 4 runs | once per push |

What the person reads changes more than the count. One verdict line. An *act on* list: blockers
and majors, each with owner and evidence. One line with the minors folded under a count. In `fix`
mode, one line per round, and a *for you to decide* list that holds only questions about intent.
The wall of thirteen minors that made a gate feel red is gone from the top of the page, not from
the record.

## 4. Change list by file

Phase **A** = finish line · **B** = stage 0 and the two cadences · **C** = `fix`.

**The A rows are done** (2026-09-12, ADR-0055), plus one the list missed:
`.claude/agents/reviewer.md` — its output shape said *"no blocking findings"* and defined
blocking nowhere, so the rule needed the same sentence there or it had two homes to drift
between. B and C rows are untouched.

| file | change | phase |
|---|---|---|
| `.claude/skills/_shared/audit-ladder.md` | the verdict rule under *The ladder*, beside the ADR-0023 nit paragraph; bump *Kit version* when cutting | A |
| `.claude/skills/gate/SKILL.md` | step 4: the verdict is a function of counts (cite the ladder, do not restate); findings split into *act on* / *advisory* / nits | A |
| `GUIDE.md` §3.6 | one sentence: what flips the verdict | A |
| `docs/attest-decisions.md` | ADR-0055 | A |
| `docs/attest-progress.md` | close P1 *"define what flips the verdict"* | A |
| `.claude/skills/gate/triggers.sh` (**new**) | POSIX sh; input `$M`; output `$M/triggers.txt` and `$M/trigger-<pass>.txt`; rules of §2.2; exit 0 always (fail-open, like the hooks) | B |
| `.claude/skills/gate/SKILL.md` | modes `/gate` · `/gate full`; step 1: cleanliness from `git status --porcelain` (not `git diff --quiet`), `gate-records.txt` filtered to `gate-*`, first-parent diff on a merge HEAD, untracked contents written for stage 0 (all P1 items); step 1b: run `triggers.sh`; step 2: launch only `run` passes and hand the evidence file; step 5: `mode:` and `triggers:` lines; the contract paragraph | B |
| `.claude/skills/compliance/SKILL.md` | Mode 3: the trigger check and Step 0 restated as *done by stage 0, you receive the hits; in `full` you re-check the diff yourself*; flatten the `###` siblings so "hand Mode 3" hands the whole mode (P1: *55 words*) | B |
| `.claude/skills/business/SKILL.md` | Mode 3: *in light mode you run only on a trigger hit*; Mode 1: the watch-list line (Q1) | B |
| `BUSINESS.md` (template) | the optional watch-list line under Non-goals (Q1) | B |
| `.claude/skills/decision/SKILL.md` | Mode 2: the same *you receive the hits* paragraph | B |
| `.claude/agents/doc-auditor.md` | the evidence file is part of the material | B |
| `install.sh` | nothing structural: `copy_tree_if_absent` already installs the skill directory and the `*.sh` arm strips CRLF; extend `ensure_attribute` so the new script is LF-pinned in the adopter's repo (today only `.claude/hooks/*` is) | B |
| `.gitattributes` (attest's own) | the same pin for the new path | B |
| `.github/workflows/ci.yml` | shellcheck list gains `.claude/skills/gate/triggers.sh` | B |
| `scripts/smoke.sh` | fixtures per rule: records-only → all skip; manifest → decision `run`; keyword → compliance `run` only when installed; watch word → business `run`; template `BUSINESS.md` → *nothing declared* with no run; script runs under `sh`; install-shape count +1 | B |
| `GUIDE.md` §3.6, §4.2, PART 4 note, PART 9 | modes; stage 0 and what light cannot see; the material includes the evidence file; per-change = `/gate`, ship = `/audit-history` + `/gate full` | B |
| `README.md` lines 70–76 and 214 | *"every document audit the project installed"* → *the passes the diff needs; `full` runs them all*; the workflow line | B |
| `METHOD.md` *Two gates, two cadences* and the cost line | *"a model run per commit"* → a run per pass the diff needs, the full judgment once per push | B |
| `docs/attest-decisions.md` | ADR-0057 | B |
| `docs/attest-progress.md` | close F65 *"what `/gate` is for"* and the P1 gate-scoping items | B |
| `.claude/skills/gate/SKILL.md` | the `fix` section (§2.4), the `round:` line | C |
| `.claude/agents/reviewer.md` | *re-review mode*: inputs (previous findings, fix hunks, touched files), output (per finding: addressed / not / regressed, plus new findings), checks re-run | C |
| `GUIDE.md` §3.6 and PART 5 | a pointer: for *until green*, `/gate fix`, not `/loop` | C |
| `docs/attest-decisions.md` | ADR-0058 | C |
| `.attest/gate-*.md` | no change to any existing record (append-only); new records carry the new lines | — |

## 5. ADR drafts

Numbered after ADR-0054, the log's newest entry. The status word is `DRAFT` until `/decision`
records the entry, at which point it becomes `Accepted` and the date the day it is written.

## ADR-0055 — the verdict line flips on blocker or major, and on nothing else · RECORDED 2026-09-12

  **No longer a draft.** Recorded in `docs/attest-decisions.md` as ADR-0055 and implemented; the
  entry there is the decision, this is the proposal it came from. Two things changed on the way
  in, and a third went wrong. `.claude/agents/reviewer.md` joined the change list: its output
  shape said *"no blocking findings"* and defined blocking nowhere, so the rule would have had
  two homes disagreeing the moment it was written in one. The entry carries **no relation
  field**, where this draft had `Extends: ADR-0023`.

  **And the reason given for dropping it was false.** The entry argued that `Extends` is not one
  of the log's relations and was not invented here. The log had been using `Extends:` under four
  entry titles since 2026-09-07, and `Relates to:` under a fifth; only the *rules* said three.
  The `/decision` pass of the gate run over that very commit caught it — ADR-0056 records the
  two relations properly and states the correction, because ADR-0055 was already committed and
  this log's window closes at the commit. Worth keeping visible here: the mistake was reasoning
  about a document from the rules that describe it instead of from the entries in it, which is
  the exact failure the audits are pointed at.


- **Context** — Nine gate runs, nine ⚠️, and the rule that produces the line is written nowhere
  (carrier, P1). The ladder calls `minor` *"real but advisory"*, yet a run of thirteen minors
  reads as a red gate, and a loop cannot stop on a line whose condition is undefined.
- **Options** — (a) leave the line to the merge step's judgment; (b) ⚠️ on any finding;
  (c) ⚠️ on `blocker` or `major` only, `minor` and `nit` advisory.
- **Decision** — (c).
- **Why** — (a) is the status quo and is what makes the rounds unbounded. (b) makes every gate
  red on a project with an honest reviewer and trains people to read ⚠️ as noise; the kit's
  hooks were rebuilt on exactly that argument (ADR-0028). (c) matches the ladder's own
  definitions: `major` is *"should not go in as it stands"*, `minor` is *"real but advisory"*.
- **Consequences** — The line is now a function of counts, so a merge step and a loop can
  evaluate it. Minors stay listed and counted; none is dropped. On attest's own nine records the
  rule would have changed no verdict, because every run carried a major: it buys termination,
  not a greener history. The rule lives in the ladder beside ADR-0023's, and `gate/SKILL.md`
  step 4 cites it instead of restating it.

## ADR-0057 — a pass runs only when the diff touched its ground; `full` runs them all · 2026-09-12 · DRAFT

- **Context** — `/gate` launches four subagents on every diff. `/compliance audit`'s "cheap"
  trigger check costs a full subagent before it returns *out of scope*; `/business` and
  `/decision` have no trigger at all. Four subagents for a one-file change is why the gate goes
  unrun (carrier, F65). Measured on the last 40 non-merge commits: 10 touch only `.attest/`,
  24 only `*.md`, and a document audit would have had a trigger on 18. The full gate is also what
  found both September blockers, but only when run over the whole PR.
- **Options** — (a) keep four, always; (b) a user-chosen `light` flag that drops the document
  audits; (c) a shell stage that decides per pass from the diff, with `full` as the per-push run
  over the whole branch.
- **Decision** — (c).
- **Why** — (b) hands the human, per commit, the decision the gate exists to take from them,
  and they will choose light every time; the kit's own rule is that a mechanism prevents rather
  than reminds, and a flag reminds. (a) is the cost that stops the gate running. (c) costs
  nothing when it skips and leaves the complete judgment where the diff is the one that ships.
- **Consequences** — A new POSIX sh file installs with the gate skill (`triggers.sh`),
  shellchecked in CI, LF-pinned, smoke-tested per rule; kit footprint +1. The light gate can miss
  what only judgment sees, and the record says so: `mode: light` and a `triggers:` line make
  *skipped — no trigger* a fact distinct from *ran clean*, *degraded* and *not installed*.
  `/compliance audit`'s Step 0 becomes a shell fact. `/gate full` joins the ship cadence in
  GUIDE PART 9 beside `/audit-history`; whether the ship guard should demand its record is
  deferred until the light gate has a history to measure. Attest's own diffs are the worst case
  for keyword triggers, prose about the very words on the lists, and still halve the runs.

## ADR-0058 — `/gate fix` loops only on what a command can verify, at most three times · 2026-09-12 · DRAFT

  Narrows: ADR-0016 (*"the run record is the gate's only write"* holds for `/gate` and
  `/gate full`; `fix` is a named mode whose code edits are the author's, made in the main
  context, and whose every round appends its own record).

- **Context** — The maintainer runs the gate four to five times per change by hand and fixes
  between runs; the records show those fixes opening new findings, so the second run is not
  optional (`gate-20260907-110842` says so in its note). The CI pattern of run, read the red,
  fix, run again until green works because a command is the judge. Three of the gate's four
  passes are not commands.
- **Options** — (a) keep the loop manual; (b) loop the whole gate until ✅; (c) loop only the
  `reviewer` and the project's checks, fix only reviewer-owned blockers and majors, cap three
  rounds, hand every document finding to the human.
- **Decision** — (c), as `/gate fix`, composable with `full`.
- **Why** — (b) cannot terminate: majors on one tree went 4, 2, 3, 5 across four runs, and the
  judgment passes vary on secondary findings (`METHOD.md` says so). A loop over such a judge ends
  when the judge tires or the tokens do. (a) is what costs the tokens today. (c) puts the loop
  where the judge is a command and keeps the person where the question is about intent.
- **Consequences** — Each round is a gate run and appends its own record with
  `round: n/3 · mode: fix`; ADR-0016's one-file-per-run shape holds and `record_guard.sh` is
  unaffected. `/gate` and `/gate full` keep writing nothing but the record; `fix` edits code,
  never a control document, so recording stays the owning skill's human-approved write mode.
  `reviewer.md` gains a re-review mode. Stage 0 re-runs on the fix hunks, so a fix that adds a
  dependency re-opens `/decision audit` on that hunk only. After three red rounds the mode stops
  and says *split the change*: a fourth round is not a fix, it is evidence the change is too
  large to gate. The loop itself is model behaviour and `smoke.sh` cannot test it; the record
  lines it writes can be, and are.

## 6. Open questions — decide before phase B and C

1. **The business watch list.** Where does a project declare the words its non-goals turn on?
   Proposed: one HTML comment under *Non-goals* in `BUSINESS.md`
   (`<!-- gate-watch: socket, telemetry, upload -->`), read by `triggers.sh`; the generic set
   applies when the line is absent. Alternative: always run `/business audit` in light mode when
   `BUSINESS.md` is filled (one more subagent per commit, no list to maintain).
2. **Should the ship guard demand a `gate-…` record with `mode: full` for HEAD**, as it demands
   a ship record? Stronger boundary, one more prompt per push. Proposed: not yet; measure first.
3. **The cap.** Three rounds (proposed) or two.
4. **Should `fix` also take reviewer minors in files it already touches?** Proposed: no. Advisory
   stays advisory and the diff stays minimal; the user can ask for them by name.
5. **The keyword sets.** §A's are a measured starting point. Should attest exclude its own
   carriers (`docs/attest-*.md`) from the scan as it excludes `.attest/`? Proposed: no; those are
   attest's control documents and a hit there is real.
6. **Naming.** `full` and `fix` as words on `/gate` (mirrors `/audit-history full`) or a separate
   `/converge` skill. Proposed: words on `/gate`; a fourth skill widens the surface the README
   promises to keep narrow.
7. **Should the ship guard block on a major, not only a blocker?** Surfaced by the `/decision`
   pass of this proposal's own first gate run. `ship_guard.sh` reads `findings: 0 blocker`
   (ADR-0037), so a record carrying a major clears a push while the same counts read ⚠️ at
   commit time. The asymmetry is defensible — the two gates ask different questions — and it is
   now stated in the ladder rather than left for the next reader to notice. Proposed: leave it,
   and revisit only with evidence of a major that should have stopped a push.

## 7. Order of work

- **A — done, 2026-09-12** (ADR-0055). Four files, not three: `_shared/audit-ladder.md` holds
  the rule, `gate/SKILL.md` step 4 cites it and splits its output into *act on* / *advisory*,
  `GUIDE.md` §3.6 gets a sentence, and `.claude/agents/reviewer.md` was added on the way — it
  said *"no blocking findings"* without defining blocking, which is a second home for the rule
  and therefore a place for it to drift. No version bump: the record shape is untouched.
- **B** — the script, its smoke fixtures, the skill and agent text, the installer pin, CI, the
  docs, one ADR. The bulk. Cut **0.9.0** here: the record shape changes (`mode:`, `triggers:`).
- **C** — prose in two files, one ADR. Small, but it is the part whose behaviour only a real run
  shows: dogfood it on the next series here before it is documented for adopters.

Measure after B on twenty real commits: how many passes ran, how many rounds, and one thing no
number captures, whether the gate was run at all.

## A. The measurement

Bash, run in this session's scratchpad, not in the repo; reproduce with the same sets.

```
DEC_PATH  (file names)  (^|/)(package\.json|package-lock\.json|yarn\.lock|pnpm-lock\.yaml|
                        pyproject\.toml|requirements[^/]*\.txt|uv\.lock|poetry\.lock|
                        Pipfile(\.lock)?|Cargo\.(toml|lock)|go\.(mod|sum)|[^/]*\.csproj|
                        Gemfile(\.lock)?|pom\.xml|build\.gradle[^/]*|composer\.json|
                        Dockerfile[^/]*|docker-compose[^/]*\.ya?ml|[^/]*\.tf|[^/]*\.bicep)$
                        |^\.github/workflows/|^\.claude/hooks/|^\.claude/settings\.json$
DEC_LINE  (added lines) ^\+\s*(import |from \S+ import |require\(|use [A-Za-z]|using [A-Za-z]|#include )
COMP_WORDS (added lines, -i)
   first_?name|last_?name|surname|e-?mail|phone|ip_?addr|device_?id|user_?agent|account_?id|
   latitude|longitude|date of birth|national[ _-]?id|passport|health|diagnos|biometric|
   fingerprint|ethnic|religio|sexual|inference|predict|ranking|classif|automated decision|
   openai|anthropic|embedding|analytics|telemetry|webhook|third[ -]party|social scoring|
   emotion recognition|subliminal
BUS_WORDS (added lines, -i)
   socket|https?://|fetch\(|curl |wget |requests\.|urllib|axios|smtp|telemetry|analytics|
   tracking|upload
```

For each of `git rev-list --no-merges -n 40 main`: file list from `git show --name-only`, added
lines from `git show <sha> -- . ':(exclude).attest'` filtered to `^+` minus `^+++`. A commit
counts as a hit for a pass if any rule of that pass matched. With `.attest/` **included** in the
keyword scan the compliance count is 25, not 12: the ship records list the scan taxonomy
("special-category data · national identifiers · IP addresses"), which is why records are outputs
and not ground.
