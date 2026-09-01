---
name: checkpoint
description: >-
  Captures the current state of work into PROGRESS.md before /clear or /compact —
  token/context hygiene, so nothing is lost across the context boundary. Derives
  state from the git log, git status and work in progress, updates the
  Done/Next/Notes sections (briefly — it is a thread-carrier) and advises whether
  /clear (between blocks) or /compact (mid-task) fits better. Generic — usable in
  any project. Do NOT write rules here (they belong in CLAUDE.md) or business
  context (that belongs in BUSINESS.md).
disable-model-invocation: true
---

# /checkpoint — token/context hygiene (PROGRESS.md)

This skill captures the **current state of work** into `PROGRESS.md` before the context is
discarded (`/clear`) or compressed (`/compact`). The goal: **nothing is lost across the
context boundary** — `PROGRESS.md` is the thread-carrier that hands the thread to the next
session.

The skill is **generic** — work with what you actually find in the repo, and assume nothing
about the specific project.

## The control documents — keep them separate

**Anti-duplication:** status → `PROGRESS.md` · rules → `CLAUDE.md` · why-it-exists →
`BUSINESS.md` · why-we-chose-X-over-Y → `DECISIONS.md` · under-what-rules → `COMPLIANCE.md`.
Write each fact in exactly one place. (full table: GUIDE PART 1)

> Not every project has all five docs. This skill only maintains `PROGRESS.md`; treat the
> others as sources of context if they exist. If you catch yourself writing a rule (language
> version, commit style) or a business justification (who it is for, what pain it solves)
> into `PROGRESS.md` — it belongs elsewhere, leave it out. A **durable "why we chose X over
> Y"** is a `DECISIONS.md` entry, **not** a Notes bullet.

## What PROGRESS.md holds

A short **thread-carrier**, not a diary. If the project's thread-carrier is **not**
`PROGRESS.md` — the SessionStart declaration hook honours `ATTEST_THREAD_CARRIER`, and `CLAUDE.md` may
name one (e.g. `TIMESHEET.md`) — maintain **that** file instead: same sections, same
brevity. Keep these sections (if the file already uses
different names, adopt its order and tone):

- **Current state** — 2–3 sentences: what is done and exactly where we are.
- **Done** — completed steps (brief bullets).
- **Next** — the next step / open tasks.
- **Notes** — transient context the next session needs to resume: open threads, gotchas, a
  one-line pointer to a recent decision (`see ADR-N`) — **not** its rationale (that lives in
  `DECISIONS.md`).

Write **briefly**. A thread-carrier should restore context quickly, not replace it. Feel
free to delete old, no-longer-relevant details — the goal is a faithful, short picture, not
a complete history (`git log` holds that).

### Write a claim the next event cannot falsify

The carrier lives **inside** the branch it describes, so it can never describe its own merge:
you write it, then the merge happens, and a sentence like *"in progress on `feat/x`"* is false
from that moment on — while nobody is looking, because the work is done and attention has moved.
A hook that loads this file into every session then carries the falsehood forward as binding
context.

So **state what is true of the branch, not what is momentarily true of the repo**, in a tense the
merge leaves standing:

- write *"phase 12 is committed on `feat/x`; PR #7 opened"* — still true after the merge, merely
  incomplete;
- not *"in progress on `feat/x`"* or *"PR #7 is open"* — the merge makes both untrue and nothing
  will notice.

Same for anything else an imminent event settles: name the state you observed and when, rather
than a status you expect to hold. Being **stale is recoverable; being wrong is not**, because a
reader cannot tell a wrong line from a current one. When you do catch a falsified line, fix it
first — before adding today's delta on top of it.

## Behaviour when I run you

1. **Determine the current state** — derive it without asking, from:
   - `git log` (recent commits) — what actually got finished;
   - `git status` / `git diff` — what is in progress (uncommitted changes);
   - the session itself — what was being worked on and the **next step** (a durable "why we
     chose X over Y" is not status — it belongs in `DECISIONS.md` via `/decision`);
   - the existing `PROGRESS.md` — what is already written (so you only add the delta).
2. **Update `PROGRESS.md`** — the **Done / Next / Notes** sections, so they faithfully
   reflect reality: move finished items from Next to Done, add the new next step, note open
   threads in Notes, update "Current state" and the date if the file has them. **Keep it
   brief** — do not touch unchanged parts. A decision worth keeping goes to `DECISIONS.md`
   (`/decision`), not into Notes.
3. **Advise `/clear` vs `/compact`** based on whether the task is finished:
   - **Logical block done** (the commit is in place, no work in progress, no uncollected
     background jobs) → **`/clear`** fits, between blocks.
   - **Mid-task**, work must continue → **`/compact`**, not `/clear`.
   - **Never `/clear`** while uncollected background work is running (an A/B run, a paid
     cloud box) — finish it and collect the results first.
4. **Do not commit automatically.** At the end, **summarize** what you wrote into
   `PROGRESS.md` and which hygiene step you recommend.

## If PROGRESS.md is absent, or still the shipped template

> **A file whose sections are still `<placeholder>` text counts as absent** — the kit ships
> `PROGRESS.md` as a skeleton. Fill it from scratch; do **not** append your delta underneath
> the placeholders, and never treat a template's text as prior state.

Do not fill it silently — **offer** first, and once agreed, write (or overwrite the template
with) a skeleton containing
the sections above (**Current state / Done / Next / Notes**) and a short blockquote pointing
rules → `CLAUDE.md`, business → `BUSINESS.md`, decisions → `DECISIONS.md`, posture →
`COMPLIANCE.md`. Fill it with what can be derived from git and the session; mark blanks as open.

## After writing

- **Do not commit automatically.** Leave the commit to me (`docs:` or `chore:`).
- Briefly summarize which sections you changed and what you recommend (`/clear` vs `/compact`).
- Change nothing other than `PROGRESS.md`.
