# Shared audit ladder + ownership contract

**The canonical source for every audit's severity vocabulary and its ground.** Five skills
read this file at runtime — `/business audit`, `/decision audit`, `/compliance audit`,
`/audit-history`, and `/gate`, which merges the commit-time
passes under this contract — plus both subagents: `reviewer` and `doc-auditor` (the one that
executes the gate's document audits). It lives here, next to its consumers, so that it
installs with them and is never absent when an audit runs.

> Not a skill — this directory has no `SKILL.md` and Claude Code ignores it for skill
> discovery. It is reference material the skills `Read` when they need it.

> **`attest ADR-NNNN` means attest's own decision log**, at
> `github.com/radozaprazny/attest` (`docs/attest-decisions.md`) — the kit does not install it.
> Those citations are provenance for a rule, never a file to look up in *your* repo; your own
> log is `DECISIONS.md` and its numbering is unrelated.

Kit version: 0.2.0 (the kit's one version marker — it lives in this file because the ladder
installs with every audit consumer, so the version travels with the kit and can never desync
from the contract; attest ADR-0018. `install.sh` prints it; a `/gate` run record cites it.
Bump it when cutting a release.)

---

## The ladder

Three rungs, shared by every audit, so they read as one family:

| Rung | Meaning |
|------|---------|
| **blocker** | Always the bare word — never aliased. Ship-stopping. |
| **major (domain alias)** | The middle rung, flavoured per skill (see below). |
| **minor** | Real but advisory. |

**Aliases — the middle rung only:**

| Skill | Middle rung |
|-------|-------------|
| `/business audit` | **major (scope creep)** |
| `/decision audit` | **major (undocumented decision)** |
| `/compliance audit` | **major (posture gap)** |
| `/audit-history` | **major (PII / client name)** |

**Always a blocker**, in any audit: a secret · special-category or national-ID personal data ·
a violated non-goal · a prohibited (EU AI Act Art 5) practice.

**Always minor:** metadata · large files · stale wording.

`nit` is **not** on this ladder. It survives only in the `reviewer` subagent, which reviews
*code* and so has legitimate cosmetic findings; a "does reality match the declaration" audit
does not. Stale wording that would once have been a nit is **minor**. (Attest ADR-0005.)

**A reviewer `nit` passing through `/gate`** keeps its rung — it is neither promoted to minor
nor dropped. Merged verdicts list nits last, under the reviewer's line, and the run record
counts them in their own column. Never let a nit change the verdict line: a gate whose only
findings are nits is ✅ *ready to commit* (attest ADR-0023).

---

## Ownership — one hunk is flagged once

The audits are designed to run **together** (that is `/gate`). Without an ownership rule a
single hunk — one new dependency — is simultaneously a scope question, an undocumented
decision and possibly regulated ground, so three audits would each report it and "one pass"
would read as noise. Each finding therefore has exactly **one** owner:

| Owner | Its ground |
|-------|-----------|
| `/decision audit` | A new dependency · a swapped library · a new pattern or protocol · a notable new threshold/default. |
| `/business audit` | Non-goal violations and scope creep — **only**. Fires on nothing else. |
| `/compliance audit` | Regulated ground — **only**: a new personal-data field, a new model or automated decision, a new data source/transfer, an Art 5 practice. |
| `/audit-history` | What the repo **ships** — bytes in the working tree or in git history. |

**If a finding is not yours, name the skill whose ground it is and move on.** Do not report it
yourself, even when you can see it clearly. The two edges where one hunk really can belong to
two owners are resolved below — those rules are the tiebreak, and they are what `/gate` merges
under. The `reviewer`'s own findings (plain code defects) have no row here: they are the
reviewer's by construction, and the contract only arbitrates between the audits.

### The `/decision` ↔ `/compliance` edge: the choice vs the ground it lands on

The contract's own motivating case — *one new dependency* — is also the collision it has to
settle: an analytics SDK or a model client is both an undocumented decision and regulated
ground, and both audits can see it.

- The hunk touches **regulated ground** (personal data, a model or automated decision, a new
  data source/transfer, an Art 5 practice) → **`/compliance audit` owns it**. Regulated ground
  outranks the record-keeping finding, because the consequence of missing it is larger. Name
  the missing ADR in one clause of the same finding; do not file a second one.
- It does **not** → **`/decision audit` owns it**, alone.

Neither audit may defer to the other on this edge: exactly one of the two conditions holds, so
exactly one owner exists (attest ADR-0023).

### The `/business` ↔ `/audit-history` edge: content vs behaviour

The sharpest collision, and the one a real dogfood actually hit (attest ADR-0004):

- Code that **does** something a non-goal forbids → `/business audit`.
  *Example: a non-goal says "no network access" and new code opens a socket. This is
  `/business`'s, even though it looks like an exfiltration risk.*
- **Bytes that must not leave** → `/audit-history`.
  *Example: a secret or personal data committed to the tree or history.*

If one change does **both** — adds forbidden behaviour **and** commits forbidden data — flag
only the **data** half and name `/business audit` for the rest.

---

## Output shape

Every audit returns the same shape:

1. **A one-line verdict.** If nothing fired, say so in one line and stop — a short clean audit
   is a correct result.
2. **Findings**, ordered by severity, each with:
   - a one-line description,
   - **evidence** — `file:line`, a commit, or a diff hunk; never a vague gesture,
   - a **severity** from the ladder above.
3. **A recommended update** — which document, roughly what — but **do not make it**. Recording
   is a separate, human-approved step (each skill's write mode).

**Every audit is read-only. The audit writes nothing** — no control document, no code. One
sanctioned artifact exists at the merge point only: `/gate` appends a dated **run record**
under `.attest/` (attest ADR-0016) — a log *that* the gate ran and what it returned, never a
document change. `.attest/` holds exactly two things: those append-only records, and — only
when a subagent cannot read the out-of-tree scratch — an ignored `.attest/tmp/` the gate
deletes when it is done (attest ADR-0026). The individual audits still write nothing at all.

Do not inflate a minor into a blocker to look thorough, and do not invent findings to avoid
returning an empty verdict.
