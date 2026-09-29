# attest

Stop the push you would regret. Your non-goals in context before the first edit. One audit per
push, with a dated record.

attest attests process, not artifacts: it is not GitHub Artifact Attestations. It is a kit for
[Claude Code](https://code.claude.com): three shell hooks, five skills and one read-only auditor.

## Install

```sh
git clone https://github.com/radozaprazny/attest.git /tmp/attest
/tmp/attest/install.sh ~/my-project
```

**Requirements:** Claude Code · git · `bash` for `install.sh` (it runs once) · `/bin/sh` for the
hooks · optional: [`betterleaks`](https://github.com/betterleaks/betterleaks) on your PATH.

The installer copies 10 files into your project's `.claude/` and appends one line each to
`.gitignore` and `.gitattributes`. It never overwrites a file of yours. `--upgrade` replaces only
the kit's own files, naming each first, and only where git holds a copy. The real output of
0.20.0 on a fresh repository:

```text
attest 0.20.0  →  /tmp/tmp.mFzdNbOmjp/myproj

  ✓ 10 kit file(s) landed under .claude/ — settings, 3 hooks, the auditor, /gate /business /decision /compliance /checkpoint
  ✓ .gitignore += .attest/tmp/
  ✓ .gitattributes += .claude/hooks/* text eol=lf

  NEXT
  1  claude        start it, or restart a session that was open: skills load at start
  2  /business     writes BUSINESS.md; its non-goals reach every session and /gate
  3  /gate         before a push: audits what it sends, commits the record the guard reads
  4  /checkpoint   before /clear: writes PROGRESS.md for the next session
```

Restart Claude Code if a session was open in that project: skills load when a session starts.

## What it looks like

Claude runs a push, and no clean record covers HEAD. The ship guard stops it and asks you. This
prompt is real, from a fresh install:

```text
attest ship guard: NO RECORD — sends data off the machine (git push origin main). No clean ship record names HEAD 80b75af. Run /gate, which commits its record, then push; or approve anyway.
```

`/gate` runs betterleaks and the auditor over what the push would send, then writes a ship
record. The record guard asks before that write, and approving it is the attestation. The record
is committed on its own, and the next push passes on it. This one gated PR #54
([`.attest/ship-20260929-194043-ff45cc5.md`](.attest/ship-20260929-194043-ff45cc5.md)):

```markdown
- HEAD: ff45cc5 (refactor/install-lean)
- tree: clean
- scope: HEAD --not --remotes + worktree (3 commits, 0 untracked)
- findings: 0 blocker · 1 note
- verdict: ✅ clean to push
- kit: 0.20.0
- key layer: betterleaks 1.8.1 — unpushed 0 · unstaged 0 · staged 0 · untracked skipped
```

## The loop

`/business` once: purpose, non-goals, regulated ground. Then work, `/decision` when a choice
lands, `/gate` before each push, and `/checkpoint` before `/clear`.

## What it costs

- **Per push:** `/gate` and the auditor are 1,296 words of kit text (798 and 498, by `wc -w`).
- **Time:** install, `/business`, one change, `/gate` and the push took 6 min 7 s and 5 user
  turns. `/gate` took 2 min 21 s of it, the auditor 71 s. Measured on 2026-09-29 with Claude
  Code 2.1.268, Fable 5.1 at xhigh effort, in auto mode ([PR #54](https://github.com/radozaprazny/attest/pull/54)).
- **Prompts:** attest adds one per clean push, the record write.
- **Every session:** the session hook prints your non-goals and current state. In this
  repository on 2026-09-29 that was 385 words, by `wc -w` of its output.

## Limits

- **Forgetting, not forgery.** A ship record is an ordinary file, and nothing signs it. The
  record guard makes writing one a prompt, not a wall. Sign commits if you need integrity.
- **A verdict is a model's reading.** It can differ between runs and between models.
  betterleaks is the deterministic part, and it is optional, so the record says whether it ran.
- **The guard runs on your machine, and you can approve past it.** A push from a terminal, an
  IDE or another tool never reaches it.
- **It sees only what it is pointed at.** It reads git pushes, common publish and upload
  commands, and GitHub MCP writes. A deploy script or a git alias leaves no prompt.
- **An ask needs someone to answer it.** What it becomes in each permission mode, and
  `ATTEST_GUARD=deny` for runs nobody watches, is in [GUIDE.md](GUIDE.md#permission-modes).
- **Windows needs Git Bash** to run the hooks.

## Works with

- **`/code-review`** reviews the code. `/gate` leaves that to it and asks what must not ship.
- **spec-kit** says what to build. attest keeps what you declared you will not build in front
  of every session.
- **GitHub push protection** blocks known secret patterns at the server. attest asks earlier,
  on your machine, and about more than secrets.

## Evidence

`scripts/fixture.sh` builds a small repository with 4 planted faults, and
[`scripts/fixture-key.md`](scripts/fixture-key.md) is the answer key. On 2026-09-29, kit 0.20.0,
the auditor found all 4 with the right class, path and severity. It added 2 notes, each with its
evidence, and no extra blocker. That is n = 1: /gate's material step, run verbatim, then the
auditor, from a Claude Code 2.1.284 session on Claude Opus 5.5.

An earlier dogfood, in July 2026 on an unversioned kit older than 0.1.0, is in
[the devlog's account](docs/archive/attest-devlog.md#what-the-dogfood-proved). No adopter is
claimed here without a public record.

The method without the tool is [METHOD.md](METHOD.md). Every hook, command and knob is in
[GUIDE.md](GUIDE.md).

---

The key scan is [`betterleaks`](https://github.com/betterleaks/betterleaks), the successor to
gitleaks by its original author. Thank you. MIT licence.
