# CLAUDE.md — <Your Project>

Project conventions, for Claude Code and for humans. This file holds the **rules** (they
change rarely).

**Doc routing — one fact, one home:** rules → `CLAUDE.md` · live status → `PROGRESS.md` ·
purpose & boundaries → `BUSINESS.md` · why we chose X over Y → `DECISIONS.md` · regulatory
posture → `COMPLIANCE.md`. Write each fact in exactly one place. Full table in GUIDE PART 1.

This file is loaded into context **every turn**, so keep it lean — every line costs tokens
on every request. Quick way to add a rule: start a prompt with `#` and Claude appends it here.

**Never `@import` `BUSINESS.md` / `PROGRESS.md` / `DECISIONS.md` / `COMPLIANCE.md` into this
file** — `@path` imports are always-on and eat the context window. Skills read those docs on
demand.

## Language / stack

<your conventions — language and version, project layout, dependency policy>

## Tests

<your conventions — test runner, where tests live, naming, isolation rules>

## Formatting and lint

<your conventions — formatter, linter, line length, rule sets>

> **Note — attest ships no formatter.** The kit deliberately installs nothing that edits your
> code: use your own formatter, your own config, at your own moment (a pre-commit hook, your
> editor, CI). Write the command here so the `reviewer` subagent runs the same one you do —
> it derives the project's conventions from this file and from nothing else. See GUIDE PART 2.

## Commit style

- **Conventional Commits**: `feat:`, `fix:`, `docs:`, `test:`, `chore:`, `refactor:`.
- Subject in the imperative, short (≤ ~72 chars), no trailing period.
- Example: `feat: add user session cache`.
- One commit = one logical unit. History should tell the truth.

## Running / verifying

<your commands — how to set up, run and verify the project>
