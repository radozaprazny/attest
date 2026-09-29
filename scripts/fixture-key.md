# fixture-key.md — the answer key for `scripts/fixture.sh`

`bash scripts/fixture.sh` builds a small Python to-do CLI in a fresh temp directory and prints
its path. The repo has a bare remote and one pushed commit, which holds `BUSINESS.md` with the
non-goal *"No network calls from the CLI"* and `DECISIONS.md` with two entries (a local JSON
file, argparse). It then plants the 4 faults below and installs attest from this checkout,
untracked. `--no-kit` skips the install. Open a Claude Code session in the printed path and run
`/gate`.

| # | Fault | Path | Where it sits | Class | Severity |
|---|---|---|---|---|---|
| a | A GitHub-token-shaped credential | `app/settings.py` | unpushed commit *chore: release settings* | `secret` | blocker |
| b | A `rodné číslo` column with three birth-number-shaped values | `ünï data.csv` | untracked | `national-id` | blocker |
| c | `rich==13.7.1`, a new dependency with no DECISIONS entry | `requirements.txt` | unpushed commit *feat: coloured task list* | `unrecorded-decision` | note |
| d | A usage report sent with `urllib.request.urlopen` on every run | `app/cli.py` | uncommitted change | `non-goal` | blocker |

**Why each severity.** Three are blocker floors: a secret (a), national-ID data (b) and a
violated non-goal (d). Under D4 an unrecorded decision (c) is a **note**. It is no floor, the
old ladder made it a `major`, which never held a push, and the fixture's `BUSINESS.md` declares
no dependency rule the auditor could raise it on. Report it as a blocker and the auditor has
invented a floor. Leave it out and the auditor has missed a fault.

**Expected run.**
- `findings: 3 blocker · 1 note` or more notes, and `verdict: ⚠️ fix before push`.
- One record line per blocker: `blocker · secret · app/settings.py`, `blocker · national-id ·
  ünï data.csv` and `blocker · non-goal · app/cli.py`.
- `key layer: betterleaks <version> — unpushed 42 · unstaged 0 · staged 0 · untracked 0`.
  betterleaks finds (a) through its `github-pat` rule. It has no rule for a birth number, so (b)
  is the auditor's alone. It also scans the untracked file under its real name, which tests
  `-z` and `quotepath=off`.
- No finding under `.claude/`: the kit is untracked, and its 9 files are excluded from the
  material. Of `.claude/`, only `settings.json` stays in the untracked list; the auditor
  reads it as the kit's own install.

**Scoring.** A fault counts as found when its class and path match and its severity is the one
above. An extra note must cite evidence. An extra blocker is a false positive and counts
against the run.

The literals are never in this repository. The token is built at run time from
`git hash-object`, and the birth numbers are computed mod 11, so betterleaks and the auditor
leave attest's own `scripts/` alone.
