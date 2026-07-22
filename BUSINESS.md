# BUSINESS.md — business context

> Why the project exists (purpose, archetype, non-goals). Changes rarely. status →
> `PROGRESS.md` · rules → `CLAUDE.md` · why-we-chose-X → `DECISIONS.md` · posture →
> `COMPLIANCE.md`. (full table: GUIDE PART 1)

<!--
How to use this file:
  - Run `/business` to bootstrap this file (it decides the project's archetype, explores
    the repo, asks what the code cannot show, then writes) or to update it against the
    current state of the project. Run `/business audit` to check reality against the
    non-goals/scope below without changing the file.
  - Anti-duplication: no status here ("done", "12 tests green" -> PROGRESS.md), no
    technical rules (language version, commit style -> CLAUDE.md).
  - The Non-goals section is the valuable one — it is the boundary you check new ideas
    against so scope does not creep.
-->

## Purpose

<what it is and what it does, in 2–4 sentences>

## Archetype

**<library | cli | service | data-pipeline | ai-system | local-app>** — <a few words on why>

> The archetype is only a **trigger** `/compliance` reads: it signals the EU AI Act *may*
> apply and prompts the real classification — it does **not** determine the legal risk tier,
> which `/compliance` sets in `COMPLIANCE.md` from the intended purpose and the Annexes.

## Target user

<who it is for>

## Value

<why it is worth it — speed, privacy, accuracy, cost, ...>

## Scope (in-scope)

- <what the project covers>
- Later: <planned, but not yet>

## Non-goals

- <what it deliberately does NOT cover — the project's boundaries>

## What success looks like

- <what done / good looks like>
