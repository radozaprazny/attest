# DECISIONS.md — decision log (ADR-lite, append-only)

> **Why we chose X over Y.** Append-only — never edit or delete a past entry (except flipping
> its `Status` line when superseded); to reverse one, **append** a new entry that supersedes it.
>
> **Router (this doc owns decisions only):** why-it-exists → `BUSINESS.md` · rules →
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
    carrying `Supersedes: ADR-0007`. Never rewrite an old entry's rationale. Exactly two touches
    are permitted, and nothing else is: flipping its Status line (Accepted → Superseded by
    ADR-000M), and the id-only renumber below when two branches took the same number. A
    superseded entry is NOT an anti-duplication violation.
  - An entry becomes IMMUTABLE when the commit carrying it is PUSHED — not when written, not
    when committed. Before that it is a draft: fix it in place. After it has left the machine,
    only a new entry can correct it. Same boundary the ship gate defends, same reason: what has
    left cannot be recalled from whoever already read it.
  - SIX relations may sit under a new entry's title, in two kinds, and all six are fields of
    the NEW entry, touching nothing older.
    They change how far the older entry reaches: `Supersedes: ADR-N` (the old decision is
    reversed — this one alone earns the Status flip) · `Supersedes in part: ADR-N` (half of it
    is reversed) · `Narrows: ADR-N` (the old decision still stands, but its scope turns out
    smaller than its text says) · `Widens: ADR-N` (it still stands, and its ground turns out
    larger — the mirror of Narrows). Reach for `Narrows` instead of editing an entry whose
    reasoning was right and whose wording was too broad.
    They only point, and say nothing about the older decision: `Extends: ADR-N` (this builds on
    that) · `Relates to: ADR-N` (read that alongside this). Neither is a softer `Narrows` —
    using one where the scope really did shrink hides the narrowing from every later reader.
  - IDs are sequential, zero-padded (ADR-0001, ADR-0002, …). Dates ISO YYYY-MM-DD.
  - Take the next id from EVERY ref, not from your checkout — another session or an open branch
    may already hold the number. `/decision` has the command. If two branches took the same id
    anyway, the one that merges SECOND renumbers; that is the one edit of a pushed entry this
    log sanctions, because a duplicate id breaks every citation.
  - One session at a time in these documents. Two agents editing the same control document do
    not see each other, and nothing here can tell you they were both there.
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
