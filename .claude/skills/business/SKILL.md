---
name: business
description: >-
  Writes or updates BUSINESS.md: Purpose, Non-goals, Regulated. Reads the repo, then asks at
  most three questions in one message, each with a proposed answer; unknowns become Open:
  bullets. The session hook and /gate read the non-goals.
disable-model-invocation: true
---

# /business — why the project exists (BUSINESS.md)

The argument `audit` is retired: say `/gate` checks the non-goals before a push, and stop.

Only why the project exists goes here: status → `PROGRESS.md` · rules → `CLAUDE.md` · why X
over Y → `DECISIONS.md` · posture → `COMPLIANCE.md`.

## 1. Read, silently

Read the README, the manifest (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, …),
the top-level directories and `BUSINESS.md` if present. Narrate nothing.

## 2. Ask once

Send ONE message with at most three questions, each with its proposed answer filled in — from
the repo, or on an existing file from its current text — so a reply of "yes" or one
correction is enough:

1. **Purpose**: what it is and does, in 1–3 sentences.
2. **Non-goals**: 3–6 things it deliberately does not do, each drawn from the repo (a
   dependency it avoids, a boundary the README draws, a surface it lacks).
3. **Regulated**: yes or no. Does it process personal data, make automated decisions about
   people, or place an AI system on the market?

Never a second round.

## 3. Write

Whatever the reply leaves unknown becomes an `Open:` bullet (`- Open: who may call the API?`),
never a guess and never `<placeholder>` text.

No `BUSINESS.md`, or only the kit's old `<placeholder>` skeleton: write this, at most 20
lines, no HTML comments.

```markdown
# BUSINESS.md — <project>

## Purpose
<1–3 sentences>

## Non-goals
- <one boundary per bullet>

## Regulated
<Yes | No> — <one clause: personal data, automated decisions about people, or an AI system placed on the market>
```

An existing file: replace the bodies of `## Purpose`, `## Non-goals` and `## Regulated` in
place (add `## Regulated` after Non-goals if missing) and leave every other heading and line
exactly as it is, so an older seven-section file keeps working.

## 4. Close

- Regulated **no**: the clause says why ("No — it stores nothing about people").
- Regulated **yes**: end your reply with "run /compliance".
- Do not commit. Say which sections changed, and touch no file but `BUSINESS.md`.
