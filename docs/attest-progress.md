# attest — live status (thread-carrier)

> **This is attest's own status — not part of the kit.** `install.sh` never copies `docs/`.
> The `PROGRESS.md` at the repo root is an empty **template** for *your* project; attest's own
> status lives here, because ADR-0006 (and the Phase 7 devlog) record what happens when the two
> are confused. Decisions → `attest-decisions.md` · history → `attest-devlog.md`.

## Current state

**`v0.9.0` is tagged at `b1b6e0e`** — the first tag since `v0.8.0` on 2026-09-10, and it carries
the whole gate series plus the guard fix below: ADR-0067 (a pass runs only when the diff touched
its ground; `full` runs them all — the record shape change that earned the bump), ADR-0068 (the
bounded `fix` loop) and ADR-0069 (the ship list matches a command, not a spelling). Until it was
cut, `main` claimed kit 0.9.0 with no such tag anywhere, so an adopter had nothing to pin.

**The ship list stops reading spelling — ADR-0069, and P0 item 5 is closed after four
releases.** `git -C . push`, `git -c k=v push`, `git --no-pager push`, `git --work-tree /w push`
and `git  push` with two spaces were every one of them a real push with no prompt and no trace
line. The dry-run escape was the worse half, because it let through a command the list *did*
match: `--push-option=--dry-run` read as a dry run, a `#` parked the flag out of the shell's
sight, `&` was not compound, and `gh pr create --body "adds a --dry-run flag"` opened a real pull
request on the strength of a word in its own description. **Two of those were ADR-0038's, written
down on 2026-09-04 and deferred on purpose** — this closes them rather than discovering them. The
command is now normalised once, above the list, and **the list is
unchanged** — that was the whole argument against writing a pattern per entry. Suite **281 →
303**, with **17 of the 22 new cases failing against `448b57b`**; the other five are controls,
and `git --no-pager log --grep push` is the one that caught the first draft, which backtracked
over `log` to reach `push`. **Its own gate earned its keep three times, and the third is the one
worth keeping.** The `/decision` pass caught the entry citing ADR-0033 for a rule ADR-0028 owns
and presenting two known holes as new findings. The `reviewer` pass caught the first fix still
missing `git --work-tree /w push` — five of git's global options take a **separate** argument on
top of `-c`/`-C`, and only those two were losing theirs. Then the **re-review** caught the repair
for that: `--exec-path` had gone onto the list on the strength of a measurement that asked the
wrong question, *did the command exit 0*, which it does by printing its path and stopping before
the subcommand. Asking *did the subcommand run* removes it and nothing else. A proxy for the
question is not the question, and a round-2 pass is what turned it up.
**Coverage was left alone on purpose** (`npm run release`,
`yarn publish`, `make deploy` still silent): a spelling and a missing command are different
decisions, and the review that raised this said *fix detectability before coverage*.

**Phase C is in, and with it the proposal is spent — `/gate fix`, a bounded repair loop
(ADR-0068).** The contract is in `.claude/skills/gate/SKILL.md`; what matters for the thread is
that the series is finished and what it cost. **C was gated by the loop it adds**, and the two records say what that cost:
round 1 returned **1 blocker and 10 majors** (the blocker: three files still promising *"the
gate changes no code"* while `fix` edits code — the same rule-home drift ADR-0045, ADR-0056 and
ADR-0064 each paid an entry for), and round 2's re-review confirmed eleven of twelve repairs and
found **two more majors**, one of them a disagreement between the two halves of the loop's own
contract. Both closed; the loop stopped at its finish line, not at its cap. `docs/attest-proposal-gate.md` is deleted, as it said it would be;
ADR-0068 maps its sections to the entries that own them, and **six of its seven questions are
answered** (the seventh, the ship guard's `major` threshold, stays flagged in the ladder).

**Phase B is in — the gate asks only the questions a diff raises, and `full` asks them all
(ADR-0067, kit 0.9.0).** `.claude/skills/gate/triggers.sh` is a POSIX `sh` stage that runs
before any subagent exists: it reads the diff, the untracked files and the two declaration
documents, and writes one `run` / `skip` / `not-installed` line per pass plus a `file:line`
evidence file for each pass that runs. **Measured over the last 40 non-merge commits: 50
subagent runs against 160** — reviewer 32 · decision 10 · compliance 8 · business 0, with 8
records-only commits (32 + 8 = 40). The proposal predicted 61, and **three of the four
components moved, not one** — the detail is in ADR-0067, which is the one home for this number.
Twenty-four `smoke.sh` cases pin the rules, including the ones that give the others meaning: a
diff **no** list names leaves its pass off, a stage with no material writes nothing and exits 0,
and a patch it cannot parse produces no verdict at all rather than a false "records only". The record gains `mode:` and `triggers:`, so a skipped pass
can never be read as one that ran clean. **`/gate full` joins the ship cadence** in GUIDE PART 9
beside `/audit-history`: the light gate triggers on words, and the 2026-09-07 blocker
(`*.sh text eol=lf`) is the standing proof that a word is not always there.

**The id collision resolved, and six entries on top — ADR-0061 … ADR-0066 (merged as PR #20).** PR #18 and PR #19 were written in parallel sessions and **both**
claimed `ADR-0055`–`ADR-0057`, for six different decisions. #19 keeps the numbers it recorded;
#18 is renumbered **0058–0060** — the cheaper side, measured: 26 citations against 45 — by a 1:1
`sed` over ids that changed no word of content. The merge had exactly one conflict, both
branches appending to the end of the log, and resolved it by keeping both blocks in id order.

On top of that, six entries out of one afternoon's dogfooding (devlog, *The first run outside a
sandbox*): **ADR-0061** — the round ends at ✅, and `/gate` closes with an instruction rather
than a list · **ADR-0062** — a recommended fix subtracts before it adds, and states as fact only
what the audit read, with a `file:line` · **ADR-0063** — the next id comes from every ref, and a
landed collision is renumbered by the branch that merges second · **ADR-0064** — the log's sixth
relation (`Widens`), and the grep that ends a three-entry series of the same drift ·
**ADR-0065** — what day one costs, said where first-run advice is actually read · **ADR-0066** —
a skeleton is skipped *before* the subagent, and *skipped* is not *degraded*.

Suite **240 → 244** from the change itself, and **245** as the branch stands: `smoke.sh` asserts
one case per ship record and this branch writes one. The new grammar check was verified to fail on a planted `Contradicts:`,
including the mid-line and tab-indented shapes its first version missed. **Kit stays 0.8.0** — the
maintainer's call, made explicitly rather than by omission: the record template's `passes:` line
now carries a reason inside the existing word (`skipped (template)`), which the records have
been writing in practice since `gate-20260904`, so no consumer of the record has to change. The
bump belongs to phase B, which changes the shape for real (`mode:`, `triggers:`). **Nothing is pushed** — the ship record for this branch is the maintainer's call
(ADR-0051), and both PRs say the same of their own heads.

**The ship gate caught what the commit-time gate could not see.** `/audit-history`, run by an
independent pass, found the removal of a third party's specifics complete in the **tree** and
incomplete in the **history**: two unpushed commits still carried them. They were rebuilt before
the push (`5bbad84` → `4979896`), and the run record says so in its own first lines rather than
presenting a clean sha. That is the whole argument for a second gate on a different clock —
the commit-time passes were looking at the tree, and the tree was already right.

**The gate on this work ran once and is recorded** (`.attest/gate-20260912-…`): two passes, not
four — `/business` and `/compliance` skipped as skeletons, which the run then found to be wrong
for `/compliance` and corrected in ADR-0066. Seven majors fixed, one rejected with evidence
(the reviewer read `ce439a5`'s rounds in file-name order; the 14:41 record declares itself late,
so `4 · 2 · 3 · 5` stands). Minors were not fixed — they are below, which is the rule this
branch adds.

**The gate covers the non-shell publish path — ADR-0058, and the front page stops overclaiming
— ADR-0059.** A reader asked the question the README invites — *does nothing sensitive really
leave?* — and probing the hook with real payloads answered most of it well: the literal list
behaves exactly as PART 2.2 documents. It also found one path nothing in the kit named. The
`PreToolUse` matcher is `Bash`, and a GitHub MCP server publishes over the API, so
`push_files`, `create_or_update_file`, `create_pull_request` and `create_repository` shipped
bytes with the hook never consulted and no line in the trace. Closed by registering the same
hook for those tools; that arm **asks every time and never reads a record**, because a record
attests the tree at a commit and these calls send bytes chosen in the call. `install.sh` now
requires the new matcher before it calls a kept `settings.json` wired, or an upgrader would be
told their guards run while the path stayed open. Twenty-three new `smoke.sh` assertions,
seventeen failing against `332a40b` — the other six are controls that must pass both ways;
suite 210 → 233.

The same session found the front page claiming *"prove nothing sensitive leaks when you ship"*
while *What it does not defend against*, ninety lines down, said the opposite at length.
ADR-0059 states the mechanism instead of the outcome and names the coverage boundary where a
reader looks for it. **Closed 2026-09-13: the GitHub *About* description was changed by hand**
to *"…and makes the leak scan a gate, not a memory"* — 343 of the 350 characters GitHub allows,
read back with `gh repo view` — it was never in the tree, so no commit carries it.

**ADR-0060, found by the guard watching itself.** The push for the above left
`record … grep -c . README.md > /tmp/n && ls .attest/ship-a.md` in the trace — a command
that lists a record, not one that writes it. The arm was a whole-command `case`, so a
redirect in one half and a record path in the other read as a write. Now judged per command
part. Tightening the pattern instead would have dropped absolute-path writes, which is why
the fix splits rather than narrows. Suite 233 → 240.

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

- **From the phase-C rounds (`gate-20260913-0744*`) — the minors, unfixed on purpose:**
  - **GUIDE PART 9's per-change step 3 does not mention `fix`**, while `reviewer.md` sends the
    reader there for the full loop. Either add the word or stop pointing at it.
  - `docs/attest-progress.md` still carries `./scripts/smoke.sh  # 177 passed` in an older
    block; the suite is at 280. A stale count in a status doc is the cheapest kind of lie.
  - **`smoke.sh` pins the narrowed *"no code"* sentence in two homes and not in `GUIDE.md`**,
    which is the third; and nothing pins the record's shape against the entry that prescribes it
    — the round-2 major was exactly that pair disagreeing.
  - *"What flips that verdict line"* — after the bullet was reordered, the demonstrative in
    GUIDE 3.6 points at *verdict*, not at *line*.
  - **The limit this series demonstrated and ADR-0068 does not name:** in a repository whose
    product is prose, `fix` has almost nothing it is allowed to touch — seven of the eight files
    changed here are documents. The loop is built for code and this repo is the wrong dogfood
    for it; the next adopter with real tests is the first honest test.

- **From the phase-B gate (`gate-20260912-224046-4baa8d5.md`) — the minors, unfixed on purpose:**
  - **`smoke.sh` fixtures that pass for the wrong reason.** The line-number case uses a hunk
    where the old start, the new start and a hunk-relative count all give 2, so it cannot tell
    the three apart; use `@@ -10,2 +20,3 @@` and expect `:21:`. Section 0c also has no negative
    case for `/compliance` (`skip · no trigger` is never asserted) and no case for the 2000-line
    or 200-file caps.
  - **`triggers.sh` calls `git log` for the new-top-level-directory rule**, which its own
    contract does not list among its inputs; where git is absent every top-level directory reads
    as new and `/business` runs every time. Either widen the contract or drop the rule.
  - **The `trigger-<pass>.txt` files are a second local store of matched lines** — for the
    compliance pass, by definition the lines that matched a personal-data pattern. They live in
    `mktemp -d` and step 2 deletes them, but `COMPLIANCE.md` §7 records the ship guard's trace
    (ADR-0038) and does not record this one. Decide whether it belongs there.
  - `.claude/agents/doc-auditor.md` has a 158-char line in a file whose longest was 91; the
    `triggers.sh` file mode is 644 where every other `.sh` is 755; the record's `triggers:` line
    joins with `·`, which each line already contains.
  - **`/gate full`'s base is now derived** (`origin/HEAD`, then `main`/`master`, then the root
    commit) but the entry does not say what the base was — a record that says *"the branch"*
    should name the range it meant.

- **From the 2026-09-12 gate on the ADR-0061…0066 branch — the minors, unfixed on purpose** (ADR-0061: a ✅
  ends the round and minors travel here; these rode a ⚠️ whose majors were fixed, and the same
  rule applies to what was left):
  - `/decision`'s id command runs `git fetch --all --quiet 2>/dev/null`, so a fetch that fails
    (offline, auth) is indistinguishable from one that worked, and the command then reports a
    maximum over stale refs. ADR-0063 claims this path *"fails safe"*. Drop the redirect on the
    fetch line; keep it on `git grep`, where it suppresses the refs that have no such file.
  - **This log's own header** (`docs/attest-decisions.md`) still names the `Status` flip as the
    single exception to append-only. The two shipped homes now name two, the id-only renumber
    included. Either propagate it or say in ADR-0063 that attest's header is deliberately out.
  - The shipped `DECISIONS.md` pointer sentence still reads *"neither is a softer `Narrows`"*
    where the other homes now read *"`Narrows` or `Widens` … really did move hides the move"*.
    The new smoke check does not catch it: it tests for the **word**, not the sentence.
  - `smoke.sh` details: the rule-home presence test is an unanchored `grep -q "$rel"`, so a
    sentence merely mentioning a relation satisfies it (match `<rel>: ADR-` instead); its
    comment says *"two shipped rule-homes"* while the loop walks three, one of which
    (`docs/`) does not ship; and `LOG` is assigned here and again at the ship-guard trace —
    harmless today, a trap on the third use.
  - ADR-0063 says *"Sixty entries cite each other … and so do `audit-ladder.md`, four skills"*.
    Measured on HEAD: 66 entries, five skills.
  - ~~The devlog naming a personal project and three of its specific weaknesses~~ — **closed
    before the push.** `/compliance` would have owned it had that pass run; the `/decision` pass
    reported it once under the ladder's fallback. The maintainer's call was the subtractive one:
    the project name and the three specifics are gone, the counts and timings the argument rests
    on stay. Same reason ADR-0049 keeps contents out of a record.
  - Next gate on this branch must run `/compliance` — ADR-0066 now scopes the skeleton skip to
    `/business`, and this run had skipped it before that was settled.
  - **From the `/audit-history` pass that cleared this push:** seven commits arriving from the
    two PR branches carry a `Claude-Session:` trailer with a session URL; `main` carries none
    today, and the nine newer commits on this branch have already dropped the habit. They are
    the maintainer's own identifiers in his own public repo — the class ADR-0040 weighed — and
    they are already public on the PR branches, so rewriting them buys nothing. Worth deciding
    once, deliberately, rather than drifting: keep the trailer or stop writing it.

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
  5. ✅ **Normalise the matching** (F01, F02) — **closed by ADR-0069**, which owns the reasoning
     and the known limits; *Current state* above carries the headline. Coverage was deliberately left
     alone: `npm run release`, `yarn publish`, `make deploy` and `gh release upload` are still
     silent, because they are not spellings of anything on the list but commands absent from it.
     That is a separate decision with its own README sentence — *fix detectability before
     coverage*, as the review itself put it.
  6. ⬜ **`"matcher": "Bash|PowerShell"`** (F06) — the docs wording was checked verbatim; on Windows
     without Git Bash the hook does not run at all, which deserves a sentence in GUIDE 2.2.
  7. ⬜ **The non-git directory** (F14, F50) — the hook's own header and ADR-0028 promise it
     "proceeds untouched"; it actually prompts with advice that cannot be satisfied, and a repo
     with no commits yet is told it is "not a git checkout".
  8. ⬜ **Decide what `/gate` is for** (F65, below) — a light mode for small changes, or stop
     promising a commit-time gate. Sharpened by the 09-07 run: the full gate is what *found* two
     blockers nothing else could, so the answer is not "run it less" — it is a cheaper mode that
     is still worth running on a one-file change.

  **P1** — ~~gate scoping (first-parent diff on a merge HEAD; cleanliness from `git status
  --porcelain`, not `git diff --quiet`, which ignores untracked; `gate-records.txt` filtered to
  `gate-*`)~~ and ~~`/compliance` Mode 3's `###` siblings~~ **are closed by ADR-0067**, all four
  in `/gate` step 1 and the compliance skill's headings. What remains: `/audit-history full`
  breaks on its own `-----BEGIN` pattern (exit 129) and should pipe through
  `xargs git grep -I -l -e`. *(What flips the verdict to ⚠️ was on this list and is now
  ADR-0055.)*

  **P2** — smoke has no fixture for never-clobber, hook wiring or the negative dry-run cases;
  the declaration hook mis-handles multi-line HTML comments and fenced blocks, and its 24-line
  cap counts blank separators (15 non-goals arrive as 12).

- **What `/gate` is for (was F65) — closed. All three phases have shipped.** The question was
  never whether to run the gate but what it cost: four parallel subagents on a one-file change,
  four and five rounds per tree, and no run ever green. **A** gave the verdict a finish line and
  the round a terminus (ADR-0055, ADR-0061); **B** made a shell stage choose the passes and added
  `/gate full` on the push cadence (ADR-0067, kit 0.9.0); **C** added the bounded `fix` loop
  (ADR-0068). `docs/attest-proposal-gate.md` has been **deleted**, as it said of itself it would
  be — its parts are in those entries, and ADR-0068 carries the map from each of its sections to
  the entry that now owns it. **Six of its seven open questions are answered**; the seventh —
  should the ship guard block on a `major`, not only a `blocker`? — is flagged in the ladder,
  where the asymmetry lives, and wants evidence rather than an argument.
  - **What the phases cost each other, which is the part worth keeping:** gating A found a major
    *in* A twice over (ADR-0056, ADR-0057), and gating B found two blockers in B — a stage that
    could not parse a diff rendering that as a decision, and a posture check dead against the
    shipped template. Every one of them was found by the passes running **beside** the commits
    rather than ahead of them. That is the argument `fix` was built on, and it was paid in full
    before `fix` existed.

- **Dogfood the declaration hook** — `ATTEST_THREAD_CARRIER=docs/attest-progress.md` is now set in
  `.claude/settings.local.json` (gitignored), so the next session start here is the first live
  run.
- ✅ **Branch protection on `main` — on since 2026-09-13**, and with it the merge boundary
  ADR-0035 names actually exists somewhere. Read back from the API rather than assumed:
  required status check `check` with `strict: true` · `enforce_admins: true` · pull request
  required at **0** approvals · force pushes and deletions refused. **`enforce_admins` is the
  part worth defending**: the only account that merges here is the maintainer's, so protection
  that exempts admins would exempt the one person it is for. Zero approvals is the other half —
  GitHub will not let you approve your own pull request, so any higher number locks a solo
  maintainer out of their own repository, and *required PR* is the property that was wanted
  anyway. **The standing cost, noticed the first time it bites:** a one-line documentation fix
  now needs a branch and a PR too. PR #24 is this entry paying it.
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
