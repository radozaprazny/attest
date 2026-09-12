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
argument-hint: "[audit]"
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
- **The next id comes from every ref, not from your checkout** (attest ADR-0063). Two sessions
  on one repository, or a session and a branch someone else is pushing to, otherwise take the
  same number, and the collision surfaces only at the merge — by which time both entries are
  written, cited and pushed:

  ```sh
  LOG=DECISIONS.md                      # attest's own log is docs/attest-decisions.md
  git fetch --all --quiet 2>/dev/null   # a ref you have not fetched cannot be seen
  git for-each-ref --format='%(refname)' refs/heads refs/remotes \
    | xargs -I{} git grep -h -oE '^## ADR-[0-9]{4}' {} -- "$LOG" 2>/dev/null \
    | sort -u | tail -1
  ```

  Take the next number above what that prints. If two sessions both start before either has
  pushed, nothing local can see the clash and it lands at the merge: then **the branch that
  merges second renumbers**, and when you choose the order, merge the branch with more citations
  to its own ids first — renumbering is a mechanical `sed` over ids, so the cheaper side is the
  one with fewer of them. That renumber is the one edit of a pushed entry this log sanctions,
  and it changes ids only: a duplicate id breaks every citation in the log, which is worse than
  the exception.
- **Append-only, forward-only:** past entries are **immutable**. To reverse `ADR-0007`, append
  a **new** entry carrying a `Supersedes: ADR-0007` line under its title. The **only** permitted
  touch to an old entry is flipping its `Status` from `Accepted` to `Superseded by ADR-000M` —
  **never** rewrite its rationale.
- **"Past" starts at the push, not the commit** (attest ADR-0057): an entry is immutable once
  the commit carrying it has left the machine. Until then it is a draft — correct it in place,
  which is what the commit-time gate is *for*. It is the same boundary the ship gate defends,
  and it is checkable from the checkout, which "once the branch merges" is not.
- **Five relations, in two kinds, all of them fields of the *new* entry**, so none of them costs
  an exception to the rule above. **They change how far the older entry reaches:**
  `Supersedes: ADR-N` · `Supersedes in part: ADR-N` · `Narrows: ADR-N`. Only `Supersedes` earns
  the `Status` flip. **`Narrows` is the one to reach for when an entry's reasoning was right and
  its wording too broad** — the decision still stands and its scope is smaller than its text
  claims. The alternative people reach for instead is editing the old wording, which is the one
  thing the log cannot allow. **They only point:** `Extends: ADR-N` (this builds on that) ·
  `Relates to: ADR-N` (read that alongside this) — neither says anything about the older
  decision, so neither is a softer `Narrows`: using one where the scope really did shrink hides
  the narrowing. All five share a limit worth knowing: the field is on the **new** entry, so
  landing on the old one shows nothing — finding a relation means searching the log for that id.

## Two modes

> **A `DECISIONS.md` with no real entries — the shipped template's header and commented
> example only — counts as empty.** The kit ships it as a skeleton: the entry shape lives in
> an HTML comment, never as a visible entry. The first real entry is `ADR-0001`; never treat
> the commented example as prior state, and if the file is absent, create it (header rules
> included) before appending.

### Mode 1 — record (a decision was just made)

1. **Confirm it clears the threshold** above. If it is really a non-goal / a rule / an
   obligation, route it to the right doc instead and say so.
2. **Read `DECISIONS.md`** to match the house tone, and take the next `ADR-NNNN` id from
   **every ref** with the command above — never from this checkout alone (an empty template has
   no entries — start at `ADR-0001`).
3. **Append one entry** with the five fields. Capture the **Options** and **Why** honestly —
   the discarded alternatives are the point. If the decision is compliance-relevant, note the
   regulatory consequence in `COMPLIANCE.md` and cross-reference this ADR id (record the fact
   once).
4. If this decision **reverses** an earlier one, append with `Supersedes: ADR-000N` and flip
   that entry's `Status` line only.

### Mode 2 — `audit` (decisions made in code but never recorded)

Invoked as **`/decision audit`**. Read-only — it **reports**, it does not write entries. It
**owns** the "undocumented decision" finding, so a new dependency is flagged here and not by
`/business audit`, whose ground is non-goals and scope — one hunk is flagged once.

**The one exception is the `/decision` ↔ `/compliance` edge** (`_shared/audit-ladder.md`): a
choice that lands on **regulated ground** — personal data, a model or automated decision, a
new data source/transfer, an Art 5 practice — belongs to `/compliance audit`, which names the
missing ADR inside its own finding. Everything else that is a decision is yours.

**Unless `/compliance` is not installed** (`.claude/skills/compliance/` absent — the project
opted out, attest ADR-0030). Then that ground is **re-assigned** by the ladder's table rather
than dropped, and its first row is yours: a regulated-ground hunk with a **choice** behind it
comes back to you (the rest goes to `/audit-history` if it is bytes, otherwise to `/business
audit`). **Take the severity from the ladder, not from your rung list below** — its floor is
absolute: special-category or national-ID personal data, or an Art 5 practice, is a **blocker**
even when it reaches you as an inherited choice. Report yours once, with a clause naming what
it would have been — *"regulated ground; /compliance
is not installed in this project"*. Deferring to an audit that does not exist is how a finding
disappears, and the contract forbids silence, not just double-reporting.

1. **Read `DECISIONS.md`** — what has already been recorded (respect supersede chains; the
   shipped template's commented example is not a recorded decision).
2. **Survey reality** — `git log` / recent commits, the working diff, and especially the
   **dependency manifest** and **structural changes**: a newly added or swapped dependency, a
   new architectural pattern or protocol, a notable new threshold/default.
3. **Match against the log** — for each decision visible in the code that clears the threshold
   but has **no** entry, that is a finding. A choice already recorded (even if later
   superseded) is **not** a finding.
4. **Return a short verdict** (shared audit ladder — see `.claude/skills/_shared/audit-ladder.md`). For each finding: a
   one-line description, **evidence** (file / commit / diff hunk), and a severity —
   - **blocker** — a decision that contradicts a recorded ADR or a stated rule;
   - **major** — a threshold-clearing choice with no entry;
   - **minor** — a recorded entry gone stale, or a missing cross-reference.
   End with a recommended `DECISIONS.md` entry (title + the gap it fills) — but **do not**
   write it (recording is a human call, Mode 1). If nothing is undocumented, say so in one
   line. **The audit writes nothing.**

## After editing

- **Record mode:** append only — never edit or delete a past entry (except the sanctioned
  one-line `Status` flip). Do **not** commit automatically — leave the commit to me (`docs:`).
  Change nothing other than `DECISIONS.md`. Briefly summarize the entry you appended.
- **Audit mode:** read-only — report the verdict, change nothing at all.
