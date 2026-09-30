# Simplification plan — attest v0.9

**Status: proposal. Nothing is implemented.** This file exists to be chosen from. Every block
in PART 4 is independent unless its *Depends on* line says otherwise; PART 5 is one choice;
PART 9 is where the answer goes.

---

## PART 1 — Measured baseline

| What | Measured |
|---|---|
| Prompt text loaded by one `/gate full` | **~30 000 tokens** — skill text *only*, before the diff, before the documents each subagent reads, before reasoning or output |
| `gate/SKILL.md` into the main context | 4 101 words ≈ 5 700 tok |
| Shipped kit prose (skills + agents) | 17 641 words |
| `README.md` + `GUIDE.md` before anything runs | 10 728 words |
| Own ADRs, for 119 commits | 69 entries, 31 760 words |
| `.attest/` records | 38 files |

Reproduce:

```sh
wc -w .claude/skills/*/SKILL.md .claude/skills/_shared/*.md .claude/agents/*.md
grep -c '^## ADR-' docs/attest-decisions.md
ls .attest | wc -l
```

The 30k figure counts `gate/SKILL.md` once, the ladder three times (one per `doc-auditor`),
each audit skill once, and the two agent files. A real `/gate full` lands at **80–150k tokens
per run** once the diff, the control documents and four reasoning passes are added.

---

## PART 2 — Diagnosis: three costs that are usually confused for one

### 2.1 The onboarding ceremony is not load-bearing

Of `BUSINESS.md`'s seven sections, the audits read **three**: Non-goals, Scope, Archetype.

```sh
grep -rn -i "target user\|What success looks like\|^## Value" .claude/
```

returns hits only inside `business/SKILL.md`'s *writing* template and question bank — never in
an audit path. **`Target user`, `Value` and `What success looks like` are consumed by nothing
in the kit.** They are the sections that cost the longest to answer, and they buy no mechanism.

The archetype has exactly two jobs: pick the question set, and trigger the compliance call. That
is a six-row table and a question bank standing in for one yes/no question (*personal data or
automated decisions?*).

### 2.2 Judgment runs at both cadences

The expensive, non-deterministic thing runs on **every commit** (four subagents), and the cheap,
deterministic thing (`gitleaks`-class scanning) runs **never** — `README.md` delegates it to the
user in prose. That is the inverse of every tool that gets adopted.

Second multiplier: the skill files are mostly *rationale*. `gate/SKILL.md` spends its length on
"three details in that first block are each a bug someone hit", ADR-0066/0067/0068 citations, and
the reasoning behind each shell flag. A runtime prompt pays for that on every invocation and does
not need it to execute.

### 2.3 The conceptual surface is a consequence, not a cause

Five documents · six skills · three hooks · two agents · a shared ladder · an ownership contract ·
a six-label archetype taxonomy · three severity rungs · three gate modes · a trigger stage · a
record-naming convention · five ADR link types.

Most of that machinery exists **to serve the four-pass design**. The ownership contract, the
dedup merge, the `trigger-<pass>.txt` files, three copies of the ladder, and `triggers.sh` itself
are all answers to *"four passes are looking at one hunk"*. Collapse the passes and the
answers have no question.

---

## PART 3 — What to take from gitleaks

| gitleaks | attest today |
|---|---|
| ~170 rules embedded in the binary; works at second zero | needs a declaration before it says anything useful |
| config is written **reactively**, to allowlist a false positive | config is written **up front**, as a prerequisite |
| deterministic regex + entropy; exit code 1 | a model reading a diff |
| runs in CI with no agent | requires Claude Code |
| `--baseline-path` accepts the existing mess | first run reports all pre-existing drift |
| one integration point (pre-commit / CI step) | six slash commands and three hooks |

**The honest caveat.** gitleaks needs no declaration because its rules are *universal*.
Non-goals are per-project by definition, so attest cannot be zero-config. The transferable
version is not "no config" — it is **a default that works before any config exists**. gitleaks
ships 170 built-in rules; attest ships zero.

---

## PART 4 — The blocks (pick any combination)

### Block A — invert the two cadences

**What.** Commit-time becomes pure shell: `gitleaks` when it is on `PATH`, plus deterministic
greps (new top-level directory, new dependency with no ADR, `BUSINESS.md` still a skeleton,
record freshness). Exit code. Zero tokens. The single model pass moves to push time, once per
branch.

**Removes.** `triggers.sh` and the whole light/full trigger distinction; the "which passes did
this run skip" ambiguity the `mode:`/`triggers:` record lines exist to resolve.

**Gains.** The commit gate becomes free, so it stops being a thing you decide whether to afford.
And it **runs in CI without an agent** — which attest cannot do today at all.

**Costs.** Judgment feedback arrives at push, on a larger diff, not at commit. Someone who
commits twenty times and pushes once sees drift later. Mitigation: keep `/gate deep` as an
on-demand command for when you want it early.

**Note on the earlier rejection.** `docs/attest-progress.md:170` rejected a mandatory
`gitleaks` run as colliding with *"the kit ships no tool and edits nothing"*. That non-goal is
about **editing your code** — a read-only scanner edits nothing, and *calling* a binary the user
already installed does not ship one. The shape that respects both: run it if present, record
`- scanner: gitleaks <version> <verdict>`, say so in the record when absent. That is the
"optional `- scanner:` line" the same note calls the version worth having.

**Effort:** medium — one new shell script, `gate/SKILL.md` rewritten, `triggers.sh` deleted.

---

### Block B — four passes → one auditor

**What.** One read-only subagent with a short checklist covering all four grounds (non-goals /
unrecorded decision / regulated ground / code quality), instead of `reviewer` + three
`doc-auditor`s.

**Removes.** The ownership contract, the dedup merge step, the per-pass trigger files, three
loads of the ladder, and the three-way *skipped / degraded / not installed* vocabulary.
The duplicate-finding problem disappears **by construction** rather than by a merge rule.

**Preserves.** Read-only *by capability* — it is still an agent without `Bash`, `Edit` or
`Write`. `METHOD.md` property 3 is untouched.

**Costs.** Parallelism (seconds of wall-clock). One agent holding four checklists may cover each
dimension less deeply on a very large diff than four dedicated passes would. Mitigation: let
`full` mode still fan out, or split only when the diff exceeds a size threshold.

**Effort:** medium. **Depends on:** nothing, but pairs naturally with A.

---

### Block C — `/business` down to three questions

**What.** Drop `Target user`, `Value`, `What success looks like` (§2.1: read by nothing) and the
six-row archetype table with its question bank. The file becomes:

```markdown
## Purpose
<one sentence>

## Non-goals
- <what this must never do>

## Compliance
<yes/no + one clause why>
```

**Costs.** `BUSINESS.md` stops being a document a human stakeholder reads for orientation. If
that is a real use, keep those sections as **optional free prose that no audit reads**, and stop
asking for them during bootstrap — the cost was the interrogation, not the bytes.

**Impact:** hours → about two minutes. This is the block that answers the original complaint
directly.

**Effort:** small — one skill rewritten, one template shortened.

---

### Block D — default non-goals

**What.** `/gate` works on day zero with **no document at all**, against a built-in generic set
(no secrets in code, no PII in logs, no telemetry without a recorded decision, no new dependency
without one). Project-specific non-goals get written when the default is wrong — and the gate
offers the one-line append at the moment it fires, the way a gitleaks allowlist grows from
friction.

**Why it matters.** `METHOD.md` property 8 already promises "adopt on a gradient"; today the
onboarding contradicts it. This closes that gap.

**Costs.** False positives where the default does not apply — a telemetry SDK trips "no
telemetry" on its first run. That is the gitleaks failure mode too, and it has the gitleaks
answer: the first false positive writes the allowlist line, and the cost is paid once.

**Effort:** small–medium. **Depends on:** C (same file, same skill).

---

### Block E — rationale out of the runtime prompts

**What.** `SKILL.md` becomes instructions only. Every *why* — the bug behind a shell flag, the
ADR citation, the design defence — **moves** to `GUIDE.md` / `docs/attest-decisions.md`. It is
not deleted.

**Targets:** `gate` ≤ 600 w (from 4 101) · `business` ≤ 400 (from 3 122) · `decision` ≤ 300
(from 1 960) · `audit-history` ≤ 300 (from 1 709) · `compliance` ≤ 400 (from 2 096).

**Impact:** 4–5× fewer tokens on every run, independent of every other block. Highest ratio of
benefit to risk in this plan.

**Costs.** None functional. The risk is that reasoning gets dropped instead of moved — so do it
as a move, and let `GUIDE.md` grow.

**Effort:** small per file, mechanical. **Depends on:** nothing. Can ship first, alone.

---

### Block F — the small ones

- **`.attest/log.md`** — one append-only file, one line per run
  (`2026-09-13T20:43Z gate 448b57b ✅ 0b/0M/3m`), instead of 38 files. Removes sha-parsing from
  filenames and makes ADR-0032 (name order ≠ run order) moot.
  **Real trade-off:** 38 separate files never conflict on merge; one appended file does. If
  parallel branches are normal here, keep per-file.
- **`/decision` trim** — five link types (`Supersedes` / `Narrows` / `Widens` / `Extends` /
  `Relates to`) is a taxonomy; real ADR practice uses one. Keep `Supersedes`, drop the rest.
- **README cut** — 2 538 words is the first thing anyone sees. Target ≤ 600: what it is, install,
  the loop, one honest limits paragraph. The rest is already `GUIDE.md`'s job.

**Effort:** small each, independent.

---

## PART 5 — Compatibility (pick exactly one)

- **C1 — clean break, v0.9.** No migration paths, no aliases. `CHANGELOG`/`README` state what
  changed and how to move. *Rationale: with ~0 external installs, fallback code is just more of
  the complexity being removed.*
- **C2 — deprecate in place.** Old `/business`, `/audit-history` and the four-pass `/gate` stay
  beside the new ones, marked deprecated, removed a version later. *Cost: for one release the
  kit is strictly larger than it is today.*
- **C3 — prototype beside.** Build the simplified kit under `next/`, delete nothing, compare the
  two shapes before anything is swapped. *Cost: slowest; risk that both live on.*

---

## PART 6 — Suggested combinations

| | Blocks | Effect |
|---|---|---|
| **Minimal** — one sitting | **E + C** | ~5× fewer tokens per run, onboarding hours → minutes. No architecture moves. |
| **Recommended** | **A + B + C + E** | The four costs in PART 2 all addressed; the surface in §2.3 mostly evaporates as a side effect. |
| **Full** | **A–F** | The target shape in PART 7. |

---

## PART 7 — Target shape (after A–F)

```
CLAUDE.md                  # your rules
ATTEST.md                  # ~20 lines: purpose + non-goals + compliance yes/no
.attest/log.md             # one line per run
scripts/attest.sh          # deterministic core: gitleaks + greps, exit code, runs in CI
.claude/
  skills/gate/SKILL.md     # ~500 words, one pass
  skills/checkpoint/       # optional
  hooks/ship_guard.sh
  agents/auditor.md
```

5 documents → 2 · 6 skills → 2–3 · 4 subagents → 1 · ~30k prompt tokens → ~5k ·
onboarding hours → minutes.

---

## PART 8 — One thing worth naming

69 ADRs and 31 760 words of recorded decisions for 119 commits is itself a signal. The kit is
applied to itself at a fidelity no adopter will ever match — and because this repository is also
the advertisement, **what a newcomer sees first *is* the complexity being described here.** Part
of simplifying is deciding to stop documenting attest and start using it. That is a choice about
how the project is run, not a code change, and no block above makes it.

---

## PART 9 — Decision

```
Blocks:        [ ] A   [ ] B   [ ] C   [ ] D   [ ] E   [ ] F
Compatibility: [ ] C1  [ ] C2  [ ] C3
Order:
Notes:
```
