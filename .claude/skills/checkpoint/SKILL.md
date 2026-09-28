---
name: checkpoint
description: >-
  Rewrites the Current state and Next sections of PROGRESS.md from git and this session, so the
  thread survives /clear: the SessionStart hook reads both back. Creates the file on first use.
  Run before /clear or /compact.
disable-model-invocation: true
---

# /checkpoint — where the work stands

Status only: rules → `CLAUDE.md` · why it exists → `BUSINESS.md` · why X over Y →
`DECISIONS.md` (`/decision`) · posture → `COMPLIANCE.md`.

1. Read the recent `git log`, `git status` and `git diff`, this session, and `PROGRESS.md`.
2. Rewrite `## Current state` (what is done, where the work stands) and `## Next` (the next
   step, what is open), at most 8 lines each: the hook prints no more. Replace their content
   rather than appending to it, and drop what has gone stale; `git log` holds the history.
3. Leave every other part of the file exactly as it is. If it names these two sections in
   another language, keep its headings; if one is missing, add it.
4. If `PROGRESS.md` does not exist, create it with exactly these two sections:

```markdown
# PROGRESS.md — <project>

## Current state
- <what is done, and where the work stands>

## Next
- <the next step>
```

5. Do not commit. Say what changed, and advise `/clear` when a logical block is done
   (committed, nothing in progress) or `/compact` mid-task. Never `/clear` while background
   work is still running.

## Write what the merge leaves true

This file lives inside the branch it describes, so it cannot describe its own merge. Write
"committed on `feat/x`; PR #7 opened", not "in progress on `feat/x`" or "PR #7 is open": the
merge makes those false, and nothing notices. State what you observed, not what you expect to
hold.
