# Shared audit ladder + ownership contract

**The canonical source for every audit's severity vocabulary and its ground.** Every audit
skill reads this file at runtime — `/business audit`, `/decision audit`, `/audit-history`,
`/compliance audit` where it is installed, and `/gate`, which merges the commit-time passes
under this contract — plus both subagents: `reviewer` and `doc-auditor` (the one that executes
the gate's document audits). It lives here, next to its consumers, so that it installs with
them and is never absent when an audit runs.

> Not a skill — this directory has no `SKILL.md` and Claude Code ignores it for skill
> discovery. It is reference material the skills `Read` when they need it.

> **`attest ADR-NNNN` means attest's own decision log**, at
> `github.com/radozaprazny/attest` (`docs/attest-decisions.md`) — the kit does not install it.
> Those citations are provenance for a rule, never a file to look up in *your* repo; your own
> log is `DECISIONS.md` and its numbering is unrelated.

Kit version: 0.6.0 (the kit's one version marker — it lives in this file because the ladder
installs with every audit consumer, so the version travels with the kit and can never desync
from the contract; attest ADR-0018. `install.sh` prints it; a `/gate` run record cites it.
Bump it when cutting a release.)

---

## The ladder

Three rungs, one vocabulary, no per-skill variants — write the bare word (attest ADR-0029):

| Rung | Meaning |
|------|---------|
| **blocker** | Ship-stopping. |
| **major** | Real, and the change should not go in as it stands. |
| **minor** | Real but advisory. |

Every finding already names the audit that owns it, so a flavoured middle rung ("major (scope
creep)") repeated what the owner line said and cost every reader a second vocabulary. Say what
the finding *is* in its one-line description instead.

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
| `/business audit` | Non-goal violations and scope creep — **only**. Fires on nothing else, *except* the last row of the re-assignment table below, and only while `/compliance` is absent (attest ADR-0030). |
| `/compliance audit` | Regulated ground — **only**: a new personal-data field, a new model or automated decision, a new data source/transfer, an Art 5 practice. *(Opt-in: this skill is not installed in every project — attest ADR-0030.)* |
| `/audit-history` | What the repo **ships** — bytes in the working tree or in git history. |

**When `/compliance` is not installed, its ground is re-assigned — never dropped.**
`.claude/skills/compliance/` absent means the project declared itself out of regulated scope.
Its ground still exists; only its owner does not. Re-assign each hunk by this order, and the
order is **total** — every item of `/compliance`'s ground list has an owner in it, or this
contract has a hole:

| The hunk is… | Falls to |
|---|---|
| a **choice** with a discarded alternative (an SDK, a model client, a transfer target) | `/decision audit` |
| **bytes** already in the tree or the history | `/audit-history` |
| **anything else on regulated ground** — a bare new personal-data field, a model wired in with no alternative to name, a new source with no choice behind it | `/business audit` |

The last row is a deliberate carve-out from *"non-goals and scope — only"*: what is missing in
that case **is a declaration**, and `/business` is the pass that reads the declaration. It is
the only thing that may make `/business audit` fire on something other than a non-goal, it
applies **only** while `/compliance` is absent, and it is written into that skill's audit mode
so the gate delivers it (attest ADR-0030).

Whichever owner takes it, the finding carries one clause naming what it would have been:
*"regulated ground; /compliance is not installed in this project."* One finding, never two,
and never silence.

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
  data source/transfer, an Art 5 practice) **and `/compliance` is installed** → **`/compliance
  audit` owns it**. Regulated ground outranks the record-keeping finding, because the
  consequence of missing it is larger. Name the missing ADR in one clause of the same finding;
  do not file a second one.
- It touches regulated ground and **`/compliance` is not installed** → **`/decision audit` owns
  it** under the fallback above, and its finding carries the clause naming what it would have
  been. This is the one case where the edge does not resolve to `/compliance` (attest ADR-0030).
- It does **not** touch regulated ground → **`/decision audit` owns it**, alone.

Neither audit may defer to the other on this edge: exactly one of the three conditions holds, so
exactly one owner always exists (attest ADR-0023, ADR-0030). "Defer" is never the same as
"drop" — an unowned hunk is a bug in this contract, not a silent pass.

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

**Every audit is read-only on your work** — it changes no control document and no code. Two
sanctioned artifacts exist, both of them records *that* a gate ran and what it returned:
`/gate` appends a dated run record under `.attest/` (attest ADR-0016), and `/audit-history`
appends one of its own — `ship-…-<short-HEAD-sha>.md` — which the `PreToolUse` ship guard
reads before anything leaves the machine (attest ADR-0028, narrowed by ADR-0037: the guard reads
the record's `HEAD:` and `findings: 0 blocker` lines, so passing means *audited **and** clean*). `.attest/` therefore holds
append-only records plus an ignored `.attest/tmp/` for anything transient: the gate's
fallback material, which it deletes when it is done, and the ship guard's decision trace,
which it keeps (attest ADR-0026, ADR-0034). Whatever writes there removes its **own files**,
never the directory. **Two mutations of a record itself are sanctioned, both named, and nothing
else is:** redacting personal data a record should never have carried, leaving a visible mark
and saying what went, when and under which entry — **the finding, its counts and its verdict are
never touched, and it sanctions one mutation of one record, not a licence to tidy `.attest/`**
(ADR-0040); and `template-cleanup.sh` sweeping attest's own records out of a repo generated from
the template button (ADR-0041) — **the sweep** never touches a record in the project that
wrote it, while the redaction is precisely a project editing one of its own, once, in the open.
The document audits
inside the gate still write nothing at all: they have no `Write` tool (attest ADR-0017).

Do not inflate a minor into a blocker to look thorough, and do not invent findings to avoid
returning an empty verdict.
