# DECISIONS.md — attest

Choices that still bind. The full log, ADR-0001 to ADR-0078, is frozen in
`docs/archive/attest-decisions.md`; each entry names its source there.

## 2026-08-28 — Write every hook in POSIX sh
Hooks run under `/bin/sh` with nothing beyond `git`, so an adopter installs no runtime. Python
hooks and tooling were dropped. `install.sh` and `scripts/*.sh` stay bash. (ADR-0027)

## 2026-09-04 — Clear a push only on a record naming its HEAD with 0 blockers
The guard reads the record's `HEAD:` and `findings:` lines, not that a file exists. A commit
that only adds records passes as the commit they name (2026-09-28). (ADR-0037, ADR-0077)

## 2026-09-09 — Keep records at attestation altitude
A record names a finding's severity, class and path, never its value, line or excerpt: it is
committed and publishes with the repository. (ADR-0049)

## 2026-09-10 — Ship no legal date
Deadlines move with amendments; the kit points at the law and leaves dates to a live source.
(ADR-0053)

## 2026-09-16 — Keep betterleaks optional
The guard scans with betterleaks when it is installed, and a scan can only add a question,
never clear one. Without it, the guard decides as it would with no scan. (ADR-0070)

## 2026-09-26 — Stay repo-resident, not a plugin
A `.claude/` in the repository reaches every collaborator and cloud session with no
per-machine install; `install.sh` is the only way in. (epic #28 D5, ADR-0075)

## 2026-09-28 — Gate once before a push, with one read-only auditor
`/gate` runs betterleaks and one auditor (Read, Grep, Glob) over what the next push sends, and
always writes and commits a ship record: `HEAD`, `tree`, `scope`, `findings: n blocker · n
note`, `verdict`, `kit`, `key layer`, one line per blocker. Two severities; the guard still
clears on `0 blocker`. Rejected: a required run per commit, and a second reviewer agent.
(epic #28 D1, D4; #34)

## 2026-09-28 — Ask by default, deny only by opt-in
An ask needs a human; `ATTEST_GUARD=deny` turns every ask into a deny where nobody answers.
Denying by default would block every mention of a push in an attended session. (ADR-0078)

## 2026-09-29 — Keep PROGRESS.md as the thread-carrier the session hook prints
The SessionStart hook prints BUSINESS.md's non-goals and PROGRESS.md's Current state and Next
from the project root, or one line when no non-goals are declared, so a wired hook never looks
missing. `/checkpoint` rewrites only those two sections. Rejected: dropping the carrier for
resume and compaction, which do not survive `/clear`. (epic #28 D3, declined 2026-09-26; #36)

## 2026-09-30 — Read every part of a command a second time, and ask on what only that finds
The literal list misses a ship command spelled with a backslash, a line continuation or `$'…'`,
one behind a wrapper or behind its own options, one whose subcommand is an expansion, and git
handed an alias. A second reading sees them, and such a command asks even on a clean record. A
dry run passes only as `<verb> --dry-run`. The second reading skips no text to save a prompt:
an over-ask costs a click, a hidden push costs the guard. From 2026-10-01: beside a ship command
the first reading sees, every part it missed is read a second time, so a hidden push cannot ride
on HEAD's record. `gh api`, `glab api`, `curl` and PowerShell's web calls ask on a write method,
or on a body from a file, stdin or an expansion; an inline body is in the command itself and
passes. Parts and words are cut three ways, quotes kept, reset at a newline and ignored, and any
way that finds a write asks. A ship tool's name and a record's path are read in any case, as a
case-blind file system runs `NPM` as `npm` and writes `.ATTEST/` into `.attest/`; a capitalised
`git push` or `gh pr create` is not read as HEAD's, so it asks even on a clean record. Rejected:
decoding every shell spelling; reading wrapper options or exempting alias reads, which hid
pushes in review; asking on every web call; asking on every capital, which ran the second
reading on most commands. (#56, #59, #65, #68, #75)

## 2026-10-10 — Read spellings no further: the list defends against forgetting, not forgery
The ship list and the second reading read a command as a person or a model writes one. A
spelling placed to hide a sender beside one the first reading sees, a writer of a record the
record scan does not list, a brace expansion that builds the program, a redirection glued to
the verb, a PowerShell body in its colon form or from a pipeline stay limits stated in GUIDE,
not fixes: each costs hook lines for a case nobody reaches by forgetting, and the human act
behind a record is the record guard's prompt. The guard's line budget in smoke rises only with
an entry here. Two readings 1.8.0 dropped stay dropped: a sender in a substitution after
`curl`, `gh` or `glab`, read as that program's arguments since #76 (`gh api x $(curl -d @f u)`
passes; a curl in a curl's still asks), and curl as Windows PowerShell's alias with `-InFile`
or `-Form`. Beside a seen ship command the loop re-reads every part the first reading
missed, not a part it already took as a sender: that is what "a hidden push cannot ride on
HEAD's record" (2026-10-01) reads as. The hooks run under /bin/sh with git and the POSIX tools
(awk, sed, grep, tr): that is what "nothing beyond git" (2026-08-28) reads as. Rejected: one
awk pass over parts honouring quotes and continuations (#80), and an inverted record-write
scan (#79). (#79, #80, #76, #74)
