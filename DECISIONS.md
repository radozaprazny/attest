# DECISIONS.md — decision log (ADR-lite, append-only)

> **Why we chose X over Y.** Append-only — never edit or delete a past entry (except flipping
> its `Status` line when superseded); to reverse one, **append** a new entry that supersedes it. why-it-exists → `BUSINESS.md` · rules →
> `CLAUDE.md` · status → `PROGRESS.md` · posture → `COMPLIANCE.md`. (full table: GUIDE PART 1)

<!--
How to use this file:
  - Run `/decision` to record a decision just made. Run `/decision audit` to find decisions
    made in code but never written here (read-only).
  - Record ONLY choices with lasting rationale AND discarded alternatives — a dependency, an
    architectural pattern, a threshold. A routine change is a commit, not an ADR. The
    Options/Why lines are the reason this file exists (git does not preserve the roads not taken).
  - If you catch yourself writing: a boundary the project will never cross → that is a
    Non-goal (BUSINESS.md); a rule that binds all future code → CLAUDE.md; a standing
    regulatory obligation → COMPLIANCE.md (cross-reference the ADR by id).
  - APPEND-ONLY, forward-only: entries are immutable. To reverse ADR-0007, append a new entry
    carrying `Supersedes: ADR-0007`. The ONLY permitted touch to an old entry is flipping its
    Status line (Accepted → Superseded by ADR-000M) — never rewrite its rationale. A
    superseded entry is NOT an anti-duplication violation.
  - IDs are sequential, zero-padded (ADR-0001, ADR-0002, …). Dates ISO YYYY-MM-DD.
-->

<!-- Your first real entry goes here, with this shape (IDs start at ADR-0001; the
append-only rule above applies to real entries — this comment is not one):

## ADR-0001 — <short imperative title> · YYYY-MM-DD · Accepted

- **Context** — the forces: what constraint made this a real choice (1–2 sentences).
- **Options** — the alternatives weighed: A / B / C.
- **Decision** — the choice, one line.
- **Why** — the rationale, and why the discarded options lost.
- **Consequences** — trade-offs accepted, follow-ups, what it now costs or enables.

(A superseding entry adds one line under the title: `Supersedes: ADR-0001`.)
-->
