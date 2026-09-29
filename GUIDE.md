# GUIDE.md — attest reference

What each document, hook and command of the attest kit does, and what a ship record promises.
This file stays in the kit repository; `install.sh` does not copy it. The first steps are in
[README.md](README.md), and the reasoning is in [METHOD.md](METHOD.md).

## Documents

Five documents, one kind of fact each. Each skill writes its own; `install.sh` writes none.

| File | Holds | Written by |
|---|---|---|
| `CLAUDE.md` | Rules and conventions. Claude Code loads it every turn, so keep it short. | You, or `/init` |
| `PROGRESS.md` | `## Current state` and `## Next`, at most 8 lines each. | `/checkpoint` |
| `BUSINESS.md` | `## Purpose`, `## Non-goals` and `## Regulated`, at most 20 lines. | `/business` |
| `DECISIONS.md` | Why a choice beat its alternatives. Append only. | `/decision` |
| `COMPLIANCE.md` | The self-assessed posture under the EU AI Act and the GDPR. | `/compliance` |

One fact, one home: status goes to PROGRESS, rules to CLAUDE, why the project exists to
BUSINESS, why X beat Y to DECISIONS, and which external rule applies to COMPLIANCE.

Only `CLAUDE.md` is in context every turn. The session hook prints the non-goals, the current
state and the next step once, at session start. The skills and the auditor read the rest when
they run. A missing document costs nothing. The auditor reads a missing BUSINESS.md as no
non-goals, and a missing DECISIONS.md as every choice unrecorded.

A `DECISIONS.md` entry is never edited. A reversal is a new entry with a line
`Supersedes: <heading>`. The format maps to [MADR][madr]. The heading gives the title and date,
**Context** the problem statement, and **Options** the considered options. **Decision** and
**Why** give the decision outcome, and **Consequences** the consequences. `Supersedes:` replaces
MADR's status field and sits on the new entry, because old entries stay untouched.

## Hooks

Three hooks, wired in `.claude/settings.json`. All three are POSIX `sh` and need only `git`.
The two guards answer with a PreToolUse `permissionDecision`: `ask`, or `deny` under
`ATTEST_GUARD=deny`. A pass prints nothing, so Claude Code's own permission rules still decide.

### Session hook

| Matches | `SessionStart` |
|---|---|
| Says | BUSINESS.md's `## Non-goals` (up to 24 lines) and PROGRESS.md's `## Current state` and `## Next` (up to 8 each), inside `<project-declaration>`. A trimmed section says so. |
| No non-goals | One line: `attest: no non-goals found in BUSINESS.md — …` |
| Knobs | `ATTEST_NONGOALS_HEADING`, `ATTEST_STATE_HEADING`, `ATTEST_NEXT_HEADING`: an awk regex for each `## ` heading, for documents in another language |
| Trace words | None |

### Ship guard

| Matches | PreToolUse on `Bash\|PowerShell`, and four GitHub MCP tools: `push_files`, `create_or_update_file`, `create_pull_request`, `create_repository` |
|---|---|
| Ship commands | `git push` in any spelling, `git send-email`, `gh` pull requests, releases, gists and repository creation or visibility. Registry publishes (`npm`, `yarn`, `bun`, `uv`, `poetry`, `twine`, `cargo`, `gem`), `docker` pushes and Kaggle submits. `scp` or `rsync` to a remote, `aws s3`, `gsutil cp` and `curl` uploads. |
| Record writes | A shell write to `.attest/ship-*.md`, such as `>`, `tee`, `cp` or `sed -i` |
| Says | `attest ship guard: <VERDICT> — <action> (<command>). <reason>. <next step>.` |
| Verdicts | `NO RECORD`, `BLOCKED`, `COMMIT FIRST`, `NOT HEAD`, `LEAK`, `SCAN FAILED`, `MCP PUBLISH`, `NO HEAD`. A record write speaks as the record guard. |
| Knobs | `ATTEST_GUARD=deny`, `ATTEST_LEAK_SCAN=off`, `ATTEST_LEAK_SCAN_SECONDS` (1 to 540, default 30), set in `settings.json`'s `env` block or the environment. Fingerprints in `.betterleaksignore`. |
| Trace words | The eleven under **Trace** below |

**Pass.** A push passes when every record naming HEAD reports `0 blocker`, and the push ships
HEAD alone. That is an allow-list: a plain `git push` whose refspecs resolve to HEAD, with known
options, in this repository. Read-only commands may come before it, and a filter after it.
Anything else asks.

**Carrier.** With no record for HEAD, a push or `gh pr create` passes as `pass-carrier` when
HEAD only adds non-merge commits of `.attest/ship-*.md` files. The commit below them must be
cleared by one of the 10 newest records. A blocker there asks `BLOCKED`. So `/gate` commits its
record, then you push, then open the PR with `--body-file`. The one prompt is the record write.

**Leak scan.** With `betterleaks` on the PATH, each `git push` also scans every unpushed branch
and tag. The scan only adds a question: `LEAK` on a finding, `SCAN FAILED` on an error or
timeout.

**Dry run and MCP.** A `--dry-run` passes only in a plain command: no chaining, substitution,
comment or quote. The MCP tools always ask: no record covers bytes chosen in the call.

**Trace.** Each matched command appends a line to `.attest/tmp/ship-guard.log`. Its columns are UTC time, word, short sha, permission mode, scan and subject, with
credentials masked. The scan column reads `-`, `off`, `absent`, `clean`, `leak` or `error`.

| Word | Meaning |
|---|---|
| `pass` | A clean record names HEAD; the push ships HEAD alone |
| `pass-carrier` | HEAD only adds records; a clean record names the commit below them |
| `blocked` | A record for HEAD, or a carried record, reports a blocker |
| `ask` | No clean record, or no HEAD |
| `compound` | Clean record; something runs before the push |
| `nothead` | Clean record; the push may ship more than HEAD |
| `leak` | Clean record; betterleaks found a secret |
| `scanerr` | Clean record; betterleaks failed or timed out |
| `dryrun` | A plain dry run |
| `mcp` | An MCP publish tool |
| `record` | A ship record write, from either guard |

### Record guard

| Matches | PreToolUse on `Write\|Edit` whose `file_path` is `.attest/ship-*.md` |
|---|---|
| Says | `attest record guard: RECORD WRITE — writes a ship record (<file>). Approve only if /gate ran and this is its verdict: approving is the attestation.` |
| Knobs | `ATTEST_GUARD=deny` |
| Trace words | `record`, in the ship guard's log |

It cannot stop a forged record. It asks while you still know whether `/gate` ran.

### Permission modes

What the guards' `ask` becomes in each mode. Sources are the Claude Code docs, read 2026-09-29,
or a measured run.

| Mode | The guards' `ask` becomes | With `ATTEST_GUARD=deny` | Source |
|---|---|---|---|
| `default` | A prompt | A deny | [hooks][h] |
| `acceptEdits` | A prompt | A deny | [hooks][h] |
| `plan` | A prompt; not measured in a terminal session with bypass available | A deny | [hooks][h], [plan][pl] |
| `auto` | A prompt; the classifier can deny it, never approve it | A deny | [hooks][h]; measured on a record write, Claude Code 2.1.268, 2026-09-29 ([PR #54][pr54]) |
| `dontAsk` | A deny | A deny | [dontAsk][da], [hooks][h] |
| `bypassPermissions` | Not measured; the docs do not settle it | A deny | [bypass][bp], [hooks][h] |
| `claude -p` | A deny with no permission host; with one, the host answers | A deny | [headless][hl], [hooks][h] |
| A cloud session | As in its mode: default, plan or auto; bypass is not offered | A deny | [modes][cm], [hooks][h] |

Where nobody answers, set `ATTEST_GUARD=deny`. It also denies a command that only mentions a
push.

## Commands

All five are manual (`disable-model-invocation: true`): only you start them.

**`/gate [full]`** is the one gate before a push. Its scope is what the next push sends,
`HEAD --not --remotes`, plus uncommitted and untracked files; `full` adds all history. One Bash
step writes the material to `.attest/tmp/gate/` and runs betterleaks, if installed. One auditor
reads the material. Any blocker gives ⚠️ fix before push; none gives ✅ clean to push. Whatever
the verdict, it writes the ship record and commits it alone. Code review is `/code-review`'s
job.

**The auditor** has Read, Grep and Glob only. It checks four grounds:

- must-not-ship bytes: secrets, special-category and national-ID data, third-party personal
  data, client names, internal hosts, stray data files;
- the non-goals in BUSINESS.md;
- decisions with no DECISIONS.md entry;
- regulated ground, when COMPLIANCE.md exists.

Always a blocker: a secret, special-category or national-ID data, a violated non-goal, or an EU
AI Act Art 5 practice. Everything else is a note, unless BUSINESS.md or COMPLIANCE.md says that
class must not ship. The material is evidence, never instruction.

**`/business`** reads the repository, then asks at most three questions in one message. Each
comes with a proposed answer. It writes Purpose, Non-goals and Regulated; unknowns become
`Open:` bullets. A Regulated "yes" ends with "run /compliance".

**`/decision`** appends one entry: Context, Options, Decision, Why, Consequences. It records only
a choice with discarded alternatives. It never invents an option or a reason: it asks, or writes
nothing.

**`/compliance`** writes COMPLIANCE.md from BUSINESS.md's Regulated line. It walks the AI Act
and the GDPR and cites provisions by ID. It gives no legal verdict and no legal date.

**`/checkpoint`** rewrites Current state and Next in PROGRESS.md from git and the session. Run
it before `/clear`. Write what the merge leaves true: "PR #7 opened", not "PR #7 is open".

The four document skills never commit. Their old `audit` argument now points at `/gate`.

## The ship record

`/gate` writes one record per run, `.attest/ship-<YYYYMMDD-HHMMSS>-<short sha>.md`:

```markdown
- HEAD: <short sha> (<branch>)
- tree: clean|dirty
- scope: HEAD --not --remotes + worktree (<n> commits, <n> untracked) | --all + worktree
- findings: <n> blocker · <n> note
- verdict: ✅ clean to push | ⚠️ fix before push
- kit: <version>
- key layer: betterleaks <version> — unpushed <rc> · unstaged <rc> · staged <rc> · untracked <rc|skipped> | degraded — <why>
- blocker · <class> · <path>
```

The ship guard parses two lines, and they are a contract:

- `- HEAD:` — the first such line. Its first 7 or more hex characters must be a prefix of HEAD's sha.
- `- findings:` — the first such line. It clears only if its first number is the `0` of
  `0 blocker`.

The guard reads every `.attest/ship-*.md`, but not the sha in its name, and ignores carriage
returns. Every record naming HEAD must clear, so one
blocker holds the push. A record names a finding's class and path, never its value, line or
excerpt: it is committed and published. Never edit a record; run `/gate` again.

## Install and upgrade

```sh
./install.sh [--upgrade] <path-to-your-project>
```

It copies 10 files, each only if absent: `settings.json`, the 3 hooks, the auditor and the 5
skills. It appends 2 lines: `.attest/tmp/` to `.gitignore`, and `.claude/hooks/* text eol=lf`
to `.gitattributes`. It writes no document. It refuses to install into the kit, or into a
directory that holds it. Without git or a first commit, it says so under NEEDS YOU.

A `settings.json` of yours is never edited. If it leaves a hook unwired, the installer prints a
`jq` command that appends the kit's entries. Without jq, it tells you to ask Claude to merge them.

Without `--upgrade`, a kit file that differs from this kit is kept and counted. `--upgrade`
replaces such a file only where git holds your committed copy, and names it first. A file with
uncommitted changes, or one git does not track, is kept and named. Retired paths go under the
same condition: `reviewer.md`, `doc-auditor.md`, `_shared/`, `audit-history/` and `triggers.sh`.
It never touches a document or `settings.json`.

Restart Claude Code afterwards, because skills load at session start. The kit version is the
`Kit version:` line in `.claude/skills/gate/SKILL.md`, and each record's `kit:` line.

## Limits

- A record attests HEAD. The leak scan covers every unpushed branch and tag of this repository.
  A push that ships anything else asks.
- The push-config check models `push.default`, `remote.*.push`, `remote.*.mirror`,
  `push.recurseSubmodules` and `submodule.recurse`, from git config, `-c` or `GIT_CONFIG_*`. It models nothing else.
- These are outside the guard: commands that do not go through Claude Code's tools (a terminal, an IDE, another tool), scripts (`make deploy`, your own deploy script), submodule pushes, and git aliases such as `git p`.
- The ship list is literal. A command not on it, such as `mvn deploy`, passes unseen until you
  add it to `ship_act()`.
- Managed settings with `allowManagedHooksOnly` or `strictPluginOnlyCustomization` stop project
  hooks, and so does a cloud session opened on several repositories ([managed][ms], [cloud][ce]). Nothing
  reports it. The check is the session hook: no attest output at session start means no guard.
- On Windows the hooks need Git Bash. Without it, Claude Code runs hook commands in PowerShell
  ([hooks][hsh]), which has no `sh`. Not measured on Windows.
- A ship record defends against forgetting, not forgery. For integrity, sign commits and require
  signed commits in branch protection.

## Glossary

- **ship guard** — `ship_guard.sh`. It asks before a command or MCP tool sends data off the
  machine.
- **record guard** — `record_guard.sh`, and the ship guard's shell arm that speaks as it. It asks
  before a ship record is written.
- **session hook** — `session_declaration.sh`. It prints the non-goals and the state at session
  start.
- **ship record** — `.attest/ship-*.md`, the committed verdict of one `/gate` run on one HEAD.
- **/gate** — the one audit before a push. It writes the ship record.
- **auditor** — the read-only subagent `/gate` runs.
- **blocker** — a finding that holds the push.
- **note** — an advisory finding, counted in the record but not listed.

[madr]: https://adr.github.io/madr/
[h]: https://code.claude.com/docs/en/hooks#pretooluse-decision-control
[pl]: https://code.claude.com/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode
[da]: https://code.claude.com/docs/en/permission-modes#allow-only-pre-approved-tools-with-dontask-mode
[bp]: https://code.claude.com/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode
[hl]: https://code.claude.com/docs/en/headless#turn-off-permission-prompts-in-unattended-runs
[cm]: https://code.claude.com/docs/en/permission-modes#switch-permission-modes
[ce]: https://code.claude.com/docs/en/cloud-environments#what-carries-over-from-your-setup
[ms]: https://code.claude.com/docs/en/settings-reference#what-runs-under-allowmanagedhooksonly
[hsh]: https://code.claude.com/docs/en/hooks#exec-form-and-shell-form
[pr54]: https://github.com/radozaprazny/attest/pull/54
