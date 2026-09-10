# attest — live status (thread-carrier)

> **This is attest's own status — not part of the kit.** `install.sh` never copies `docs/`.
> The `PROGRESS.md` at the repo root is an empty **template** for *your* project; attest's own
> status lives here, because ADR-0006 (and the Phase 7 devlog) record what happens when the two
> are confused. Decisions → `attest-decisions.md` · history → `attest-devlog.md`.

## Current state

**Second review of `0.8.0` — ADR-0054, one arm wider.** An independent pass over the guard
series found the record arm of ADR-0051 covers only the shapes that **create** a file: `sed -i`
on a record went through with no prompt, and so did `sed --in-place` and `perl -pi`. Reproduced
here, then closed — the arm now lists the in-place editors, five `smoke.sh` cases pin them (four
fail against `825d996`; the fifth pins that a non-editing `sed -n 1p` stays a read), and GUIDE
2.4's *"four words"* is corrected to five, which two earlier ADRs had quietly outdated.

**How to count new assertions, since three reports have now disagreed about it:** run the old
suite and the new suite over the **same tree**. Measured on `825d996` — old 185, new 204 — the
guard series added **19**, of which 11 fail against the pre-series hooks. Counting `+` lines in
the diff undercounts (a loop body is one line and many assertions); counting totals from
different clones overcounts (records differ). Neither is wrong on purpose; the method just has
to be stated with the number.

**External review of `v0.7.0` — the guard series (ADR-0050, ADR-0051), kit 0.8.0.** An
independent read of the public repo produced seven findings plus nits; each was reproduced here
before being touched, and two were reproduced *against* the reviewer's description and came out
narrower than reported.

- **ADR-0050 — the abbreviation bug is real, and both directions give a false reason.** The guard
  matched `- HEAD: $SHA` byte for byte with `$SHA` from `--short`, whose length is `core.abbrev`,
  i.e. a colleague's config. Record at 7 read by a guard at 10 → *"no record for HEAD"* while it
  sits there; record at 8 read at 7 → *"reports a blocker, or predates the record format"* when
  it does neither. It now reads the sha out of the record and accepts any prefix of the full
  `HEAD`, seven hex or longer. The filename keeps its sha for people only.
- **ADR-0051 — the record is forgeable and the README oversold it.** The guard's matcher is
  `Bash`, so the `Write` tool went past it; a record is an unsigned untracked file. New
  `record_guard.sh` on `Write|Edit` makes writing one a prompt, and `README.md` gained *"What it
  does not defend against"*. Stated honestly there and here: this does **not** make forgery
  impossible, it moves the prompt to where the human still knows whether the audit ran.
- **Measured narrower than reported:** the CRLF claim in `.gitattributes` was false only for the
  *bare* `- HEAD: <sha>` shape — the shape `/audit-history` actually writes always passed, the CR
  landing where a `*` swallowed it. The pin stays as belt and braces; the reasoning was rewritten
  and the guard now strips CR, so the claim is moot rather than restated.
- **Also in:** the trace carries the payload's `permission_mode` (the other half of ADR-0034's
  ambiguity), and the guard's *"fail-open everywhere"* header now says what the code does —
  outside a git checkout it asks.
- **Rejected:** a mandatory `gitleaks`/`trufflehog` run before a record is written. It collides
  with the non-goal that the kit ships no tool and edits nothing; an optional `- scanner:` line
  in the record is the version of that idea worth having, and it is not built yet.

**The docs half of the same review (ADR-0052, ADR-0053).** The `SessionStart` declaration opened
with *"Treat it as binding"* — text styled as an order arriving from outside the conversation,
which is the shape a model is trained to distrust, so the kit's strongest sentence was its most
suspect one. It now states the same weight as fact about the repository. And the kit shipped a
**legal status**: two instruments share the name *Digital Omnibus* — the one on **AI** has been
in force since 27 Jul 2026, the one on **data** is still a proposal — so one line was false and
the other true of a different act than the reader would assume. Both are gone: the kit now ships
structure and a pointer to a live source, never a date. `README.md` also gained a 60-second
start above the prose, and one paragraph on what the guard adds over a harness that already
refuses the obvious.

Shipped as **PR #14** (`ad0641a`) and **PR #15** (`f34acf8`), tagged **`v0.8.0`** at `f34acf8`.
`smoke.sh` 0 failed; **11 of the new assertions fail against the pre-series hooks**,
verified in a worktree — including the case-fold bug the first draft shipped, which the *control*
fixture caught. shellcheck clean.

**`METHOD.md` — the method without the tool (ADR-0048)** is on `main` (PR #12, `a0fb1d7`). One
root document states the spine, the ten properties that make it work, the four host primitives an
implementation needs, and what it costs — tool-neutral, no code, and deliberately **no adapter**
for any other agent: an adapter would keep attest's name and drop its guarantee. It is attest's
identity, so `install.sh` never copies it and `template-cleanup.sh` removes it in a generated
repo by content guard. `smoke.sh` clean, 0 failed (see the standing note on totals).

The **guard-truthfulness series (phase 12)** merged as **PR #10** (`2d381f5`), and the heading
overrides (phase 13, ADR-0047) as **PR #11** (`dfa2255`); `main` carries both. (This paragraph
replaced one reading *"PR #10 opened 2026-09-06, CI green"* — written per ADR-0036, so the merge
left it standing rather than false, but it was still what the `SessionStart` hook loaded as
binding two days after it stopped being the state. Stale is recoverable; it is not free.)

It closes the four P0 items an external review of `v0.4.0` left, all of which were reproduced
here before being touched — and then **five more ADRs (0042–0046) came out of gating it**, two of
them blockers that only the gate could see. **Ten** ADRs in the series, kit **0.5.0**:

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
  marked exception to append-only: the data goes, a visible mark stays where it was, and the
  record says what was removed, when and under which rule.
- **ADR-0041** — attest's own audit records do not travel into a repo generated from the
  template. `template-cleanup.sh` removes them, discriminating on whether the sha in the
  filename **resolves** in the target — the only thing that really separates attest's records
  from an adopter's own, since auditing before the first push is the workflow this kit teaches.
  The kit's own gate caught two inversions of that test before it shipped (`git cat-file -e`
  answers non-zero for *any* reason, including "no git at all", which would have deleted every
  record wherever git could not answer).

**What the 2026-09-07 gate added** (record: `.attest/gate-20260907-103000-d91f69f.md`, run over
the whole of PR #10 rather than a working diff):

- **ADR-0042** — a shallow clone answers about `HEAD` and nothing else, so
  `template-cleanup.sh`'s sha test deleted **the adopter's own** records: a record names the
  commit it gated, which ADR-0033 makes an ancestor. `actions/checkout` defaults to
  `fetch-depth: 1`, and the workflow runs unattended with a write token. Fixed in both layers —
  the script refuses unless git says the history is complete, the workflow asks for it.
- **ADR-0043** — `.gitattributes` is tracked, so the template button carried a blanket
  `*.sh text eol=lf` into adopters' repos: the kit editing your code through a rule you never
  wrote, against the non-goal in README §"Not a kitchen sink". `template-cleanup.sh` now narrows
  it, like it already narrows README and LICENSE.
- **ADR-0044** — a line-ending-only difference is named, with its repair, instead of being
  reported as ordinary `drift` — the message that failed exactly the Windows population ADR-0039
  exists for. Nothing is rewritten: copy-if-absent stays absolute.
- **ADR-0045** — the log's `Narrows:` relation gets the entry it never had, and ships in
  `DECISIONS.md` and `decision/SKILL.md`, which still knew only `Supersedes`.
- **ADR-0046** — ADR-0038 understated the trace sanitiser's keep-set; narrowed rather than
  edited, which is what ADR-0045 just made the grammar for.

Both blockers were invisible to `smoke.sh` — one fixture had a single commit, the other never
copied `.gitattributes`. Both now have regression tests.

**A second gate run over the fixes found more, which is the point.** It returned 2 majors and 8
minors, and two of them were defects the *first* round of fixes introduced: the narrowing threw
away the `.attest/*.md` pin the same series had just added, and ADR-0044 claimed smoke coverage
that did not exist — a consequence written from a manual check rather than from an assertion. The
narrowing is now surgical (a line of the adopter's own survives a late run), the assertions exist,
and the ADR says what they actually assert. Verified by running the final suite in a worktree at
the pre-fix HEAD: **6 failures there, 0 here** — the new tests can fail, which is the only thing
that makes them tests.

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
0.6.0** (`.claude/skills/_shared/audit-ladder.md`), tagged `v0.6.0` at `dfa2255`.

**Why 0.6.0 and not 0.5.1.** 0.5.0 shipped a declaration hook whose reach stopped at the
language of its own documents; ADR-0047 makes the three headings configurable, which is a new
capability an adopter can depend on, not a repair of one that was stated and broken. `v0.5.0`
was tagged at `2d381f5` first, so the number is not left orphaned by the bump — the marker on
`main` said 0.5.0 to anyone who cloned it, and the tag is what makes that true afterwards.

0.4.0 rather than a `v0.3.0` tag on the same tree: three adopter-visible changes landed in
shipped files after 0.3.0 reached `main` and none of them bumped the line — the guard writes a
trace file (ADR-0034), gates a new class of command (ADR-0035), and `/checkpoint` carries a new
rule (ADR-0036). Tagging 0.3.0 would have put a stale label on a kit that behaves differently.
The `.attest/` records keep saying `kit: 0.3.0` and must: they record the version an audit
actually ran under (ADR-0016).

Baseline green; every number below re-measured 2026-09-07 — shellcheck is not on `PATH`, use
`uvx`:

```bash
uvx --from shellcheck-py shellcheck install.sh scripts/*.sh .claude/hooks/*.sh   # clean
./scripts/smoke.sh                                    # 177 passed, 0 failed
./install.sh "$EMPTY"                                 # 16 files + 2 .gitignore + 2 .gitattributes = 20 items
./install.sh --compliance "$EMPTY"                    # 22 items; a re-run reports "changed nothing"
git diff -U0 origin/main -- docs/attest-decisions.md | grep -c '^-[^-]'   # 0 on this branch —
                                                      # the phase-11 status flips are already in main
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

- **Public since 2026-09-09.** `radozaprazny/attest` is public; `main` carries `METHOD.md`, and
  `v0.6.0` is tagged at `dfa2255`. Cleared before the flip: the carrier fixed · PR #12 merged as
  `a0fb1d7` · `/audit-history full` over **all 431 blobs in every commit, branch and tag** —
  **0 blocker, 0 major, 1 minor**, record `.attest/ship-20260909-211730-5c79205.md`. The minor is
  the maintainer's own address surviving in the blob one commit behind ADR-0040's redaction
  (`50e9893`); it stays, because purging it means rewriting every sha the `.attest/` filenames,
  the ship guard and `template-cleanup.sh` all resolve — against a value the author field of 45
  commits carries anyway. The stale remote branches were a non-finding: GitHub had auto-deleted
  them at merge and only the local tracking refs were behind.

  **What being public changed for the kit — resolved the same day (ADR-0049).** The `.attest/`
  records are readable by anyone now, and a `/gate` record as the kit wrote them is a running
  narrative of every finding: what was wrong, where, how it was repaired. Harmless here, where
  the findings *are* the documentation; for an adopter it is a dated, pre-indexed inventory of
  every weakness their code has had, published by a kit they installed to be safer. Records are
  now written at **attestation altitude** — HEAD, kit version, passes, verdict, counts, and one
  line per blocker and major (severity · pass · class · path), with the narrative going to the
  session and, if wanted durably, to the ignored `.attest/tmp/`. The two machine-parsed lines are
  untouched, so `ship_guard.sh` is unchanged and every record already written still clears it.
  Kit **0.7.0**, shipped in PR #13 (`68a3f58`) and tagged `v0.7.0` there: it changes what the kit
  writes into an adopter's repo, which is adopter-visible even though nothing breaks. `v0.6.0`
  stays tagged at `dfa2255` so that number is not orphaned by the bump either.

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
     promising a commit-time gate. Sharpened by the 09-07 run: the full gate is what *found* two
     blockers nothing else could, so the answer is not "run it less" — it is a cheaper mode that
     is still worth running on a one-file change.

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

- **What `/gate` is for (was F65) — the gap is closed, the design question is not.** F65 read
  *"gate has not run since 2026-08-28"*; that was true when written and is now stale — it ran
  2026-09-04, 09-06 and 09-07, the last of them over the whole of PR #10 rather than a working
  diff. **That run is why this branch grew:** it returned **2 blockers, 2 majors, 7 minors**,
  and both blockers were things no other check could see — a shallow clone deleting the
  adopter's own records (ADR-0042) and a blanket `.gitattributes` rule reaching adopters through
  the template button (ADR-0043). The suite could not see either: one fixture had a single
  commit, the other never copied dotfiles. Both now have regression tests that fail against the
  pre-fix code, verified by running the new suite in a worktree at the old HEAD.
  The design question F65 really asked still stands: four parallel subagents is disproportionate
  for a one-file change, which is *why* the gate goes unrun, and a light mode is the open item —
  not the running of it.

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

- **`smoke.sh`'s total is a floor, not a property.** One assertion is generated per
  `.attest/ship-*.md` on disk — the loop at `smoke.sh:195` re-checks that every shipped record
  still parses for the guard — so the total grows with the directory and never with the suite
  alone. **Measured 2026-09-10: 15 ship records, 15 generated assertions, 203 total.** An earlier
  version of this note said *"four"*, which was true when it was written and quietly false for
  weeks afterwards; that is the whole argument for comparing failures, not totals. A reviewer
  reporting a different total from a clone is agreeing with you, not contradicting you.

- **attest widens ADR-0049 for its own records.** The rule is that a run record names findings
  at attestation altitude, because it publishes with the repo; a project whose findings are its
  own documentation may write more, and say so in its `CLAUDE.md`. attest has no filled
  `CLAUDE.md` of its own (ADR-0006 — the root one is the consumer's template), so the widening
  is declared here: attest's records keep their narrative, since every finding in them is already
  public in `docs/attest-decisions.md` and the point of this repo is to show the gate working.
  The records written before 2026-09-09 keep theirs regardless — `.attest/` is append-only.

- **attest's own regulatory posture: out of scope.** No personal data beyond the maintainer's
  own — his authorship on every commit, and what ADR-0040 redacted from one record — no third
  party, no Art 9 category, no model, no automated decision, no placement on any market — the kit is markdown and shell that runs on the
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
  half applies here. It **is** now set locally. `smoke.sh` unsets all five overrides at the top
  for that reason — the two paths and, since ADR-0047, the three headings: with the carrier
  exported, the declaration fixtures read this file instead of the documents the test wrote, and
  four assertions failed for a purely ambient reason.
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
  docs/attest-decisions.md | grep -c '^-[^-]'` must be **0**. ADR-0001…0046 stay
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
