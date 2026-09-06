# attest — live status (thread-carrier)

> **This is attest's own status — not part of the kit.** `install.sh` never copies `docs/`.
> The `PROGRESS.md` at the repo root is an empty **template** for *your* project; attest's own
> status lives here, because ADR-0006 (and the Phase 7 devlog) record what happens when the two
> are confused. Decisions → `attest-decisions.md` · history → `attest-devlog.md`.

## Current state

The **guard-truthfulness series (phase 12)** is on `fix/guard-trace-and-semantics`, uncommitted
at the time of writing. It closes the four P0 items an external review of `v0.4.0` left, all of
which were reproduced here before being touched. Four ADRs, kit **0.5.0**:

- **ADR-0037** — the guard reads the record's `- HEAD:` and `- findings: 0 blocker` lines instead
  of matching a filename. An empty record used to pass, and so did one reporting a blocker; those
  two lines are now a specified machine interface in `/audit-history` and GUIDE 2.2. Narrows
  ADR-0028: the question became *audited **and** clean*.
- **ADR-0038** — every branch traces, with four words (`pass` · `ask` · `blocked` · `dryrun`), one
  line per decision. The dry-run exemption sat above `trace()`, so the one class of command the
  guard waves through wrote nothing — the kit breaking ADR-0034 in exactly the case ADR-0034
  existed for.
- **ADR-0039** — `.gitattributes` pins shell to LF **and** `install.sh` strips CR on copy. A
  Windows checkout opened from WSL gave `dash` CRLF hooks, exit 2 — and a `PreToolUse` exit 2
  blocks every Bash call in the session.
- **ADR-0040** — the maintainer's address was redacted from `ship-…-9621526.md` under a narrow,
  marked exception to append-only, and `template-cleanup.sh` now removes attest's own records
  from a generated repo, discriminating on whether the sha in the filename resolves there.

**Why 0.5.0 and not 0.4.1.** The record format became a contract in this series: a record
written before ADR-0037 no longer clears the guard, and `install.sh` is copy-if-absent, so an
adopter who refreshes `ship_guard.sh` and keeps older records will meet `blocked` with no
migration note anywhere. 0.4.0 was additive; this one breaks a shipped artefact, and the number
is the only place that can say so.

`smoke.sh` 118 → **156** assertions; shellcheck clean. Still open from the same review: P0 items
5–8 (matching normalisation, the PowerShell matcher, the non-git directory, and what `/gate` is
for) — see **Next**.


The **lean-kit series (phase 11)** is **merged** — PR #4, merge commit `8360fd5`; `main` carries
it. It came from a design pass that asked one question of every component — *would a new adopter
miss this if it were gone?* — and removed the four that answered no. Six ADRs: **0027** no
formatter · **0028** a hook must prevent, not remind · **0029** three bare rungs · **0030**
`/compliance` is opt-in · **0031** the installer reports capabilities · **0032** a late gate
record says so. Shipping it produced two more: **0033** a ship record is written before the push
and committed under a later sha · **0034** the guard leaves a trace, for the pass as well as the
ask (narrowing ADR-0026 — whatever writes into `.attest/tmp/` deletes its own files, not the
directory). Rationale → `attest-decisions.md`; narrative → `attest-devlog.md` Phase 11. Phase 10
is merged (PR #3, `ce439a5`).

**ADR-0035** landed on `feat/visibility-guard`, PR #5 (merge commit `4ed24da`). Merging PR #4
passed the guard in silence, which looked like a missing `gh pr merge` pattern; measuring found
the larger gap was elsewhere. The guard covers the **visibility flip** (`gh repo edit
--visibility`, `gh repo create`) — the one action whose blast radius is the whole history and
which no revert undoes — each `case` arm states what the prompt will claim the command does, and
the absence of `gh pr merge` is a written decision rather than a hole.

**ADR-0036** is committed on `fix/carrier-tense`: this file went false at the merge three times
running, because a carrier lives inside the branch it describes and so can never describe its own
merge. `/checkpoint` now asks for claims the merge leaves standing — branch-scoped and past
tense — since staleness is recoverable and a wrong line is not. This paragraph is written that
way; so is the one above it.

The kit now needs **`git` and `/bin/sh`** — nothing else. Of what a default install puts in your
repo, **0** items edit your code, **0** are language-bound, **0** are inert. **Kit version
0.5.0** (`.claude/skills/_shared/audit-ladder.md`); `v0.4.0` is the last tag.

0.4.0 rather than a `v0.3.0` tag on the same tree: three adopter-visible changes landed in
shipped files after 0.3.0 reached `main` and none of them bumped the line — the guard writes a
trace file (ADR-0034), gates a new class of command (ADR-0035), and `/checkpoint` carries a new
rule (ADR-0036). Tagging 0.3.0 would have put a stale label on a kit that behaves differently.
The `.attest/` records keep saying `kit: 0.3.0` and must: they record the version an audit
actually ran under (ADR-0016).

Baseline green; every number below re-measured 2026-09-04 — shellcheck is not on `PATH`, use
`uvx`:

```bash
uvx --from shellcheck-py shellcheck install.sh scripts/*.sh .claude/hooks/*.sh   # clean
./scripts/smoke.sh                                    # 156 passed, 0 failed
./install.sh "$EMPTY"                                 # 16 files + 2 .gitignore + 1 .gitattributes = 19 items
./install.sh --compliance "$EMPTY"                    # 21 items; a re-run reports "changed nothing"
git diff -U0 origin/main -- docs/attest-decisions.md | grep -c '^-[^-]'   # 4 — the sanctioned
                                                      # status flips only (0005, 0015, 0021, 0024)
```

There is no linter step for another language because the kit no longer contains one. Both new
hooks answer correctly when driven by hand: `ship_guard.sh` returns `ask` on `git push` naming
the current HEAD and stays silent on `ls`; `session_declaration.sh` emits the declaration block
once a carrier is set.

Repo is **private** on GitHub (`radozaprazny/attest`), template button on. Going public is
a separate, deliberate step, and as of 2026-09-01 the case for it is measured rather than
aesthetic:

- **Branch protection is unavailable** on a private repo on GitHub Free — both
  `branches/main/protection` and `rulesets` answer **403 · "Upgrade to GitHub Pro or make this
  repository public"**. ADR-0035 delegates the merge boundary to branch protection, so that
  boundary currently **exists nowhere**; going public is the only way to obtain it at no cost.
- **`/audit-history full` ran clean** — 51 commits, 9 refs, 441 objects, all 44 paths that ever
  existed: 0 findings on every rung (`.attest/ship-20260901-143933-9621526.md`). Two things are
  recorded there as intended rather than as findings: the maintainer's address sits in 45 commit
  authorships and would become permanently harvestable, and the name is in the `LICENSE`, the
  clone URLs and the ADR-0012 repo-name guards. (Not spelled out here on purpose — the point
  survives without adding an occurrence in file content, which is a different exposure class
  from authorship metadata. The record itself *did* spell the address out, contradicting this
  line; it was redacted on 2026-09-04 under ADR-0040, which sanctions exactly that one edit to
  an append-only record and requires it to leave a mark.)
- **54 `ADR-NNNN` citations ship into every adopter's repo** and today resolve to a 404. The
  convention is explained (`audit-ladder.md:14`, `GUIDE.md:203`) but both pointers name this
  private repo. Publishing makes them resolvable without writing a line.

## Next

- **External review, 2026-09-03/04 — the queue it left.** An independent 8-lens analysis of
  `v0.4.0` produced 65 findings; the count is an artefact of merging the lenses, so what follows
  is the triage, not the list. Each was reproduced here on Linux before being written down. The
  analysis file itself is disposable — this is its residue.

  **P0 items 1–4 — DONE** (ADR-0037…0041, kit 0.5.0). Their reasoning lives in
  `docs/attest-decisions.md`, not here; the summary is in **Current state** above. What shipped
  differs from what was planned in one place worth naming: item 4 was written as *"make
  `template-cleanup.sh` delete `.attest/*.md`"*, and that blunt form was the blocker the gate
  caught — the sweep discriminates on whether the sha in each filename resolves, refuses to act
  outside a git checkout, and keeps any name whose tail is not sha-shaped.

  **P0 — still open:**
  5. ⬜ **Normalise the matching** (F01, F02) — whitespace, global git options, `git … push` as two
     words, `--dry-run` only as a whole word of a simple command; treat `&`, `#`, `$(`, backtick
     as compound. Verified silent today: `git -C . push`, `git -c k=v push`, `git --no-pager
     push`, two spaces, `# --dry-run`, `--push-option=--dry-run`, `& git push`, and every
     script-shaped path (`npm run release`, `yarn publish`, `make deploy`, `gh release upload`).
     Deliberately **after** (1): fix detectability before coverage.
  6. ⬜ **`"matcher": "Bash|PowerShell"`** (F06) — the docs wording was checked verbatim; on Windows
     without Git Bash the hook does not run at all, which deserves a sentence in GUIDE 2.2.
  7. ⬜ **The non-git directory** (F14, F50) — the hook's own header and ADR-0028 promise it
     "proceeds untouched"; it actually prompts with advice that cannot be satisfied, and a repo
     with no commits yet is told it is "not a git checkout".
  8. ⬜ **Decide what `/gate` is for** (F65, below) — a light mode for small changes, or stop
     promising a commit-time gate.

  **P1** — gate scoping (first-parent diff on a merge HEAD; cleanliness from `git status
  --porcelain`, not `git diff --quiet`, which ignores untracked; `gate-records.txt` filtered to
  `gate-*`, since `ls | tail -3` is alphabetical and drops every gate record once three ship
  records exist) · define what flips the verdict to ⚠️, which is nowhere stated · `/compliance`
  Mode 3's `###` siblings make "hand Mode 3 to the subagent" deliver 55 words · `/audit-history
  full` breaks on its own `-----BEGIN` pattern (exit 129) and should pipe through `xargs git grep
  -I -l -e`.

  **P2** — smoke has no fixture for never-clobber, hook wiring or the negative dry-run cases;
  the declaration hook mis-handles multi-line HTML comments and fenced blocks, and its 24-line
  cap counts blank separators (15 non-goals arrive as 12).

- **Gate has not run since 2026-08-28 (F65).** Sixteen commits and six merges since `9101eac`;
  PR #4 carries gate records, **PR #5–#9 do not**. `/audit-history` kept running throughout —
  six committed ship records in the same window — so this is not neglect of records in general.
  It is the commit-time gate specifically, and the likely reason is its cost: four parallel
  subagents is disproportionate for a one-file change. That is a design question about `/gate`,
  not a discipline question about the author. Decide it before the next release; a kit whose
  headline is *"the gate ran is a fact in the repo"* cannot have its own gate quietly unused.

- **Dogfood the declaration hook** — `ATTEST_THREAD_CARRIER=docs/attest-progress.md` is now set in
  `.claude/settings.local.json` (gitignored), so the next session start here is the first live
  run.
- **Enable branch protection** on `main` — now load-bearing, not housekeeping: ADR-0035 names
  branch protection plus required CI as *the* merge boundary, precisely because the ship guard
  deliberately does not cover merges. Until it is on, that boundary does not exist anywhere.
- **Decide on going public** — the guard now asks at the flip itself (ADR-0035). The right
  answer to that prompt is an `/audit-history full` run, not an approval. A README demo GIF
  stays an open nice-to-have; never fabricate a transcript.
- **Still never exercised in anger:** `/checkpoint` alone (it cannot be, on a template —
  ADR-0006).
- **Known debt, deliberately not fixed: GUIDE PART 7 dates fastest.** It cites a specific Claude
  Code version (*"wizard removed in v2.1.198"*), key bindings and `/rc` — correct today, and the
  first section to rot in a public repo, while also being what a newcomer reads for orientation.
  Left alone on purpose: rewriting it to be version-agnostic would cost the concreteness that
  makes it useful. Re-read it at each release instead.

## Notes / standing constraints

- **attest's own regulatory posture: out of scope.** No personal data, no model, no automated
  decision, no placement on any market — the kit is markdown and shell that runs on the
  author's machine. Recorded here because ADR-0030 makes *"out of scope, because …"* a
  declaration and an absent file not one, and attest has no filled `BUSINESS.md` of its own to
  put it in. The root `COMPLIANCE.md` stays a template for consumers; it is not attest's
  posture. (Found by the kit's own `/compliance audit` on the phase-11 gate: attest was holding
  exactly the state its new rule forbids.)
- **The `SessionStart` hook is silent in attest's own checkout** unless you set
  `ATTEST_THREAD_CARRIER=docs/attest-progress.md` in `.claude/settings.local.json` (which is
  gitignored). The shipped `.claude/settings.json` stays generic on purpose — it is the
  consumer's file, and attest's own paths must never ride out in it. Same ADR-0006 tension
  `/gate` solves with `$DOCS`. Attest has no `docs/attest-business.md`, so only the carrier
  half applies here. It **is** now set locally. `smoke.sh` unsets both overrides at the top for
  that reason: with the carrier exported, the declaration fixtures read this file instead of the
  documents the test wrote, and four assertions failed for a purely ambient reason.
- **A ship record never names the commit that contains it** — `3481531` carries the record for
  `8a7d45a`, and that is now the declared rule, not an accident (ADR-0033). Read `.attest/` by the
  sha *in the name*, never by the commit the file sits in, and never make the two line up.
- **Write a ship record and push in two separate steps** — a `PreToolUse` guard is evaluated
  before the command it guards runs, so one step doing both is judged against a state where the
  record does not exist yet and the guard asks, correctly, while looking wrong. Now also in
  `/audit-history` itself, so it is the kit's rule and not a local habit.
- **The ship guard fires on real Bash tool calls** — proven 2026-08-31 by an isolated `git push`
  that logged a `pass` line with no hook invoked by hand. A push that raises no prompt is the
  guard being auto-approved by the permission mode, not a dead hook; a push leaving **no line**
  in `.attest/tmp/ship-guard.log` would be the real bug. Its designed over-match is visible in
  the same log: a tool call merely *containing* the text `git push` in a payload fires it.
- **`docs/attest-decisions.md` is append-only.** Check every commit: `git diff -U0
  docs/attest-decisions.md | grep -c '^-[^-]'` must be **0**. ADR-0001…0036 stay
  byte-identical once landed — except the one sanctioned mutation, flipping a superseded
  entry's `Status` (ADR-0003). Phase 11 flipped four: 0005, 0015, 0021, 0024.
- **Cutting a release = bump the `Kit version:` line** in
  `.claude/skills/_shared/audit-ladder.md` (ADR-0018 — the ladder is the version's one
  home; there is no VERSION file).
- **`init-tier` grep hits are deliberate** where they survive: the append-only ADR log
  (verbatim history, ADR-0009 narrates the rename) and the devlog's Phase 2 narrative.
  A hit there is correct, not a miss — do not "fix" them.
- `_shared/` relies on verified-but-undocumented behaviour: a dir under `.claude/skills/`
  with no `SKILL.md` is silently ignored by skill discovery. If that changes, move the file
  and update the references.
- **The template cleanup must stay inert in attest** — the job guards (`is_template` + the
  hard repo-name check per ADR-0012, the fork check, the payload null check) and the
  content guards inside `scripts/template-cleanup.sh` are all load-bearing; never simplify
  any of them. The script is exercised by `smoke.sh`; keep it that way.
- The repo is a **template**: the root docs are the product; attest's own records live in
  `docs/` and `scripts/` and are deleted downstream by the cleanup workflow.
