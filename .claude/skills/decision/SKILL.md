---
name: decision
description: >-
  Appends one entry to DECISIONS.md, the append-only log of why a choice beat its alternatives,
  creating it on first use. Never invents an option or a reason: asks, or writes nothing.
disable-model-invocation: true
---

# /decision — why X beat Y (DECISIONS.md)

The argument `audit` is retired: say `/gate` checks for unrecorded decisions before a push,
and stop.

## Threshold

Record only a choice with discarded alternatives. A routine change is a commit; a boundary
belongs in `BUSINESS.md`'s Non-goals and an obligation in `COMPLIANCE.md`: say so instead of
writing.

## Refuse to fabricate

- Options and Why come only from this session or from the user.
- If alternatives were not weighed, ask, even when told to just record it.
- If there were none, the choice is below the threshold, so nothing is written.
- Anything inferred is marked `(inferred)`.

## Append

No `DECISIONS.md`, or only an older kit's template: create it as below. Otherwise append the
entry.

```markdown
# DECISIONS.md — <project>
Why each choice beat its alternatives. Append only; a reversal is a new entry.

## YYYY-MM-DD — <imperative title>
Supersedes: <the older entry's heading>
- **Context** — what forced a choice.
- **Options** — every alternative weighed.
- **Decision** — the choice, one line.
- **Why** — why it won and each alternative lost.
- **Consequences** — what it costs and enables.
```

Date it with `date +%F`; no `<…>` placeholder or HTML comment reaches the file. `Supersedes:`
is the only relation, kept only when this entry reverses an older one. Past entries are never
edited, not even to flip a status, whatever their heading shape.

## Close

Do not commit or touch any file but `DECISIONS.md`; quote the entry. A compliance-relevant
choice: say `COMPLIANCE.md` should name its heading.
