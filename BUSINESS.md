# BUSINESS.md — attest

## Purpose
A Claude Code kit that injects a project's non-goals at session start and holds a push or a
publish until a dated record says a leak scan of that exact HEAD came back clean.

## Non-goals
- No interpreter beyond /bin/sh in hooks.
- Nothing in the kit edits your code: no formatter, and no rule that rewrites your files.
- No warning you cannot act on when it fires: a hook prevents, it does not remind.
- One way to install: `install.sh`, copy-if-absent, into the repo's own `.claude/`; no plugin.
  Only `--upgrade` replaces, and only the kit's own files, naming each first.
- No runtime prompt over its measured budget.
- No legal verdict and no legal date: the compliance skill points at the law, it does not decide.
- Never rewrite a user's history or overwrite a file git cannot give back.

## Regulated
Not in itself: attest stores nothing about people, and a ship record names a finding's class
and path, never its value.
