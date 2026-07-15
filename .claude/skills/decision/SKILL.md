---
name: decision
description: >-
  Records and audits DECISIONS.md — the project's append-only ADR-lite decision log (why we
  chose X over Y, the alternatives weighed, the trade-offs accepted). Two modes: record
  (append one entry for a decision just made) and `audit` (find decisions made in code but
  never written down — a new dependency, a swapped library, a new architectural pattern;
  read-only). Record ONLY choices with lasting rationale and discarded alternatives — a
  routine change is a git commit, not an ADR. Generic — usable in any project. Do NOT use it
  for live status (PROGRESS.md), rules/conventions (CLAUDE.md), product non-goals
  (BUSINESS.md) or regulatory obligations (COMPLIANCE.md).
disable-model-invocation: true
---

# /decision — why we chose X over Y (DECISIONS.md)

This skill maintains **`DECISIONS.md`** — an **append-only, ADR-lite** log of the project's
notable decisions. Its reason to exist is the **roads not taken**: the alternatives that were
weighed and why they lost — which a git commit message does not preserve queryably.

The skill is **generic** — work with what you actually find in the repo, and assume nothing
about the specific project.

## The control documents — keep them separate

**Anti-duplication:** status → `PROGRESS.md` · rules → `CLAUDE.md` · why-it-exists →
`BUSINESS.md` · why-we-chose-X-over-Y → `DECISIONS.md` · under-what-rules → `COMPLIANCE.md`.
Write each fact in exactly one place. (full table: GUIDE PART 1)

The three "why" docs are the collision point — fence them:

- **BUSINESS.md** = *why the project exists* — a boundary it will never cross is a **non-goal**.
- **DECISIONS.md** = *why this choice beat the alternative* — a technical how/which.
- **COMPLIANCE.md** = *which external rule forces it* — a standing regulatory obligation.

> If you catch yourself recording, as a decision, a boundary the project will never cross →
> that is a Non-goal (`BUSINESS.md`); a rule that binds all future code → `CLAUDE.md`; a
> standing regulatory obligation → `COMPLIANCE.md` (record the *choice* here, cross-reference
> the obligation there by ADR id).

## What rises to a decision (the threshold)

Record **only** a choice with **lasting rationale AND discarded alternatives** — for example:

- a **dependency** or a **swapped library** (why this one over the obvious other);
- an **architectural pattern** (a boundary, a data model, a protocol);
- a notable **threshold / default** (a timeout, a retention window, a limit).

A routine change — a bug fix, a rename, a tweak with no alternative worth naming — is a **git
commit, not an ADR**. The test: *would someone later ask "why did we do it this way and not
the other?"* If yes, record it; if no, leave it to the commit.

## The entry format (append-only, forward-only)

`DECISIONS.md` opens with the rules; each entry is five terse fields:

```
## ADR-0001 — <short imperative title> · YYYY-MM-DD · Accepted
- **Context** — the forces: what constraint made this a real choice (1–2 sentences).
- **Options** — the alternatives weighed: A / B / C.
- **Decision** — the choice, one line.
- **Why** — the rationale, and why the discarded options lost.
- **Consequences** — trade-offs accepted, follow-ups, what it now costs or enables.
```

- **IDs** are sequential, zero-padded (`ADR-0001`, `ADR-0002`, …). **Dates** ISO `YYYY-MM-DD`.
- **Append-only, forward-only:** past entries are **immutable**. To reverse `ADR-0007`, append
  a **new** entry carrying a `Supersedes: ADR-0007` line under its title. The **only** permitted
  touch to an old entry is flipping its `Status` from `Accepted` to `Superseded by ADR-000M` —
  **never** rewrite its rationale.

## Two modes

### Mode 1 — record (a decision was just made)

1. **Confirm it clears the threshold** above. If it is really a non-goal / a rule / an
   obligation, route it to the right doc instead and say so.
2. **Read `DECISIONS.md`** to find the next `ADR-NNNN` id and match the house tone.
3. **Append one entry** with the five fields. Capture the **Options** and **Why** honestly —
   the discarded alternatives are the point. If the decision is compliance-relevant, note the
   regulatory consequence in `COMPLIANCE.md` and cross-reference this ADR id (record the fact
   once).
4. If this decision **reverses** an earlier one, append with `Supersedes: ADR-000N` and flip
   that entry's `Status` line only.

### Mode 2 — `audit` (decisions made in code but never recorded)

Invoked as **`/decision audit`**. Read-only — it **reports**, it does not write entries. It
**owns** the "undocumented decision" finding, so a new dependency is flagged here, not by
`/business audit` (non-goal/scope) or `/compliance audit` (regulated ground) — one hunk is
flagged once.

1. **Read `DECISIONS.md`** — what has already been recorded (respect supersede chains).
2. **Survey reality** — `git log` / recent commits, the working diff, and especially the
   **dependency manifest** and **structural changes**: a newly added or swapped dependency, a
   new architectural pattern or protocol, a notable new threshold/default.
3. **Match against the log** — for each decision visible in the code that clears the threshold
   but has **no** entry, that is a finding. A choice already recorded (even if later
   superseded) is **not** a finding.
4. **Return a short verdict** (shared audit ladder — see GUIDE PART 3). For each finding: a
   one-line description, **evidence** (file / commit / diff hunk), and a severity —
   - **blocker** — a decision that contradicts a recorded ADR or a stated rule;
   - **major (undocumented decision)** — a threshold-clearing choice with no entry;
   - **minor** — a recorded entry gone stale, or a missing cross-reference.
   End with a recommended `DECISIONS.md` entry (title + the gap it fills) — but **do not**
   write it (recording is a human call, Mode 1). If nothing is undocumented, say so in one
   line. **The audit writes nothing.**

## After editing

- **Record mode:** append only — never edit or delete a past entry (except the sanctioned
  one-line `Status` flip). Do **not** commit automatically — leave the commit to me (`docs:`).
  Change nothing other than `DECISIONS.md`. Briefly summarize the entry you appended.
- **Audit mode:** read-only — report the verdict, change nothing at all.
