# attest — decision log (ADR-lite, append-only)

> **This is attest's own decision log — not part of the kit.** `install.sh` never copies it.
> If you generated your repo from the **template button**, delete `docs/` and `install.sh`
> (see README "First 5 minutes"). The `DECISIONS.md` at the repo root is an empty template for
> *your* project; this is where the kit's own "why X over Y" lives, so attest never ships its
> author's decisions as yours. Status/history → `docs/attest-devlog.md`.
>
> Append-only — never edit or delete a past entry (except flipping its `Status` line when
> superseded); to reverse one, **append** a new entry that supersedes it.
>
> A new entry may carry, under its title, any of `Supersedes: ADR-N` · `Supersedes in part:
> ADR-N` · `Narrows: ADR-N`. All three are fields of the **new** entry and touch nothing older,
> so they cost no exception to the rule above. `Narrows` is for the case this log kept hitting:
> the old decision still stands and its scope turns out smaller than its text says. Reach for it
> instead of editing the older entry, which is the one thing this log cannot allow. Note the
> limit it shares with the other two: the field sits on the **new** entry, so a reader who lands
> on the old one is not told — searching the log for its id is what finds the narrowing. Only
> `Supersedes` earns the `Status` flip.

<!--
Every entry below was reconstructed from a written record — the design-workflow `reject`
arrays (which literally list the discarded alternatives and why) and the commit bodies.
Nothing here is inferred: where the alternatives were not written down at the time, no ADR
was created. That restraint is the same rule /decision applies.
-->

## ADR-0001 — Record the archetype as a trigger, not as the legal risk tier · 2026-07-15 · Accepted

- **Context** — `/init-tier` records a project archetype (library / cli / service /
  data-pipeline / ai-system) in `BUSINESS.md`. `/compliance` needs to know whether the EU AI
  Act applies. The obvious wiring is to let the archetype drive the classification.
- **Options** — (a) the archetype *drives* the AI-Act risk classification; (b) `/init-tier`
  records the legal risk tier directly in `BUSINESS.md`; (c) the archetype is only a
  **trigger** and `/compliance` derives the tier independently.
- **Decision** — (c). The archetype signals the AI Act *may* apply; the tier follows the
  intended purpose + Annex I/III + Art 5, and lives only in `COMPLIANCE.md`.
- **Why** — (a) is legally wrong: a `service` or `data-pipeline` embedding a model is in scope
  exactly as an `ai-system` is, a deterministic tool is out regardless of label, and GPAI is a
  separate axis — so archetype→tier over-claims determinism. (b) puts a legal conclusion in the
  product-intent doc and duplicates `/compliance`'s job. The EU-correctness review was
  authoritative here over the simpler wiring.
- **Consequences** — `/compliance` must re-derive the classification from the Art 3(1)
  threshold every time; `BUSINESS.md` holds only a label. The word "tier" now means two things
  in the kit, so every place both appear carries a disambiguation line.

## ADR-0002 — One router line everywhere, not a doc table per file · 2026-07-15 · Accepted

- **Context** — the doc-routing rule (status → PROGRESS, rules → CLAUDE, …) appeared as a
  3-row table in 7 files. Adding `DECISIONS.md` and `COMPLIANCE.md` meant growing all of them.
- **Options** — (a) grow the table to 5 rows in each of the 7 files; (b) one canonical table in
  GUIDE PART 1 that every other file links to; (c) a **one-line router** everywhere, with
  exactly two sanctioned full enumerations (README's shop-window table + GUIDE PART 1).
- **Decision** — (c).
- **Why** — (a) is ~14 hand-synced edits of the same fact: the kit violating its own
  single-source rule, and worst in `CLAUDE.md`, which is loaded every turn and explicitly warns
  against its own growth. (b) was rejected because GUIDE PART 1 uses prose sections carrying
  How/What-for/When detail that a table would flatten — the substance of "single source" is
  honoured by the router without the reformat.
- **Consequences** — `CLAUDE.md`'s always-on cost stays flat as docs are added. Adding a sixth
  document means editing one router line plus the two enumerations, not seven tables. Doc-header
  blockquotes legitimately omit their own doc, so they are not verbatim-identical to the router.

## ADR-0003 — Append-only means forward-only, with one sanctioned Status flip · 2026-07-15 · Accepted

- **Context** — `DECISIONS.md` is append-only, and reversals use the ADR "supersede" pattern.
  As first drafted it said both "never edit a past entry" **and** "Superseded-by back-pointer" —
  which contradict, because writing a back-pointer onto the old entry *is* an edit.
- **Options** — (a) strict forward-only: the new entry carries `Supersedes: ADR-N`, the old one
  is never touched; (b) the classic back-pointer edited onto the superseded entry; (c)
  forward-only **plus** one sanctioned mutation — flipping the old entry's `Status` line only.
- **Decision** — (c).
- **Why** — (a) alone loses discoverability: a reader landing on ADR-0007 has no way to know it
  was reversed. (b) makes "append-only" a lie and opens the door to rationale rewrites, which is
  the one thing the log exists to prevent. (c) keeps the rationale immutable while a one-line
  status flip preserves the trail.
- **Consequences** — exactly one permitted mutation, which must be stated in the header or
  authors will hit the ambiguity on their first reversal. The reviewer must know a superseded
  entry is *not* an anti-duplication violation.

## ADR-0004 — Give the audits an ownership contract: one hunk, one owner · 2026-07-15 · Accepted

- **Context** — the README promises the audits run "in one pass". But a single diff hunk (a new
  dependency) is simultaneously a scope question, an undocumented decision, and possibly
  regulated ground — so three audits would each report it.
- **Options** — (a) no rule: every audit reports whatever it sees; (b) ownership by
  finding-type; (c) (b) plus an explicit **content vs behaviour** line for `/audit-history`.
- **Decision** — (b) first, then (c) after the dogfood.
- **Why** — (a) makes "one pass" noisy rather than coherent: `requests` would be triple-flagged.
  (b) assigns: `/decision` owns new dependency / swapped library / new pattern / threshold;
  `/init-tier audit` fires only on non-goal or scope violation; `/compliance audit` only on
  regulated ground. (c) was added because the first real dogfood showed `/audit-history`'s
  "reads the project's own declarations" clause letting it claim a violated *behaviour* non-goal
  ("no network access") — ground already assigned to `/init-tier`. Both were per-spec, so the
  spec was the bug.
- **Consequences** — every audit body must name the *other* skills' ground, which is redundant
  text that has to stay in sync. Accepted: the dogfood showed all four then routed correctly
  instead of triple-flagging, which is what makes the "one pass" claim true.

## ADR-0005 — One 3-rung severity ladder with a domain alias, not per-skill vocabularies · 2026-07-15 · Superseded by ADR-0029

- **Context** — the audits were meant to read as one family, but shipped three ladders:
  `/init-tier` used blocker/creep/nit, the reviewer blocker/major/minor/nit, and the newer
  skills specified none at all.
- **Options** — (a) let each audit keep its own vocabulary; (b) one 4-rung ladder keeping "nit";
  (c) one 3-rung ladder (blocker / major / minor) with the middle rung domain-aliased.
- **Decision** — (c). "nit" survives only in the reviewer.
- **Why** — (a) reads as four dialects. (b) keeps a rung that a doc-audit has no honest use for:
  a *code review* has legitimate cosmetic findings, a "does reality match the declaration" audit
  does not. (c) keeps each skill's flavour ("major (scope creep)", "major (posture gap)") without
  forking the vocabulary.
- **Consequences** — `/init-tier`'s "creep" became "major (scope creep)"; stale wording that was
  "nit" collapses into "minor". The ladder is stated once in GUIDE PART 3 and referenced, so an
  install that omits GUIDE.md leaves every audit's severity undefined.

## ADR-0006 — Ship the templates at the repo root; keep attest's own docs in docs/ · 2026-07-15 · Accepted

- **Context** — attest is simultaneously the kit and the template. Its `PROGRESS.md` was its own
  live phase log, shipped verbatim to every downstream repo — and `/checkpoint` is contractually
  delta-only ("do not touch unchanged parts"), so it can never clear what it inherits.
- **Options** — (a) status quo: attest's real docs at root, shipped as the user's; (b) real docs
  at root, templates in a `template/` subdirectory; (c) **templates at root**, attest's own log
  and decisions under `docs/`.
- **Decision** — (c).
- **Why** — (a) means the doc that survives `/clear` tells the next session the user's project is
  attest and is complete. (b) breaks the "Use this template" button, which copies the whole repo —
  the user would get attest's real docs anyway, and the template dir would be the thing nobody
  copies. (c) makes the root *be* the product, which is what a template repo's root is for.
- **Consequences** — attest cannot dogfood `/checkpoint` or `/decision` on its own root documents;
  its history lives in `docs/attest-devlog.md` and this file. Accepted: shipping a clean template
  matters more than the kit using its own skills on itself.

## ADR-0007 — Replace the documented `cp` install with install.sh · 2026-07-15 · Accepted

- **Context** — GUIDE PART 8 documented installation as six `cp` lines. The first real adoption
  into an existing project would have destroyed 294 lines of that project's live `CLAUDE.md` and
  `PROGRESS.md`, clobbered its `settings.json` and its own `.claude/commands/`, and silently
  hijacked its ruff config (ruff resolves `ruff.toml` over `pyproject.toml` and does not merge,
  so the victim's config survives on disk as dead code with no diff to notice).
- **Options** — (a) keep `cp` and add prose caveats; (b) an `install.sh` that is copy-if-absent;
  (c) distribute as a package / git submodule.
- **Decision** — (b).
- **Why** — (a) fails because the damage is **mechanical and silent**: no volume of warnings stops
  someone pasting a `cp`, and the ruff case leaves literally no evidence (`git status` shows one
  *added* file). (c) is overkill for a kit that is documents plus Markdown skills, and it fights
  the "Use this template" path. A script also honours "each fact one place": the procedure lives
  in one executable instead of six dangerous lines plus twenty lines of caveats.
- **Consequences** — a new artifact to maintain in step with the file list; `install.sh` must be
  kept honest as files are added. It prints a SKIPPED report rather than merging, so a user
  adopting into an existing project still has manual work — deliberately, since merging someone's
  `CLAUDE.md` is not a job for a shell script.

## ADR-0008 — Squash the build history to a single commit at first release · 2026-07-15 · Accepted

- **Context** — `/audit-history full`, run before the public release it is designed for, found
  the working tree clean but **eight commits** carrying an earlier version of the devlog that
  named the author's other, private projects — including one project's architecture and its
  compliance posture. Scrubbing the file was a delete-commit, which does not purge. The repo had
  also been briefly public, so old objects may sit in caches or forks.
- **Options** — **accept** (they are the author's own projects, and most of that stack is already
  public via its live service) / **filter-repo** (surgically strip the file from all eight
  commits, keeping the phase-by-phase history) / **squash** (one root commit, delete + recreate
  the remote).
- **Decision** — **squash**.
- **Why** — *accept* leaves *another project's compliance posture* in a public repo, which is
  exactly the class `/audit-history`'s own taxonomy calls **major**; a kit that ships a leak gate
  should not ship a leak. *filter-repo* preserves the commit graph but is fiddly, and
  force-pushing leaves dangling objects reachable by SHA on a remote that was already public —
  recreating the remote is the only total answer. *squash* is decisive, and it is defensible
  **here specifically** because the development record survives in prose: `docs/attest-devlog.md`
  and this file carry the phases, the reasoning and every discarded alternative. The rule
  *"history should tell the truth"* is satisfied by the **documents**, not by the commit graph.
- **Consequences** — the phase-by-phase git history is gone; anyone who wants it reads the
  devlog. This would **not** be defensible in a project whose commits are the only record — it
  is defensible only because the record was written down first. It is a **one-time act at first
  release, not a habit**: the CLAUDE.md rule ("one commit = one logical unit; history should tell
  the truth") governs every commit after this one. Forks or caches of the briefly-public repo may
  still hold the old objects; deleting the remote minimises but cannot guarantee their removal.

## ADR-0009 — Rename `/init-tier` back to `/business` · 2026-07-15 · Accepted

- **Context** — the skill that owns `BUSINESS.md` was renamed `/business` → `/init-tier` in
  Phase 2 to advertise the archetype it had just gained. The kit's other document skills are
  named after their document (`/decision` → `DECISIONS.md`, `/compliance` → `COMPLIANCE.md`);
  `/init-tier` was the one that was not. It also imported the word "tier" into a kit where
  ADR-0001 had just ruled that "tier" means the **AI-Act risk tier** and nothing else.
- **Options** — (a) keep `/init-tier`; (b) rename the skill back to `/business`; (c) rename
  the skill **and** the document (`BUSINESS.md` → something archetype-flavoured).
- **Decision** — (b). The skill is `/business`; `BUSINESS.md` and the archetype are unchanged.
- **Why** — (a) costs a **disambiguation tax that exists only because of the name**: the skill
  glossed the archetype as *"tier"* three times and GUIDE PART 3 carried a whole
  `"tier" ≠ legal tier` blockquote — none of which describe the feature, all of which exist to
  stop a reader confusing the skill's *name* with ADR-0001's *legal* tier. Renaming deletes
  that text rather than maintaining it. (c) was rejected because the archetype is a **section**
  of the business context, not a rival to it — `/init` : `CLAUDE.md` :: `/business` :
  `BUSINESS.md` is the parallel the skill is built on, and renaming the doc would break the
  1:1 doc↔skill symmetry rather than restore it.
- **Consequences** — this does **not** supersede ADR-0001: the archetype is still a *trigger*
  and never the legal tier, and that text stays everywhere it was. It retires exactly one of
  ADR-0001's consequences — *"the word 'tier' now means two things in the kit, so every place
  both appear carries a disambiguation line"* — which was true only while the skill was named
  `/init-tier`. ADR-0001 through ADR-0008 keep their `/init-tier` references verbatim: they
  record what was decided when it *was* the name, and rewriting them would falsify the log this
  file exists to protect. So `/init-tier` survives in this file and nowhere else — an
  intentional grep hit, not a missed one.

## ADR-0010 — The audit ladder is a runtime contract: move it next to its consumers · 2026-07-15 · Accepted

- **Context** — the shared severity ladder and the ownership contract lived **only** in GUIDE
  PART 3, and all four audit skills referenced them at runtime ("see GUIDE PART 3"). ADR-0005
  had already written down the risk: *"an install that omits GUIDE.md leaves every audit's
  severity undefined."* `install.sh` has two branches that do exactly that — if the target
  already has a `GUIDE.md`, the kit's lands as `attest-GUIDE.md` (and the skills' hardcoded
  "GUIDE PART 3" then points at the user's *own* guide, which has no PART 3); if **both**
  names are taken, the guide is skipped entirely.
- **Options** — (a) leave it in GUIDE PART 3 and make `install.sh` try harder to land the
  file; (b) restate the ladder in each of the four skills; (c) extract it to
  `.claude/skills/_shared/audit-ladder.md` and have GUIDE PART 3 reference *that*.
- **Decision** — (c).
- **Why** — the ladder is not a *fact about* the kit, it is a **contract with four consumers**,
  and a contract belongs where its consumers always find it. (a) treats the symptom: the
  degraded branches exist for good reasons (never clobber the user's files), and no amount of
  install effort makes a *reference manual* a safe place for runtime state. (b) is four copies
  of one fact hand-synced across four files — precisely what ADR-0002 rejected, and worse here
  because a drifted copy means two audits silently disagreeing about what "major" means.
  (c) makes the dependency travel with the dependents: `copy_tree_if_absent ".claude/skills"`
  already copies the whole tree per-file, so `_shared/` installs with zero new install logic.
  Verified empirically before committing: a directory under `.claude/skills/` with no
  `SKILL.md` is **silently ignored** by skill discovery — Claude Code loaded the real skills
  beside it and neither listed nor warned about `_shared`.
- **Consequences** — GUIDE.md stops being a runtime dependency and goes back to being what it
  claims to be, a reference manual; its "GUIDE PART N" references are now documentation
  pointers, so a dangling one costs a reader a lookup rather than an audit its severity.
  `install.sh`'s GUIDE warning is softened to match. The ladder now has a canonical home and a
  summary in GUIDE PART 3, which is a duplication the kit must keep honest — the summary is
  explicitly marked as a summary. `_shared/` relies on undocumented (though verified) Claude
  Code behaviour: if a future version starts warning about non-skill directories under
  `.claude/skills/`, the file moves and the four references change with it.

## ADR-0011 — /gate delegates the commit-time audits to subagents · 2026-07-22 · Accepted

- **Context** — GUIDE PART 9's per-change gate was four separate invocations (the reviewer
  plus three doc audits) before every commit; nobody runs four commands per commit, so the
  gate existed mostly on paper. A `/gate` command was reserved as the fix — but every kit
  skill is `disable-model-invocation: true`, so a gate skill cannot model-invoke the others.
- **Options** — (a) keep the loop manual and documented; (b) `/gate` restates the four
  audits' instructions in its own body; (c) `/gate` reads each skill's audit section at
  runtime and hands it to a subagent (the reviewer as itself + three general-purpose),
  merging under `_shared/audit-ladder.md`.
- **Decision** — (c).
- **Why** — (a) is the status quo that made the gate theoretical. (b) is four copies of
  runtime instructions hand-synced across files — the drift ADR-0002 and ADR-0010 exist to
  prevent, and worst where a drifted copy silently changes what an audit checks. (c) adds
  zero duplication, and subagents are the kit's own token-hygiene rule (GUIDE PART 4): four
  audits inline would pull four SKILL.mds, three documents and the diff into the main
  context. Scope is the commit-time gate only; `/audit-history` stays the separate ship
  gate, so the two cadences (every commit vs leaving the machine) stay apart.
- **Consequences** — the ladder's consumer list gains a real `/gate`; the gate inherits any
  future change to a skill's audit section automatically (it reads, it does not copy); a
  `/gate` run costs four subagent contexts, accepted as the price of one-command adoption.

## ADR-0012 — Template cleanup runs in CI, double-guarded · 2026-07-22 · Accepted

- **Context** — the "Use this template" button copies the whole tree, so every generated
  repo starts with attest's README, LICENSE, docs/, scripts/ and install.sh, and the README
  asks the user to delete them by hand ("First 5 minutes"). Humans skip steps; Phase 7
  showed exactly this class of leftover shipping downstream.
- **Options** — (a) manual steps only; (b) a cleanup workflow guarded by
  `is_template == false`; (c) the same workflow guarded by **both** `is_template == false`
  **and** `github.repository != 'radozaprazny/attest'`, with `workflow_dispatch` as a
  manual fallback.
- **Decision** — (c).
- **Why** — (b) is one GitHub toggle away from deleting attest's own README, docs/ and
  install.sh: un-check "Template repository" and the guard opens. The hard repo-name check
  cannot be toggled off by accident. `workflow_dispatch` exists because repo-creation
  pushes do not reliably fire the `push` event. The LICENSE is rewritten to a bare MIT
  skeleton with `<YEAR>`/`<YOUR NAME>` and **no** warning header — the devlog records that
  a header broke GitHub's licence detection and was reverted; the instruction lives in the
  stub README instead.
- **Consequences** — generated repos start clean without reading anything; the workflow
  deletes itself after running; attest carries a workflow that must stay inert at home —
  the double guard is load-bearing and must survive refactors. Users who disable Actions
  fall back to the README's manual steps, which stay.

## ADR-0013 — Lead the README with real audit results and an adoption gradient · 2026-07-22 · Accepted

- **Context** — the README promised governance and showed nothing; a fresh-user audit read
  it as "much promise, no evidence", and the five-document framing read as all-or-nothing.
  The dogfood results existed, written down in the devlog.
- **Options** — (a) leave it; (b) fabricate a terminal transcript as a demo; (c) lead with
  the four real dogfood results, sourced strictly from `attest-devlog.md`, plus an explicit
  adoption gradient (minimum viable attest = three documents).
- **Decision** — (c).
- **Why** — (b) is disqualifying: a compliance kit faking an audit output in its own public
  README is the exact failure it exists to prevent. (a) leaves adoption to faith. The
  gradient lowers the entry cost honestly — the three-document minimum is real (the skills
  degrade to a note when a document is absent), and the Adopt column lives inside the
  enumeration ADR-0002 already sanctions, so it opens no new duplication site.
- **Consequences** — the README now carries claims pinned to the devlog record; if the
  dogfood is ever re-run with different results, the README changes with it. GUIDE PART 1
  carries the gradient as canonical prose; the README table only labels it.

## ADR-0014 — Add local-app as a sixth archetype · 2026-07-22 · Accepted

- **Context** — the archetype table had five rows; a local GUI/desktop/mobile app — runtime
  users, often local personal data, but neither a `cli` (a tool) nor a `service`
  (network-facing) as the table defines them — fell through to the "plain label of your
  own" escape hatch, forfeiting the tailored template and question set for a genuinely
  common kind of software.
- **Options** — (a) keep five rows and the escape hatch; (b) widen `cli`'s definition to
  cover anything running on the user's machine; (c) add **local-app** as a sixth row with
  its own question extensions.
- **Decision** — (c).
- **Why** — (a) forfeits the feature exactly where the sharpest questions exist (what data
  stays on the device, what leaves via telemetry/sync/crash reports). (b) muddies `cli`'s
  own sharpest probes — destructive operations on files the user names — with GUI-app data
  concerns; one row cannot carry both well. The escape hatch stays for what still fits
  nothing.
- **Consequences** — the table, the question bank, the template's archetype line and GUIDE
  3.1 each grow by one row; ADR-0001 is untouched — the archetype remains a trigger, never
  the legal tier, for six labels as for five.

## ADR-0015 — Install Python tooling only into Python projects · 2026-07-22 · Superseded by ADR-0027

- **Context** — the kit claims to be language-agnostic, but `install.sh` unconditionally
  landed `ruff.toml` and a `.ruff_cache/` gitignore line into every target — Python residue
  in a JS or Rust repo, flagged by the fresh-user audit as the kit's one systematic
  off-note.
- **Options** — (a) keep copying always; (b) move the ruff pair out of the kit into an
  `examples/` directory; (c) copy the Python tooling only when the target shows Python
  markers (`pyproject.toml` / `setup.py` / `setup.cfg` / `requirements.txt` / any `*.py`
  outside `.claude/`).
- **Decision** — (c).
- **Why** — (a) ships residue and undercuts the language-agnostic claim. (b) breaks the
  working out-of-the-box Python experience and the documented "two files, one swappable
  unit" story for no gain. (c) keeps both: a Python repo gets the working unit, everyone
  else gets a SKIPPED line pointing at the GUIDE PART 2 swap instructions. The `.claude/`
  exclusion in the marker scan matters — the kit's own hooks are `.py` and would otherwise
  make every target look like Python.
- **Consequences** — one more heuristic to keep honest as the kit grows; the format hook
  still installs everywhere (its `.py` filter keeps it inert), so a project that later
  gains Python only needs the config, not a reinstall.

## ADR-0016 — /gate appends a dated run record under .attest/ · 2026-07-22 · Accepted

- **Context** — every audit is hard-coded "the audit writes nothing", and the rule was
  carried over to the record of the run itself: a kit named *attest*, sold on "answer the
  questions an auditor asks", produced no evidence that any audit ever ran — no dated
  artifact, no SHA, no verdict on disk. The devlog itself notes audits vary on secondary
  findings across runs, so an un-recorded run's actual output is simply gone. An external
  analysis named this the kit's most important design hole.
- **Options** — (a) keep write-nothing absolute (status quo); (b) every audit writes its own
  log; (c) only `/gate` — the merge point — appends one dated record per run under
  `.attest/`, while the individual audits and all control documents stay untouched.
- **Decision** — (c).
- **Why** — write-nothing exists to protect the **control documents** from unattended edits;
  a run record is not a document change, and stretching the rule over it confused two
  different protections. (b) makes four artifacts per gate and burdens standalone audits,
  which often run exploratorily. (c) writes at exactly the place the passes converge, once
  per run, and the record is append-only by construction (one file per run, never edited).
- **Consequences** — `.attest/` appears in gated repos and is meant to be committed with the
  gated change ("the gate ran" becomes a fact in history). The record holds the verdict
  summary only — never findings' full text, never a fact whose home is a control document —
  or it would become a sixth document by the back door. The ladder's "writes nothing" line
  now carries the one sanctioned exception explicitly.

## ADR-0017 — The gate's document audits run read-only by capability · 2026-07-22 · Accepted

- **Context** — ADR-0011 ran the three document audits as **general-purpose** subagents
  (full toolset, including Edit/Write and Bash) while `/gate` described them as "each
  read-only" — a promise in prose, not a property. The reviewer already strips Edit/Write
  but keeps Bash, which can write (`sed -i`, `git commit`). For a kit whose pitch includes
  "the audit writes nothing", the guarantee was purely instructional.
- **Options** — (a) keep general-purpose + instruction; (b) strip Bash from every audit
  pass, reviewer included; (c) a dedicated `doc-auditor` agent (`Read, Grep, Glob` — no
  Bash/Edit/Write) for the three document audits, with `/gate` writing the scoped git
  material (diff, untracked list, log) to temp files the agent Reads; the reviewer keeps
  Bash and says honestly that its read-only is a rule, not a capability.
- **Decision** — (c).
- **Why** — (a) is the rhetoric/enforcement gap itself. (b) breaks the reviewer's contract —
  it must *run* the project's tests and lint, which is Bash by definition; a reviewer that
  cannot execute verifies nothing. The document audits, by contrast, only ever *read* — the
  one thing they needed Bash for was `git`, and the gate already scopes the diff in the main
  context, so handing it over as files removes the last reason to arm them.
- **Consequences** — `/gate` step 1 grows a material-preparation step (redirected to files,
  so the diff still never enters the main context); a `doc-auditor` absent in an older
  install degrades to the previous general-purpose path, stated in the verdict; the
  standalone audit modes (run inline in the main context) still use git themselves.

## ADR-0018 — Version the kit inside the audit ladder; install.sh reports drift · 2026-07-22 · Accepted

- **Context** — the kit had no version identifier anywhere (no file, no tag, no field), and
  `install.sh` is copy-if-absent: a project that installed v1 of a skill keeps it forever,
  reported identically to a user-customized file — installs froze silently, and an adopter
  could not say which version of the ladder audited them.
- **Options** — (a) a `VERSION` file at the kit root; (b) git tags only; (c) a
  `Kit version:` line inside `.claude/skills/_shared/audit-ladder.md`, plus `install.sh`
  telling every skipped kit-owned file apart by content: *identical to the kit's* (re-run)
  vs *DIFFERS — diff by hand to upgrade*.
- **Decision** — (c).
- **Why** — (a) is attest identity at the root: template-cleanup would have to delete it,
  `install.sh` does not copy root files into targets, so installed projects would carry no
  version at all — the one place it matters. (b) does not travel into installs either.
  (c) rides the vehicle ADR-0010 already built: the ladder installs with every audit
  consumer, so the version in a project is by construction the version its audits used, and
  it can never desync from the contract it labels. The cmp-based drift note turns silent
  staleness into a SKIPPED line that says so — no interactive `--upgrade` machinery, same
  never-clobber covenant.
- **Consequences** — bumping the version is part of cutting a release (a standing note in
  `attest-progress.md`); `install.sh` prints the version and `/gate`'s run record cites it;
  the user-owned document templates (`CLAUDE.md`, `BUSINESS.md`, …) keep the plain "your
  document kept" message — differing there is normal life, not drift.

## ADR-0019 — attest gates itself: a live CI on the kit's own repo · 2026-07-22 · Accepted

- **Context** — the kit's thesis is "audits that gate", yet its own repo ran no automatic
  check at all: `.github/workflows/` held only template-cleanup, `ci.yml.example` is
  deliberately all-comments for adopters, and the baseline (`smoke.sh`, ruff, shellcheck)
  lived in `attest-progress.md` as manual commands.
- **Options** — (a) status quo, manual baseline; (b) activate `ci.yml.example` as-is;
  (c) a separate live `ci.yml` — ruff + shellcheck + `scripts/smoke.sh` — hard-guarded with
  `github.repository == 'radozaprazny/attest'` and deleted downstream by template-cleanup.
- **Decision** — (c).
- **Why** — (a) is the preach/practice gap. (b) fails twice: the example never ran
  `smoke.sh` (it mirrors an *adopter's* baseline, and their project has no `scripts/`), and
  un-commented it would run unguarded in every generated repo. (c) keeps "attest ships no
  live CI *for your code*" true — the guard makes the job inert anywhere but attest, and
  the cleanup removes the file — while attest itself finally has a blocking check.
- **Consequences** — the cleanup's `rm` list and the README's manual-delete list grow by one
  file; the CI is red/green on every push and PR, but *blocking a merge* additionally needs
  branch protection, which is a GitHub setting, not repo content — enabling it is a standing
  item in `attest-progress.md`.

## ADR-0020 — an installed kit file is judged by content, never by a predicate that its own presence satisfies · 2026-08-11 · Accepted

- **Context** — a full audit of the kit found two messages that were false on a re-run.
  `install.sh` decided `ruff.toml` with `has_ruff_config`, which is true whenever
  `$TARGET/ruff.toml` exists — including the copy the kit itself had installed. Every re-run
  into a Python project reported the kit's own byte-identical file as *"you already configure
  ruff"*, and the ADR-0018 identical/DIFFERS ladder was unreachable for it, so a changed
  upstream `ruff.toml` could never be reported as drifted. The `settings.json` warning had the
  same shape: it fired on any byte difference and claimed *"hooks are on disk but NOT wired"*,
  which is untrue for an older kit stanza that registers all three hooks.
- **Options** — (a) leave it, document the quirk; (b) special-case a re-run by remembering
  what we installed (a manifest); (c) ask the file itself: judge a present file by content,
  and only then fall back to predicates.
- **Decision** — (c). `ruff.toml` present → `cmp` against the kit's (identical → re-run,
  otherwise → DIFFERS, with the override warning kept in the message); only if it is absent do
  `.ruff.toml`/`pyproject.toml` decide. `settings.json` → grep the kept file for each hook
  filename; warn only about hooks it really leaves unregistered, and otherwise say plainly
  that it differs but is wired.
- **Why** — (b) adds state the kit deliberately does not keep (no manifest, no lockfile: the
  never-clobber covenant is stateless by design). (c) needs nothing but the bytes already on
  disk, and it restores the property ADR-0018 was written for: every kit-owned file, without
  exception, reports identical-or-drifted on a re-run. A warning that is false in the common
  case is worse than no warning — it teaches the reader to skip the report.
- **Consequences** — `has_ruff_config` no longer answers "is there a ruff.toml"; its name now
  means *"configured somewhere other than ruff.toml"*, and its regex lost the `\1`
  backreference (a GNU extension, undefined in POSIX ERE — it also matched `[tool.ruffle]`).
  Four new smoke assertions cover the re-run, the drift, the two pyproject forms, and the
  wired-but-differing settings case.

## ADR-0021 — `ci.yml.example` ships to consumers; it is the one file under `.github/` that is theirs · 2026-08-11 · Superseded by ADR-0031

- **Context** — the file says *"opt-in CI for your project. Rename to `ci.yml` and adapt"*,
  but neither adoption path delivered it: `install.sh` copies nothing from `.github/`, and
  template-cleanup deleted it as attest identity. It existed only for people browsing attest's
  own repo — an instruction addressed to a reader who does not have the file.
- **Options** — (a) delete it and put the example in GUIDE PART 8 as a fenced block;
  (b) keep it where it is and document that it is browse-only; (c) ship it through both paths.
- **Decision** — (c): `install.sh` copies exactly `.github/workflows/ci.yml.example`, and the
  cleanup leaves it in place.
- **Why** — (a) loses the property that makes it useful: a file you rename beats a block you
  retype, and being *inert as shipped* (100% comments) is what makes shipping it safe — a
  consumer's Actions do nothing until they act. (b) is the status quo with a nicer name.
  The "never copy `.github/`" rule was a proxy for "never install attest's own CI", and that
  rule is preserved exactly: `ci.yml` stays behind, the example travels.
- **Consequences** — GUIDE PART 8's install list and README's manual-cleanup list both change;
  the example now also demonstrates the two habits attest's own CI follows (pin the tool
  version, pin actions by SHA), since an unpinned example teaches an unpinned gate.

## ADR-0022 — the template cleanup removes attest's files by name, from a script that CI lints and smoke tests · 2026-08-11 · Accepted

- **Context** — the cleanup ran `rm -rf docs scripts` and `cat > LICENSE` unconditionally,
  behind a sentinel that only checked attest's README heading and `install.sh`. Repo-creation
  pushes do not reliably fire, so a user's first pushes can land before the workflow ever
  runs: their own `docs/`, `scripts/` and `LICENSE` were then deleted or overwritten. The
  in-file comment acknowledged this rather than preventing it. The same block was also the
  only destructive code in the repo that nothing linted and nothing tested — it first executes
  for real in a stranger's repository.
- **Options** — (a) keep the wholesale `rm -rf`, warn harder in the README; (b) require an
  explicit `workflow_dispatch` so it never fires unattended; (c) remove attest's paths by
  name, guard each rewrite with a content check on its own target, and move the logic into
  `scripts/template-cleanup.sh` so CI shellchecks it and `smoke.sh` runs it in a sandbox.
- **Decision** — (c).
- **Why** — (a) documents a hazard instead of removing it, and the README paragraph it needed
  was longer than the fix. (b) breaks the promise that a generated repo cleans *itself*.
  (c) makes lateness harmless, which is the real property wanted: attest's own files are a
  known, finite list, and `rmdir` (never `rm -rf`) leaves any directory that still holds
  something of yours. The identity marker also moves from the README to `install.sh`'s own
  header — replacing the README first is a normal first step and must not be what disables
  cleanup, which was the second half of the same bug.
- **Consequences** — a generated repo carries `scripts/template-cleanup.sh` until the workflow
  removes it together with itself (a script that unlinks itself mid-read is not something to
  rely on). Fourteen smoke assertions now cover the cleanup, including the case that motivated
  the ADR: user files present, workflow fires late, nothing of theirs is touched — not their
  `docs/` or `scripts/`, not their `LICENSE`, and not a `ci.yml` or `smoke.sh` of their own
  (both are names the kit itself invites, so both are removed only on a content match). The cleanup
  also drops `ruff.toml` in a repo with no Python, which is ADR-0015 parity the template path
  never had. A queued second run rebases before pushing rather than failing red.

## ADR-0023 — the ownership contract resolves both of its own collisions, and `nit` survives the merge · 2026-08-11 · Accepted

- **Context** — the contract's stated purpose is that one hunk is flagged once, and its
  motivating example is *one new dependency* — but the table gives "a new dependency" to
  `/decision` and "a new model / data source" to `/compliance`, with a tiebreak written only
  for the `/business` ↔ `/audit-history` edge. Two doc-auditors handed only their own section
  plus the ladder would both claim an analytics SDK, or both defer. Separately, the reviewer
  legitimately emits `nit`, the ladder excludes `nit`, and `/gate` requires every merged
  finding to carry a ladder severity — so the gate's merge step had no defined move.
- **Options** — (a) give the dependency wholly to `/decision`; (b) split by aspect and accept
  two findings on one hunk; (c) regulated ground wins when both conditions hold, and the
  losing audit's point becomes one clause of the winner's finding.
- **Decision** — (c) for the edge; and `nit` passes through `/gate` unchanged — listed last,
  counted in its own column of the run record, never able to move the verdict line.
- **Why** — (a) hides the larger consequence behind the smaller one. (b) is the noise the
  contract exists to prevent. (c) keeps exactly one owner because the two conditions are
  mutually exclusive by construction, and loses no information. Promoting a nit to minor would
  inflate the ladder the kit tells other people not to inflate; dropping it silently would
  discard a real (if cosmetic) reviewer finding.
- **Relates to** — completes ADR-0004's ownership table (which resolved only the
  `/business` ↔ `/audit-history` edge and left this one open) and extends ADR-0005's nit rule
  from "not on the ladder" to "and here is what happens to one at the merge point". Neither is
  reversed, so neither flips `Status`; this entry is where a reader of either should land.
- **Consequences** — the ladder gains a second edge section and a nit rule; the gate's record
  template gains a `nit` count. Both `/compliance audit`'s and `/decision audit`'s
  carve-outs are restated in terms of the edge, so no skill's own text can contradict the
  contract the gate merges under.

## ADR-0024 — hooks act only inside the project, and never leave cache behind · 2026-08-11 · Superseded by ADR-0027

- **Context** — the format hook filtered on `.py` alone. Claude edits files outside the repo
  (another checkout, a script in `$HOME`), and ruff resolves config by walking up from the
  target, so those files were silently reformatted under ruff's defaults or a foreign
  project's rules — invisibly, since the hook drops all output. And because Python detection
  happens at install time only, a repo that gained Python later ran the wired hook with no
  `ruff.toml` and minted a `.ruff_cache/` its `.gitignore` had no line for.
- **Options** — (a) document both as known edges; (b) make the hook refuse to run without a
  resolvable `ruff.toml`; (c) contain it to `CLAUDE_PROJECT_DIR` and pass `--no-cache`.
- **Decision** — (c). Unset `CLAUDE_PROJECT_DIR` still fails open, like every other branch of
  this hook.
- **Why** — (b) would break the legitimate `pyproject.toml`-configured project, which is the
  configuration `install.sh` explicitly respects. (c) fixes both symptoms where they start:
  a hook that reformats files in a project nobody asked about is a trust problem, not a
  cosmetic one, and a per-edit run of a single file gains nothing from a cache worth writing.
- **Supersedes in part** — ADR-0015's closing clause, *"a project that later gains Python
  only needs the config, not a reinstall"*. That was true of the config alone and false of the
  `.gitignore` line the same repo also lacks, so the honest instruction is the re-run. ADR-0015
  otherwise stands in full: Python tooling still installs only into Python projects.
- **Consequences** — GUIDE PART 2 now states that adding Python later calls for a re-run of
  `install.sh` (copy-if-absent, so it adds exactly the two missing pieces); manual
  `ruff check .` still caches normally. Smoke asserts all three properties with a fake `ruff`
  on `PATH`, so the assertion needs no real ruff and no network.

## ADR-0025 — GitHub Actions are pinned by commit SHA, in the kit's CI and in the example it ships · 2026-08-19 · Accepted

- **Context** — every workflow used `@v4` / `@v5`. A tag is a mutable pointer: whoever
  controls it can change what runs, and `template-cleanup.yml` runs with `contents: write` and
  pushes a commit into someone else's repository. The audit rated this info-level, which is
  fair for a private kit — but `ci.yml.example` is *teaching material*, and an unpinned example
  propagates the habit into every repo that adopts it.
- **Options** — (a) tags everywhere, note the risk in a comment; (b) SHA-pin the write-token
  workflow only; (c) SHA-pin all three, with the version as a trailing comment.
- **Decision** — (c).
- **Why** — (b) is where the concrete risk is, but it leaves the kit teaching one thing and
  doing another two files away, and the example is the file most likely to be copied. (c)
  costs a lookup when bumping a version and buys a build that cannot change under us. The
  trailing `# v4` comment is what keeps it maintainable: the SHA is the contract, the comment
  is for humans reading the diff.
- **Consequences** — bumping an action is now a two-step (resolve the tag to a SHA, update the
  comment) and belongs to the same release ritual as the `Kit version:` bump; nothing verifies
  the pins automatically, so a stale pin is a maintenance debt, not a failure. The example
  states the reason inline so an adopter who prefers tags is making a choice rather than
  inheriting one.

## ADR-0026 — `.attest/` holds append-only records plus one ignored scratch directory · 2026-08-19 · Accepted

- **Context** — ADR-0016 scoped `.attest/` as an append-only log of run records, meant to be
  committed with the change it gates. The gate's new degrade path needs somewhere inside the
  repo to write git material when a subagent cannot read an out-of-tree temp dir — and it
  reached for `.attest/tmp/`, silently giving the directory a second, contradictory purpose:
  the kit's own `/gate` run flagged this against its own ladder ("the gate's only write").
- **Options** — (a) drop the in-repo fallback and let the pass degrade when `/tmp` is
  unreadable; (b) write the scratch somewhere else in the repo; (c) keep `.attest/tmp/`, name
  the carve-out, ignore it in git, and require the run that creates it to delete it.
- **Decision** — (c).
- **Why** — (a) loses a pass for an environment reason, which is exactly what "degrade, never
  fail" exists to avoid. (b) needs a second directory and a second `.gitignore` line for one
  transient use. (c) keeps one directory for one concept — *everything this gate produced* —
  and the distinction that matters (a record is committed, scratch never is) is enforced by
  `.gitignore` rather than by discipline. `install.sh` now lands the ignore line in every
  install, so a consumer cannot commit scratch even on the first run.
- **Consequences** — "the gate's only write" is no longer literally true and the ladder says
  so precisely; readers of `.attest/` must know one subdirectory is not a record. The rule is
  stated in both the ladder and the gate's step 5 so a doc-auditor handed either sees it.

## ADR-0027 — the kit ships no formatter: attest audits, it does not edit · 2026-08-28 · Accepted

Supersedes: ADR-0015, ADR-0024

- **Context** — the kit shipped a `PostToolUse` hook (`format_py.py`) plus `ruff.toml`: after
  every `Edit`/`Write` of a `.py` file it lint-fixed imports and reformatted. It was the only
  thing in the kit that **modified the user's code**, the only thing **bound to one language**,
  and the source of a disproportionate share of the kit's own complexity — ADR-0015 (install
  it only into Python projects), ADR-0020 (judge an installed `ruff.toml` by content),
  ADR-0024 (contain it to the project, `--no-cache`), a `has_ruff_config` predicate, a
  template-cleanup parity branch, a `.ruff_cache/` ignore line, and a paragraph in the shipped
  `CLAUDE.md` that every reader pays for. Its actual value is near zero in the common case: a
  project that formats already has this configured, and one that does not has no agreed format
  for the hook to enforce.
- **Options** — (a) keep it, document the swap better; (b) keep the hook, drop `ruff.toml` and
  let the project's own config decide; (c) drop the whole unit — hook, config, detection,
  cleanup parity and the `.gitignore` line.
- **Decision** — (c).
- **Why** — (a) is the status quo and the status quo is where all that machinery came from.
  (b) still runs a formatter after every edit, which is the wrong *moment* regardless of whose
  rules it uses: formatting belongs to a commit hook or CI, not to each keystroke of an agent.
  (c) is the only option that matches what the kit *is*. attest's claim is that a repo can
  attest to what it declared — reading, judging, recording. A component that silently rewrites
  the artifact under audit is a different product, and its removal takes five other decisions
  with it. It also removes the last interpreter dependency from **what the kit
  installs**: both remaining hooks are POSIX `sh`, so a consumer needs nothing beyond `git` and
  `/bin/sh`. (`install.sh` and `scripts/*.sh` are still bash — they run once, at the author's
  keyboard, and nothing they leave behind depends on them.)
- **Consequences** — supersedes ADR-0015 and ADR-0024 (both existed only to contain this
  hook); ADR-0020's *principle* survives, only its worked example is gone. Projects upgrading
  keep whatever `ruff.toml` they have — the installer never deletes, so removal is a one-line
  `rm` they make themselves. The kit's **own** `.gitignore` loses its whole Python block
  (`.venv/`, `__pycache__/`, `*.py[cod]`, `*.egg-info/`, `.pytest_cache/`, `.ruff_cache/`), not
  just the ruff line — after this there is no Python in the repo for any of them to match;
  only the `.ruff_cache/` line was ever installed into consumers. The shipped `CLAUDE.md` now
  asks for **your** format command in
  the "Formatting and lint" section, which is strictly more useful: the `reviewer` subagent
  derives conventions from that file, so writing it there makes the review run the same
  command you do. A project that wants edit-time formatting still can — it is one `PostToolUse`
  entry, and GUIDE PART 2.3 says so.

## ADR-0028 — a hook must prevent, not remind: two guards replace two nags · 2026-08-28 · Accepted

- **Context** — after ADR-0027 removed the formatter, the two remaining hooks were both
  advisory. `precompact_checkpoint_nudge` fired just before compaction to say the
  thread-carrier was stale — at a moment the user cannot act on, since compaction is already
  under way. `stop_session_length_warn` counted transcript lines and warned above 500, which is
  a poor proxy for context pressure (one long tool output crosses it without a word being said)
  and duplicates a signal Claude Code shows natively. Meanwhile the two rules the kit cares
  most about were left entirely to memory: a **non-goal** is *always a blocker* on the ladder,
  yet the agent only meets the non-goals when `/gate` runs — after the code exists; and
  `/audit-history` is the ship gate, yet nothing connects it to the command that actually ships.
- **Options** — (a) keep the two nags, tune their thresholds; (b) delete them and ship no hooks
  at all, leaving `settings.json` out of the kit; (c) delete them and spend the two events on
  prevention instead — `SessionStart` to load the declaration, `PreToolUse` on `Bash` to guard
  the ship boundary.
- **Decision** — (c).
- **Why** — the test a hook has to pass is *does this do something a skill cannot?* A reminder
  fails it: the user can already see a long session, and `/checkpoint` exists. Prevention passes
  it decisively. Loading non-goals at session start moves a blocker-severity rule from
  **detection** to **prevention**, and it is a hook precisely because a skill can be forgotten
  and a session start cannot. The ship guard makes the kit's own ship gate real at the one
  moment it becomes irreversible. (b) was tempting for leanness but throws away the two places
  where the harness genuinely beats a prompt.
- **Consequences** — `/audit-history` now writes one artifact, a dated run record under
  `.attest/ship-…-<short HEAD sha>.md`, so the guard can ask *"was THIS state audited"* rather
  than *"was this repo ever audited"*; the ladder's "every audit writes nothing" clause is
  amended to name both records (the gate's and the ship gate's) and to say the document audits
  still write nothing at all, because they hold no `Write` tool (ADR-0017). The guard **asks**
  via `permissionDecision: "ask"` and never blocks: a guard that cannot be overridden gets
  deleted, one that names what is missing gets used. Its command list is deliberately literal
  and is meant to be edited per project. Both hooks are POSIX `sh` and fail open — an
  unparseable payload, a missing document or a non-git directory lets everything proceed.
  Two invariants the kit's own gate had to teach it, both now pinned by `smoke.sh`: the
  declaration hook caps **per section** (24 non-goals / 8 state / 8 next) rather than once over
  the whole block — a single trailing `head` silently dropped whichever section came last and
  the closing tag with it — and each trimmed section says how much it dropped; and the ship
  guard's `--dry-run` bypass applies only to a **simple** command, because in a compound one
  (`git push --dry-run && git push origin main`) the flag may belong to a different call than
  the one that ships.

## ADR-0029 — three bare rungs: the middle rung loses its domain alias · 2026-08-28 · Accepted

Supersedes: ADR-0005

- **Context** — ADR-0005 gave the shared middle rung a per-skill flavour: *major (scope creep)*,
  *major (undocumented decision)*, *major (posture gap)*, *major (PII / client name)*. In
  practice every merged finding also carries its **owner** — the ownership contract requires it —
  so the alias restated the owner in different words, and a reader had to learn two vocabularies
  to read one verdict. It also made the ladder's own table longer than the rule it encodes.
- **Options** — (a) keep the aliases; (b) keep them but only outside `/gate`, where no owner
  column exists; (c) drop them everywhere — three bare rungs, and let the finding's one-line
  description carry the flavour.
- **Decision** — (c).
- **Why** — (b) is the worst of both: the same finding would be named differently depending on
  how it was invoked. (c) costs nothing that is not already on the line — the owner is printed,
  and *what kind of problem this is* is exactly what a one-line description is for. Shorter
  ladder, one vocabulary, same information.
- **Consequences** — supersedes ADR-0005 (its 3-rung structure survives; only the alias is
  withdrawn). `nit` is unaffected and still lives only in the `reviewer` (ADR-0005's other half,
  reaffirmed by ADR-0023). Four `SKILL.md`s lost an alias from their verdict list; anyone with
  older run records will see both vocabularies in `.attest/`, which is harmless — records are
  append-only history, not a live contract.

## ADR-0030 — compliance is opt-in, and `/business` makes the call · 2026-08-28 · Accepted

- **Context** — every install landed `COMPLIANCE.md` and `/compliance`, regardless of scope.
  For the majority of projects that is a template nobody fills, and an unfilled posture file is
  actively worse than an absent one: it reads as *"posture declared"* to every later audit while
  declaring nothing. The deeper problem is timing — **at install time nobody knows the
  archetype yet**. Asking "are you in regulated scope?" before the project has said what it is
  is a question posed at the wrong moment, which is also why an interactive install menu was
  rejected.
- **Options** — (a) keep installing it always; (b) an interactive prompt during install; (c)
  install it never and document the manual copy; (d) an opt-in flag plus a recommendation from
  `/business`, which is the first step that actually knows the archetype.
- **Decision** — (d): `install.sh --compliance`, and `/business` ends by making the call.
- **Why** — (b) breaks non-interactive installs and asks too early. (c) leaves the regulated
  case — the kit's differentiator — worse served than the common one. (d) puts the decision at
  the only point where it is answerable, and the answer is cheap either way: a re-run adds the
  pair (copy-if-absent fills exactly the gap), and being out of scope produces a **recorded
  sentence** rather than an empty file. Uncertainty is told to resolve toward installing it —
  an unused skill costs a directory, an unowned posture costs a finding nobody files.
- **Amends in part** — ADR-0023's *"exactly two mutually exclusive conditions, so exactly one
  owner exists"* on the `/decision` ↔ `/compliance` edge. That held while `/compliance` was
  always installed. The edge now has **three** conditions and the ownership contract a
  re-assignment table; ADR-0023 is not reversed and keeps its `Status` — a reader landing there
  should land here next.
- **Consequences** — the ladder gains a rule for the absent case, and it is **total**: a hunk
  goes to `/decision audit` if a choice sits behind it, to `/audit-history` if it is bytes, and
  otherwise to `/business audit` — a bare new personal-data field is none of the first two, and
  an enumerated fallback let exactly that fall through (the kit's own second gate caught it).
  That last row is a deliberate carve-out from `/business audit`'s *"non-goals only"*: what is
  missing in that case is a **declaration**, which is its subject matter. It applies only while
  `/compliance` is absent and is written **inside** the skill's Mode 3, because that is the
  section `/gate` hands to the subagent — a rule stated anywhere else in the file never reaches
  the pass that must apply it. For the same reason the *"the compliance call may need
  re-making"* pointer is a step of Mode 3 and not only of the bootstrap section: it is a
  pointer, never a finding, and it never moves the verdict line. Beyond that, the nearest audit
  reports the hunk **once** with a clause naming what it would have been — never two findings,
  never silence. **The fallback rows carry no severity of their own.** An inherited finding is
  scored by the ladder exactly as it would have been: the always-a-blocker floor
  (special-category or national-ID personal data, an Art 5 practice) stands, everything else on
  the row is major. The alternative — letting `/business audit` fix the rung at major, which is
  how this was first written — meant that *removing* `/compliance` silently downgraded a
  blocker, the precise opposite of what this entry promises. `/decision audit`'s row never fixed
  one, so leaving both to the ladder also keeps the two rows symmetric. A present-but-unfilled
  `COMPLIANCE.md` is the template path's default, so `/compliance audit` says so **before** its
  per-diff trigger and `/business` says so when it makes the call — an empty posture file that
  nobody ever points at is the same silence by another route. `/gate` counts its passes from what is on disk and
  distinguishes *"not installed"* from *"skipped"*. The template-button path deliberately
  disagrees with the installer and keeps both files: a generated repo has no `install.sh` to
  re-run, so deleting them would be the one state a user cannot undo — `/business` closes that
  gap from the other side by recommending their removal when the archetype says out of scope.

## ADR-0031 — the installer reports capabilities, not files; and ships nothing inert · 2026-08-28 · Accepted

Supersedes: ADR-0021

- **Context** — a fresh install printed 23 lines of relative paths under `INSTALLED`, then a
  `SKIPPED` list, then the next steps. The paths are the least useful thing a reader needs: they
  answer *what files exist* when the question is *what can I do now, and what do I have to look
  at*. A re-run printed the same wall to say nothing had happened. Two of the 23 items were
  `.mcp.json.example` and `.github/workflows/ci.yml.example` — files that do nothing until
  renamed: the MCP stub taught nothing the GUIDE's four-line shape does not, and the CI example
  was entirely commented out, needed its own ADR (0021) to survive template cleanup, and is
  inert in any repo without a remote.
- **Options** — (a) keep the path list, reorder it; (b) group by path prefix (`.claude/…`,
  root docs); (c) group by **capability**, with per-file detail only when a human must act;
  and separately (d) keep vs. (e) drop the two `.example` files.
- **Decision** — (c) and (e).
- **Why** — (b) still answers the wrong question. (c) makes the report say what changed *for
  you*: one line per group with `✓` landed / `·` already there / `⚠` look at this, a **YOURS,
  UNTOUCHED** block for files the kit also ships and left alone — the designed outcome, never a
  warning — and a **NEEDS YOU** block for the rare real action (a kit-owned file that drifted,
  a hook on disk your `settings.json` leaves unwired). A run that changed nothing says exactly
  that in one line. On (e): a file that requires a rename to do anything is a documentation
  example living in the wrong medium; the habits worth teaching from `ci.yml.example` — pin the
  tool version, pin actions by SHA — are three lines of prose, and they were written: GUIDE
  PART 8, *"If you add CI of your own"*. Removing the file without writing them would have made
  this entry's own justification false, which the gate's `/decision audit` caught.
- **Consequences** — **ADR-0025's consumer-facing half lapses with this entry**: its rule was
  *"pin by SHA in the kit's CI **and in the example it ships**"*, and there is no shipped example
  any more. It stays `Accepted` because its live half — attest's own workflows — is unchanged;
  the habit reaches adopters as prose in GUIDE PART 8 instead of as a file. Also: supersedes
  ADR-0021; `install.sh` now copies **nothing** from `.github/`,
  which makes the rule simpler than the exception it replaces ("none of it is written for the
  consumer"). The report's column padding is done on the **label only**, never on the content:
  `printf` counts bytes, and a `·` separator in a content column silently shifts every row after
  it. The drift/identical ladder (ADR-0018, ADR-0020) is unchanged — it now feeds the two detail
  blocks instead of a flat `SKIPPED` list, and a kept document of yours is classified as
  *untouched*, not as something to merge. `--compliance` is parsed alongside the target path in
  any order, and an unknown option is rejected rather than treated as a directory.

## ADR-0032 — a gate run record may be written late, and says so in its own first line · 2026-08-28 · Accepted

- **Context** — the phase-11 series was gated four times on one uncommitted tree. The second
  run's record was not written when it happened: the findings were fixed immediately and the
  record was only noticed as missing two runs later. ADR-0016 and ADR-0026 define `.attest/` as
  append-only, one file per run, `gate-<UTC yyyymmdd-HHMMSS>-<sha>.md` — neither says what the
  timestamp *means* or whether a record may be added afterwards. The kit's whole claim is that
  a record makes *"the gate ran"* a fact rather than a memory, so an unrecorded run is a hole in
  exactly the thing being sold.
- **Options** — (a) leave the gap: a run with no record simply did not happen for the record's
  purposes; (b) write it with a back-dated, plausible-looking run time; (c) write it late, put
  the *write* time in the filename, and say in the record's first line that it is late and why.
- **Decision** — (c).
- **Why** — (a) is the tidiest and the least honest: the gap is invisible, so a reader counts
  three runs where four happened. (b) is the option this kit exists to prevent — a fabricated
  timestamp inside an attestation artifact is worse than no artifact, and nothing downstream
  could ever tell it from a real one. (c) costs one line of prose and keeps the chain complete;
  the record is weaker evidence than a contemporaneous one, and it says so itself, which is the
  correct amount of trust to invite.
- **Consequences** — **name order in `.attest/` is write order, not run order.** Anything that
  scoped itself by "the newest name" — `/gate` step 1, `/business audit` Mode 3 step 2 — must
  match on the **HEAD sha inside the name** instead; both now say so. `/gate` step 5 gains the
  rule so the next late record does not have to re-derive it. The permitted deviation is narrow:
  a late record may differ from the shipped template only in its first line and its heading, and
  it may never be written for a run that did not happen — this entry sanctions honesty about
  timing, not reconstruction from memory.


## ADR-0033 — a ship record is written before the push and committed under a later sha · 2026-08-31 · Accepted

- **Context** — `/audit-history` keys its record on the HEAD being shipped and the `PreToolUse`
  guard matches that sha before a push, so the record must exist *while that HEAD is current* —
  it is an untracked file at the moment the guard reads it. Committing it moves HEAD, so the
  commit that carries a record is itself one no record names. ADR-0016 fixes the filename and
  ADR-0028 fixes what the sha means; neither says where the file sits in history. Phase 11 hit
  it first: `3481531` carries the record for `8a7d45a`, and the question only surfaced because
  the push actually happened.
- **Options** — (a) never commit ship records — leave them local evidence, ignored like scratch;
  (b) commit them, accepting that a record lands under a later sha than the one it names;
  (c) make the names line up — rename the record to its containing commit, or delay writing it
  until after the push.
- **Decision** — (b), stated in the skill rather than left to be re-derived.
- **Why** — (a) makes the guard's evidence unshareable: a reviewer of the PR cannot see that the
  ship gate ran, and `.attest/` exists precisely so *"the gate ran"* is a fact in the repo rather
  than on one machine. (c) is ADR-0032's rejected option wearing a different hat — a filename
  that claims a state nothing actually audited, indistinguishable downstream from an honest one.
  (b) costs exactly one thing, and it is visible and explainable.
- **Consequences** — the record is untracked when the guard reads it **by design**, so the guard
  must keep checking the filesystem and never the index (it already does). Read `.attest/`
  accordingly: `ship-…-<sha>.md` is evidence about `<sha>`, never about the commit it happens to
  sit in — do not infer the audited state from the container. A branch's **final** commit, which
  is typically the one adding the record, is unaudited by construction; where that matters — a
  public release — run `/audit-history` again at that sha and accept that its record lands one
  commit later still, or squash before shipping. The rule is written into `/audit-history`'s run
  record section.

## ADR-0034 — the ship guard leaves a trace, for the pass as well as the ask · 2026-08-31 · Accepted

- **Context** — pushing `3481531`, a sha no record named, produced **no prompt**. Driven by hand
  on the identical payload the guard answers `ask`, so the script was not the suspect. From
  inside the session the two explanations — the hook was never registered, or it fired and the
  active permission mode auto-approved its `ask` — are **indistinguishable**, because a
  `PreToolUse` hook that answers `ask` writes nothing anywhere. The kit's whole claim is that a
  gate having run is a fact rather than a memory, and the guard was the one gate leaving no fact
  behind.
- **Options** — (a) leave it: a guard is a convenience, its firing need not be evidence;
  (b) log only the ask; (c) log every matched command with its decision, into ignored scratch;
  (d) promote it to a committed record.
- **Decision** — (c): one line — UTC timestamp, decision, sha, sanitised command — appended to
  `.attest/tmp/ship-guard.log`.
- **Why** — (a) is the state that produced this entry. (b) still cannot separate *"passed
  silently"* from *"never ran"*, and the silent pass is exactly the case that misled a reader
  here. (d) inflates a routine hook firing into an attestation and would put a line in the repo
  for every push. (c) answers *"did the guard run, and what did it decide"* in one `cat`, costs
  **no new `.gitignore` line** — `.attest/tmp/` is already ignored (ADR-0026) — and cannot be
  mistaken for a record, because it does not carry a record's name and never leaves the machine.
- **Consequences** — **ADR-0026 is narrowed.** `.attest/tmp/` is no longer the gate's private
  scratch to remove wholesale: whatever writes there deletes **its own files**, and a `/gate` run
  deleting the directory would silently erase the guard's trace. Said in `/gate` step 2, `/gate`
  step 5 and the shared ladder, so a doc-auditor handed any of the three sees it. The log is
  unbounded on purpose — the guard only matches publishing commands, so it grows by a line per
  push, and it is ignored and disposable. It carries the same `tr`-sanitised command the reason
  does, so a trace can hold nothing the prompt could not already show. Fail-open like the rest of
  the hook: an unwritable scratch costs the line, never the decision. Smoke pins all of it,
  including that an unmatched command leaves no trace at all.

## ADR-0035 — the ship guard gates the visibility flip, and declares that it does not gate the merge · 2026-09-01 · Accepted

- **Context** — merging PR #4 passed the guard in silence, which looked like a hole and raised
  the obvious fix: add `gh pr merge` to the `case`. Measuring what the list actually covered
  found a different and larger gap — `gh repo edit --visibility public` and `gh repo create`
  were equally silent, and attest's own `Next` list carries *"decide on going public"*.
- **Options** — (a) add `gh pr merge` and leave visibility uncovered; (b) add both; (c) add the
  visibility commands, and write down *why* the merge is out; (d) add neither and treat the push
  as the only boundary.
- **Decision** — (c).
- **Why the merge stays out** — three independent reasons, any one of which would be enough.
  **It would state a falsehood:** at merge time every byte is already on the remote, put there by
  a push this guard did gate, so the prompt's *"sends data off the machine"* would be untrue —
  and a hook that cannot back its own reason is the failure ADR-0034 was written to end, not to
  repeat. **It could never be satisfied:** the merge commit does not exist when the check runs,
  so the only record that could exist names the branch HEAD — accepting it would be a claim about
  a different commit, which ADR-0033 forbade one day earlier. **It would advertise coverage it
  cannot have:** most merges never touch the machine at all — the web button, auto-merge, a
  colleague — so matching the CLI form would leave a reader believing merges are gated when the
  common path is not. A declared gap is worth more than a believed-but-false gate. The merge
  boundary is branch protection plus required CI (ADR-0019), which is server-side and
  path-independent; the guard cannot reach it and should not pretend to.
- **Why visibility comes in** — it is the ADR-0028 test met exactly: the moment the question
  becomes irreversible. A push exposes the tree you just wrote; making a repository public
  exposes **every commit and every old blob**, and a revert does not un-publish them. It is also
  the only entry whose required mode is `/audit-history full` rather than the default, because a
  secret buried in an old commit is precisely that action's risk.
- **Consequences** — the `case` arms now each set what the prompt claims the command does, so
  *"sends data off the machine"* and *"changes who can read this repository"* are never
  substituted for one another. `--visibility private` matches too: narrowing to the value needs a
  second pattern per flag spelling (`--visibility=public`), and this hook's standing rule is that
  an over-match costs a prompt while an under-match costs the gate. `gh repo create` matches
  whole rather than only with `--public`, because creating a repo from a local source pushes the
  history regardless of who can read it. The omission of `gh pr merge` is written in the script
  and in GUIDE 2.3 so the next reader does not "fix" it; smoke pins that it stays silent.

## ADR-0036 — the thread-carrier states what is true of the branch, in a tense the merge leaves standing · 2026-09-01 · Accepted

- **Context** — `docs/attest-progress.md` went false at the merge three times in a row: after PR
  #3 it still said the lean-kit series was *"uncommitted"*, after PR #4 it said *"open as PR #4"*,
  after PR #5 it said *"in progress on `feat/visibility-guard`"*. Each was written correctly and
  each was falsified by the very next event. The cause is structural, not sloppiness: the carrier
  lives **inside** the branch it describes, so it can never describe its own merge — the last
  write precedes the merge by construction, exactly as a ship record cannot sit in the commit it
  names (ADR-0033). It matters more here than there: the `SessionStart` hook loads this file as
  *binding* context (ADR-0028), so the falsehood is read into the next session as a rule.
- **Options** — (a) discipline: remember to fix the carrier after every merge; (b) a rule in
  `/checkpoint` that the next series' first commit cleans the stale section; (c) write the carrier
  in a form the merge cannot falsify — claims about the **branch** (*"committed on `feat/x`;
  PR #7 opened"*), never about a momentary repo status (*"in progress"*, *"PR #7 is open"*);
  (d) move the carrier out of the branch entirely.
- **Decision** — (c), written into `/checkpoint`.
- **Why** — (a) is what already failed three times, and this kit exists to replace discipline
  with mechanism. (b) is still discipline, only deferred, and it leaves the document wrong for
  the whole gap — the window in which a session actually starts and reads it. (d) breaks the
  routing table's one-fact-one-home for no gain and would put status outside review. (c) needs
  **no action at all** to stay true, which is the only property that survives a person forgetting:
  a branch-scoped past-tense claim goes stale — incomplete, still true — rather than wrong, and a
  reader cannot tell a wrong line from a current one, which is precisely why staleness is the
  cheaper failure.
- **Consequences** — `/checkpoint` gains the rule and the two worked examples, and the
  instruction to repair a falsified line **before** layering today's delta on it. The rule is
  generic — any project using branches and PRs has the same shape — so it ships rather than
  living in attest's own notes. Related and left as it is: `/audit-history` gains a plain
  operational line, not an ADR, that the record and the push must be two separate steps, because
  a `PreToolUse` guard judges the state *before* the step it guards runs — one step doing both is
  judged against a world where the record does not exist yet.

## ADR-0037 — the ship guard reads what the record says, not that a file with the right name exists · 2026-09-04 · Accepted

- **Context** — the guard matched `.attest/ship-*<sha>*.md` and stopped there. An external review
  reproduced the consequence: an **empty** record for HEAD opens the door, and so does one whose
  verdict is `blocker`. The hook's own prompt offers to *"approve to ship unaudited"*, which only
  makes sense if passing means *audited and clean* — so the hook treated two claims as one and
  said the opposite in the same breath. A filename cannot carry a verdict; that was the flaw.
- **Options** — (a) keep the name check and fix the prompt to say only *"a record exists"*;
  (b) require two lines of the record template — `- HEAD: <sha>` and `- findings: 0 blocker`;
  (c) parse the record fully against a schema.
- **Decision** — (b).
- **Why** — (a) is honest but useless: a guard that reports the existence of a file is a guard
  nobody consults. (c) buys accuracy the hook cannot use and makes every record a compatibility
  surface; the moment a schema exists, a hand-written record is a syntax error rather than a
  weaker claim. (b) is two `grep`s, keeps the record human-first, and picks exactly the two facts
  that decide the question. `[^0-9]*` before `0 blocker` is what keeps `1 blocker` and
  `10 blocker` out; anchoring on `^- ` keeps prose that merely mentions the words out.
- **Consequences** — those two lines became a **machine interface** and are now specified
  verbatim in `/audit-history`'s record section and in GUIDE 2.2; everything around them stays
  prose. A record that predates the format no longer clears the guard — correctly, since it
  cannot be read — and the ask says so in its own words rather than claiming no record exists.
  All seven of attest's own shipped records already satisfy the parser, and `smoke.sh` asserts
  that they continue to — by **shape**, not by verdict, so the day one of them honestly records
  a blocker the suite does not fail on something that is not a defect.

  Two corrections the kit's own gate made to this before it landed, both part of the decision
  rather than of its implementation. **Every record for the sha must be clean, not one of them:**
  the glob expands lexicographically, so "the first clean one wins" meant the *oldest* won, and
  the workflow this hook's own prompt recommends produces the bad case — a quick scan comes back
  clean, a later `full` scan finds a blocker, and the push goes through on the earlier file. A
  verdict about a given tree state does not expire. **And the two lines are read as the header,
  not as anything matching:** the prose around them is the author's, may quote either form at
  column 0, and two independent greps over the whole file were satisfied by a sentence. The
  parser takes the *first* line of each kind. This narrows ADR-0028: the guard's question is no longer *"was this
  state audited"* but *"was this state audited **and** did it come back clean"*.

## ADR-0038 — every branch of the guard leaves a line, including the ones that let something through · 2026-09-04 · Accepted

- **Context** — ADR-0034 added the trace because a silent decision cannot be told apart from an
  unregistered hook. The `--dry-run` exemption was then written **above** `trace()`, so the one
  class of command that the guard deliberately waves through wrote nothing at all — and because
  the exemption matched `--dry-run` as a substring anywhere in the command, so did
  `git push origin main # --dry-run` and `git push --dry-run & git push origin main`. The kit
  violated its own entry in precisely the case that entry existed to cover.
- **Options** — (a) log only refusals, treating a pass as uninteresting; (b) move `trace()` above
  every exit and give each outcome its own word; (c) drop the dry-run exemption entirely so there
  is nothing to miss.
- **Decision** — (b), with four words: `pass`, `ask`, `blocked`, `dryrun`.
- **Why** — (a) is what created the ambiguity. (c) trades a real convenience for a problem better
  solved by logging: a dry run genuinely publishes nothing, and asking about it would train the
  habit of approving without reading. (b) costs one line and makes the log answer the question it
  was introduced for — *did the hook run, and what did it decide* — for every command it matched.
  `blocked` is separate from `ask` on purpose: *"a record exists and does not clear this"* is a
  different event from *"there is no record"*, and afterwards only the log can tell them apart.
- **Consequences** — one decision writes exactly **one** line (the first draft of ADR-0037's
  branch wrote both `blocked` and `ask`; `smoke.sh` now pins the count). **Widening what is
  traced widens what the trace holds**, and ADR-0034's *"a trace can hold nothing the prompt
  could not already show"* is true of content and false of durability: the prompt is session UI,
  the log is a persistent, deliberately unbounded file. The `tr` keeps `@ . - _ : =`, which is
  what an address and a credentialed URL are made of, so `git send-email --to alice@example.com`
  or a push URL with a token in it lands there verbatim. It is gitignored and never shipped, so
  nothing leaves the machine — but GUIDE 2.2 now says this outright, and the shipped
  `COMPLIANCE.md` names the file in §7 so an adopter in regulated scope declares it rather than
  discovering it. Deleting the file is the retention control. The dry-run exemption
  still leaks by substring — `# --dry-run` is not a dry run — and that is knowingly left to the
  matching work this entry does not cover; the difference is that it is now **visible in the
  log**, which was the precondition for fixing it in any measurable way.

## ADR-0039 — shell reaches the working tree as LF, guaranteed twice · 2026-09-04 · Accepted

- **Context** — the repo shipped no `.gitattributes`. Git for Windows sets `core.autocrlf=true`
  in its system config, so a Windows checkout holds CRLF hooks. Under Git Bash they run; opened
  from WSL or a Linux container the same checkout gives `dash` a trailing CR on the last token —
  `set: Illegal option -`, exit 2. A `PreToolUse` hook that exits 2 does not merely fail, it
  **blocks the tool call**, so every Bash command in the session dies with an error that points
  at the shell rather than at line endings. Neither the LF CI runners nor the smoke suite (MSYS
  `sh` tolerates the CR) can see it.
- **Options** — (a) `.gitattributes` only; (b) strip CR in `install.sh` only; (c) both.
- **Decision** — (c).
- **Why** — they cover different populations. `.gitattributes` fixes everyone who clones the kit
  *after* it lands, and fixes nothing for a zip download, a copy made earlier, or a vendored
  tree. Stripping on copy fixes every install regardless of how the kit got onto the disk, and
  cannot fix a repo generated from the template button, which never runs the installer. Two
  cheap mechanisms with disjoint blind spots beat one with a gap.
- **Consequences** — there are in fact **three** mechanisms, not two: `.gitattributes` in the
  kit's own repo, the strip on copy, and `ensure_attribute()` writing the attribute into the
  adopter's repo so their *next* checkout does not undo the strip. That third one is scoped to
  **`.claude/hooks/*` and nothing else**. A blanket `*.sh` was written first and withdrawn: it
  reaches scripts the kit never installed, and `text` normalises on `git add`, so it would
  rewrite the adopter's own CRLF blobs at their next commit under a rule this installer put
  there — for a kit whose declaration is *"nothing here edits your code"*, that is the wrong
  side of the line. The hooks pattern already covers 100% of what the kit puts in the repo.
  `ensure_attribute` is quieter than its twin `ensure_ignore`: it matches on the **pattern
  token** (`awk '$1 == p'`, never a regex — globs are not regexes, and treating `*.sh` as one
  duplicated the line on every re-run) and returns silently when the adopter has already ruled
  on that pattern. `install.sh` rewrites the copied file through `tr -d '\r'`, using
  `cat >` rather than `mv` so the mode `cp` just set survives, and **restores from the kit if
  that rewrite fails** — swallowing the failure left a truncated hook reported as installed and
  skipped by every later re-run: a hook that parses and does nothing. `smoke.sh` builds a CRLF kit and
  asserts the installed hook is both CR-free and valid shell. The kit still cannot protect a
  template-generated repo on Windows; `.gitattributes` ships with it, which is the best available
  answer there.

## ADR-0040 — a record may be redacted once, visibly, when it carries personal data · 2026-09-04 · Accepted

  Narrows: ADR-0016 (`.attest/` is append-only, "one file per run, never edited").

- **Context** — `.attest/ship-…-9621526.md` spelled the maintainer's address out in full, inside
  the very finding that argued the address should not become permanently harvestable — while
  `docs/attest-progress.md` claimed it had deliberately not been written into file content. The
  other half of that finding, attest's records travelling into every generated repo, is ADR-0041:
  the two were one entry until the kit's own gate pointed out that `Supersedes:` and the
  sanctioned `Status` flip both operate on a **whole** entry, so a later reversal of one half
  would nominally reverse the other, and half an entry has nowhere to carry a status.
- **Options** — (a) leave it, `.attest/` is append-only; (b) delete the record; (c) redact the
  data, leave a visible mark, and sanction the exception.
- **Decision** — (c).
- **Why** — (a) makes append-only protect the wrong thing: the rule exists so a verdict cannot be
  rewritten to look better, not so leaked personal data must stay leaked. (b) destroys the finding
  along with the data. (c) is the same shape as ADR-0003's sanctioned `Status` flip — one named,
  marked, narrow mutation, with the finding, its counts and its verdict untouched.
- **Consequences** — the permitted mutation is narrow and must be stated in the record itself:
  what was removed, when, and under which entry. Nothing else may be edited. **It reaches the
  working tree, not the history:** the pre-redaction line is still the blob at the preceding
  commit, so this restores the record's truthfulness and does not reduce reachability. That is an
  accepted risk of the same class already recorded for the 45 commit authorships — the address is
  the maintainer's own, in a repo he owns, no third party and no special category — and it is
  written down here rather than left to be discovered after a visibility flip. The record's own
  `Remediation: none required` is deliberately **not** re-edited: the permitted mutation is spent,
  and a stale line inside an append-only record is evidence of its own moment.
  `docs/attest-progress.md` no longer claims the address was never written — it says it was, and
  was redacted. This entry sanctions **one** mutation of **one** record; it is not a licence to
  tidy `.attest/`. The only other thing permitted to remove a record is ADR-0041's sweep, and
  that runs in someone else's repository, never here. `smoke.sh` asserts the **shape** of an
  address anywhere in a generated tree rather than a domain allowlist — a hard-coded list passes
  every other domain, and writing one would have put the maintainer's own domain into a shipped
  file to do it.

## ADR-0041 — attest's own audit records do not travel into a repo generated from the template · 2026-09-04 · Accepted

  Narrows: ADR-0016 (`.attest/` is append-only, "one file per run, never edited").

- **Context** — `template-cleanup.sh` left all twelve of attest's records in every generated repo.
  An adopter therefore starts with a dozen scans of somebody else's commits and a full-history
  record describing 51 commits that do not exist in their repository. Those records are not inert:
  `/gate` and `/business audit` both scope themselves to *"since the last audit"* by reading
  `.attest/`, so they are handed to an adopter's auditors as that adopter's own history.
- **Options** — (a) leave them; (b) delete `.attest/` wholesale; (c) delete by name,
  discriminating on the sha in the filename.
- **Decision** — (c).
- **Why** — (b) would take a record the adopter had already written, which is plausible: auditing
  before the first push is the workflow this kit teaches. (c) keys on the only thing that really
  distinguishes them — attest's records name attest's commits, which do not resolve in a repo with
  its own history.
- **Consequences** — **two failure modes had to be closed before this was safe, and the kit's own
  gate found both.** First, `git cat-file -e` fails for *any* reason — 128 outside a repository,
  127 with no git — so deleting on a non-zero exit removed every record wherever git could not
  answer, the exact inversion of the property this entry rests on. Git must first prove it can
  answer (`git rev-parse --git-dir`); only then may a specific negative remove anything. Second,
  the trailing segment of a filename is a sha **only if it looks like one**: `gate-notes.md`,
  `ship-…-<sha>-rerun.md` and `gate-2026-09-05-pre-release.md` are names the kit never writes, so
  they are the adopter's — and feeding `notes` or `rerun` to `git cat-file` merely fails, which
  under the delete-on-failure rule took them as well. Anything that is not a bare hex abbreviation
  of at least four characters is kept, unexamined. Both belong to the decision rather than to its
  implementation: a sweep that runs unattended in someone else's repository, from a workflow
  holding a write token, is defined by what it refuses to touch. `smoke.sh` runs it in a fixture
  that is a **real repository with its own commit** — the first version of that test ran outside
  one, so it asserted the right outcome through the very bug it was meant to catch, and the suite
  was green over it. The directory itself stays (it is where the adopter's records go) and is
  `rmdir`'d only if it ends up empty.
- **Note on numbering** — the run record `.attest/gate-20260904-110554-93fc862.md` calls this
  decision ADR-0040, which is what it was called when that gate ran. Records are not edited to
  follow a later renumbering (ADR-0032).

## ADR-0042 — a git that can answer about one commit is not a git that can answer · 2026-09-07 · Accepted

  Narrows: ADR-0041 (`template-cleanup.sh` discriminates records by whether their sha resolves).

- **Context** — ADR-0041 rests on an invariant it states plainly: *a git that cannot answer keeps
  everything*. It establishes that git can answer at all (`git rev-parse --git-dir`) and only
  then lets a specific negative answer from `git cat-file -e` delete a record. A **shallow**
  clone breaks the middle of that reasoning: `rev-parse` succeeds, so the guard passes, while
  every commit but `HEAD` is simply absent — and a record names the commit it *gated*, which by
  ADR-0033 is an **ancestor**, never `HEAD` itself. So every one of the adopter's own records
  fails to resolve and is deleted. `actions/checkout` defaults to `fetch-depth: 1`, which is
  precisely how `template-cleanup.yml` runs it: unattended, with a write token, in someone
  else's repository. attest's own `/gate` found this; the smoke suite could not, because its
  fixture had a single commit, so its record named `HEAD` and resolved by accident.
- **Options** — (a) set `fetch-depth: 0` in the workflow and call it fixed; (b) drop the sha
  discriminator for something a shallow clone can evaluate; (c) refuse to delete anything unless
  git states plainly that the history is complete, **and** deepen the workflow's checkout.
- **Decision** — (c), both layers.
- **Why** — (a) alone leaves the script destructive for every other caller: the README tells
  adopters they may run it by hand, and ADR-0022 keeps it runnable late, so the workflow is not
  the only path. A script that is safe only because of a setting in a file it does not own is
  not safe. (b) throws away the one discriminator that actually distinguishes attest's records
  from the adopter's — shape cannot, because a record written before the first push carries the
  same `- kit:` line. (c) restores the invariant as stated: `--is-shallow-repository` prints
  `false` on a complete history, `true` on a truncated one, and **nothing** on a git too old to
  know the option — so the test keeps everything unless git says `false`, which is the same
  fail-open posture the rest of the block already takes.
- **Consequences** — in a shallow checkout the sweep prints that it is leaving `.attest/`
  untouched and removes nothing, including attest's own records; the generated repo then carries
  a few of attest's records until someone runs the script again with a full history. That is the
  correct trade: an inherited record is noise, a deleted one is the adopter's evidence. Name the
cost though: one of the records that then stays is `ship-…-9621526.md`, which carries the
maintainer's identity into that copy — the same class of exposure ADR-0040 redacted for, accepted
here because the alternative is deleting somebody else's evidence, and because it is the
maintainer's own already-public data, no third party and no Art 9 category. Smoke
  gains a fixture whose record names an **ancestor** — the case the old single-commit fixture
  structurally could not express — and asserts both directions: a shallow clone keeps every
  record, a full clone still sweeps the kit's and keeps the adopter's.

## ADR-0043 — what the kit pins for its own shell stops at the template boundary · 2026-09-07 · Accepted

  Narrows: ADR-0039 (shell reaches the working tree as LF, guaranteed twice).

- **Context** — ADR-0039 needs a blanket `*.sh text eol=lf` in attest's own `.gitattributes`:
  its installer, its smoke suite and its hooks are all shell, and a CRLF hook exits 2 under
  dash, which for a `PreToolUse` hook blocks every Bash call. The same ADR already saw the
  danger for the **installer** and narrowed what it writes to `.claude/hooks/*`. It missed that
  `.gitattributes` is a **tracked file**, so the template button copies it whole — and in the
  adopter's repo that blanket line normalises every `.sh` they will ever write, under a rule the
  kit put there. `README.md` and `GUIDE.md` both promise the opposite in as many words: nothing
  the kit installs edits your code. `/gate`'s `/business` pass called it what it is — a violated
  non-goal, which the ladder makes a blocker unconditionally.
- **Options** — (a) narrow attest's own file to `.claude/hooks/*` and accept CRLF risk on the
  kit's own installer and suite; (b) keep the blanket line and narrow the **declaration**
  instead, to the installer path; (c) keep it for attest and have `template-cleanup.sh` narrow
  it in the generated repo, the way it already handles README, LICENSE and the record sweep.
- **Decision** — (c).
- **Why** — (a) removes a protection attest genuinely needs to keep its own suite honest on
  Windows. (b) is the option that costs nothing today and everything later: the non-goal is the
  most load-bearing sentence in the README, and narrowing a promise to fit an oversight is how a
  kit that audits declarations stops deserving to. (c) is the shape every other attest-vs-adopter
  difference already takes — the cleanup is the boundary, and this belongs on it.
- **How, and why not the obvious way** — the first draft emitted a fresh two-line file. Its own
  gate run killed that in two ways: it discarded `.attest/*.md text eol=lf`, the other kit-scoped
  pin ADR-0044 had just added, handing the template path back the CRLF misdiagnosis the installer
  path had just closed; and on a **late** run — which ADR-0022 keeps supported and the README
  promises is safe — it silently dropped any line the adopter had added under attest's header,
  since the guard is only that header's presence. So the removal is **surgical**: the blanket
  `*.sh` line goes, every other line stays byte for byte. A symlinked or unwritable
  `.gitattributes` is reported, never written through — `install.sh` refuses those outright and
  the two paths should not disagree.
- **Consequences** — the generated repo keeps `.claude/hooks/*` and `.attest/*.md` and loses the
  blanket rule; once the file no longer carries attest's header it is never touched again. The
  **cleanup is not the only path**, and the README says so: a user may delete `scripts/` by hand,
  or have Actions disabled, or simply never run it. For them the manual list gains a step C, and
  it is marked *do this even if you skip A and B* — deleting `scripts/` is what deletes the fix.
  Smoke's generated-repo fixture now copies `.gitattributes` — `cp "$KIT"/*.md` never globbed
  dotfiles, which is the gap that let this ship unseen; other dotfiles remain uncopied, so that
  class is narrowed, not closed — and it asserts the blanket rule is gone, both kit pins remain,
  and a line of the adopter's own survives.

## ADR-0044 — a difference of line endings is named, not called drift · 2026-09-07 · Accepted

  Narrows: ADR-0018 (a kit-owned file that differs from the kit's is reported as drift).

- **Context** — ADR-0039 strips CR when `install.sh` copies a file in, but only in
  `copy_if_absent`'s fresh-copy branch. An adopter who already has the kit — precisely the
  Windows population ADR-0039 exists for — takes the other branch on upgrade: the CRLF hook is
  reported as ordinary `drift`, *"yours kept, but it DIFFERS from the kit's — diff against …"*.
  Every word of that is technically true and all of it misleads: the difference is whitespace
  most diff tools hide, and the file it calls merely stale is one that exits 2 under dash and
  blocks every Bash call in the session.
- **Options** — (a) leave it — the drift message is not false; (b) strip CR on the upgrade path
  too, repairing the file in place; (c) detect the line-ending-only case and report it by name,
  with the one-line repair, writing nothing.
- **Decision** — (c).
- **Why** — (a) fails the one user it was written for. (b) is tempting and provably
  content-preserving — if the two files are identical once CR is removed, the copy *is* the
  kit's — but it makes `install.sh` write into a file the user already has, and **copy-if-absent
  is the kit's load-bearing promise**. A promise that holds except for whitespace is a promise
  with a precedent attached, and the next exception argues from this one. (c) closes the actual
  complaint, which was never that the file went unrepaired but that the diagnosis was
  unreadable.
- **Consequences** — the `version` branch now compares both sides with CR removed before
  deciding what to say. Smoke asserts three things about it, added after the gate caught this
  entry claiming coverage that did not yet exist: an upgrade over a CRLF copy is named by its
  line endings, that same copy is *not* reported as ordinary drift, and a real content edit
  still is. The file stays as the adopter left it, and the message carries the exact
  command. `.gitattributes` additionally gains `.attest/*.md text eol=lf`, and `install.sh`
  lands the same pin: the guard parses two lines out of a record byte-exactly (ADR-0037), so on
  a CRLF checkout it fails closed with a reason that blames the record's age rather than its
  line endings — fail-closed, but a false diagnosis is still a defect.

## ADR-0045 — the log's third relation is a decision, and ships with the kit · 2026-09-07 · Accepted

- **Context** — this log grew a third relation, `Narrows: ADR-N`, and started using it (ADR-0040,
  and every entry above). It was added straight to the header rules with no entry of its own: no
  alternatives weighed, no record of why. Worse, it never left attest — the shipped `DECISIONS.md`
  template and `.claude/skills/decision/SKILL.md` still describe two moves, `Supersedes` and the
  `Status` flip. The same series propagated its other invariants into the kit faithfully, so what
  diverged here is exactly what the kit sells: attest's practice ran ahead of attest's rules, and
  `/gate`'s `/decision` pass is what noticed.
- **Options** — (a) drop `Narrows` and use `Supersedes in part`; (b) keep it in attest only, as
  a house style; (c) record the choice and ship the relation in the kit.
- **Decision** — (c).
- **Why** — (a) is wrong on the merits: `Supersedes in part` says half the decision is
  **reversed**, and that is not what happens here. In every case this log reached for `Narrows`,
  the old decision still stands entirely — its *scope* turned out smaller than its text claimed.
  Calling that a partial reversal would misdescribe five entries and flip a `Status` that should
  not move. (b) is the divergence itself, made permanent: a kit whose own log uses a grammar the
  kit does not teach is a kit that has stopped dogfooding one of its documents.
- **Consequences** — `DECISIONS.md` and `decision/SKILL.md` now name all three relations, say
  that only `Supersedes` earns the `Status` flip, and say plainly what `Narrows` is *for*: the
  entry whose reasoning was right and whose wording was too broad — the case where people reach
  for editing the old text, which is the one thing the log cannot allow. Known and accepted: the
  relation is a field on the **new** entry only, so a reader landing on the old one still gets no
  forward pointer. Adding one would mean writing into a landed entry, which costs an exception to
  append-only that a navigation convenience does not justify.

## ADR-0046 — what the guard's trace can hold, stated as the code has it · 2026-09-07 · Accepted

  Narrows: ADR-0038 (every branch of the guard leaves a line).

- **Context** — ADR-0038 records the sanitiser's keep-set as `@ . - _ : =`. The code keeps more:
  `tr -c 'A-Za-z0-9 ._/:=@-'` also keeps the **space** and the **slash**, which together mean a
  trace line can carry whole paths and filenames. The series corrected this in `GUIDE.md` and
  `COMPLIANCE.md` but not in the entry, and the entry is append-only, so the correction cannot
  be made where the error is.
- **Options** — (a) leave it: the shipped documents are right and they are what people read;
  (b) edit ADR-0038; (c) append an entry that narrows it.
- **Decision** — (c).
- **Why** — (a) leaves the decision log — the one artefact whose whole value is being a truthful
  record — carrying a claim about the code that is smaller than the code. (b) is the mutation
  append-only exists to forbid, and this is not one of the two sanctioned ones. (c) is what
  ADR-0045 just made the grammar for.
- **Consequences** — the keep-set is `A-Za-z0-9`, **space**, `.` `_` `/` `:` `=` `@` `-`. A trace
  line can therefore hold a path a matched command mentioned; it cannot hold quotes, backticks,
  `$`, or anything else that could break the JSON or smuggle a substitution. That is the same
  bound the prompt reason carries, since both come from the one `tr` — which was the property
  ADR-0038 was really asserting, stated correctly here.

---

## ADR-0047 — a heading the hook cannot read is a hook that is not there · 2026-09-07 · Accepted

  Extends: ADR-0028 (the declaration hook), ADR-0034 (a silent decision is unreadable).

- **Context** — `session_declaration.sh` takes its document *paths* from `ATTEST_BUSINESS` and
  `ATTEST_THREAD_CARRIER` but matches the section *headings* against three hardcoded English
  patterns. A project that writes `## Stav k 7. 9.` instead of `## Current state` gets nothing
  from the hook. The hook is fail-open, so it says nothing about it either — and from inside a
  session, "the hook ran and matched nothing" and "the hook was never registered" produce the
  identical observation. That is precisely the ambiguity ADR-0034 introduced the ship guard's
  trace log to remove, reappearing in the other hook.
- **Options** — (a) leave it and tell adopters to keep English headings; (b) print a diagnostic
  line when a document is read but no section matches; (c) three heading overrides, matching
  the treatment the paths already get.
- **Decision** — (c), with the defaults byte-identical to today's patterns.
- **Why** — (a) makes the kit's reach stop at the language of its own documents, and the
  boundary is invisible: the adopter's evidence that the hook works is that it printed
  something, which is the one thing it will not do. (b) spends context on *every* session to
  report a condition that is normal in a fresh install, where the templates are unfilled and
  silence is correct — the hook's own budget rule (~52 lines, prepended always) is the reason
  it stays quiet. (c) costs nothing at runtime, and a heading is the same class of assumption
  as a path: the kit already conceded that its document *names* are not universal, and its
  *section names* are the same concession one level down.
- **Consequences** — `ATTEST_NONGOALS_HEADING`, `ATTEST_STATE_HEADING`, `ATTEST_NEXT_HEADING`,
  set beside the two path variables in the `env` block of `.claude/settings.json`. Each is a
  POSIX ERE matched against the whole `## …` heading line, which two details had to be got
  right and were not, first time round:

  - An **empty** value is not an override: `${VAR:-default}`, not `${VAR-default}`. The reason
    is the opposite of the obvious one — an empty awk pattern matches *every* string
    (`"## Anything" ~ ""` is 1), so the wrong operator would not blank the declaration, it
    would pour **every section of both documents** into the context of every session. Measured,
    not reasoned: the first draft of this entry claimed "silently blank" and was wrong.
  - The pattern reaches awk through **`ENVIRON[]`, not `awk -v`**. `-v` runs its value through
    escape processing, so the obvious escape of a metacharacter — `Stav \(WIP\)` for a heading
    that really contains brackets — arrives as `Stav (WIP)`, a grouping that matches something
    else; it takes a *doubled* backslash to survive, which nobody guesses. The miss is silent,
    and awk's own warning about it goes to the stderr `section()` discards. `ENVIRON[]` passes
    bytes through untouched, so one backslash means one backslash.

  What is deliberately **not** fixed: the section must still be at level 2. The body runs to the
  next `## `, so admitting `###` as a section start would end every section at its own first
  subheading; `### Ďalší krok` has to be promoted, and `GUIDE.md` says so. Ten cases in
  `scripts/smoke.sh` pin this — including the silence without an override, which is the
  behaviour being replaced and the only one that could regress unnoticed, and including
  fail-open on a regex awk refuses to compile, since user input reaches a regex engine here for
  the first time. The two subtleties above are pinned by assertions that were checked against a
  deliberately broken build: reverting either one turns exactly one case red.

## ADR-0048 — the method is stated tool-neutrally; no adapter is shipped for it · 2026-09-09 · Accepted

  Relates to: ADR-0008 (one root commit), ADR-0031 (nothing of attest's identity is installed).

- **Context** — the recurring outside suggestion, in its strongest form from a review of the
  repo this month: split the kit into a vendor-neutral core plus adapters for Codex, Copilot and
  Cursor, add a YAML manifest as an open standard, and run the audits in CI as a required
  status check. The premise is right — the value is the spine, not the Claude wiring — and the
  conclusion does not follow from it. What makes the kit *enforce* rather than *suggest* is four
  primitives the host has to provide: context injected at session start, an action interceptable
  before it runs, a reviewer that is read-only by capability, and documents read on demand. The
  other hosts named give an instructions file. An adapter would keep the name and drop the
  guarantee.
- **Options** — (a) ship adapters for the other agents; (b) ship nothing and stay silent, the
  method readable only by reading the implementation; (c) state the method in one tool-neutral
  document, ship no adapter, and require any implementation to say which of the four primitives
  its host actually has.
- **Decision** — (c). `METHOD.md` at the root: the spine, ten properties, the four primitives,
  the costs. No code, no per-agent claim, MIT.
- **Why** — (a) sells *encouraged* as *enforced*, which for a kit whose product is a guarantee
  is not a smaller version of the thing but a different thing wearing its name; the moment a
  README carries a "Codex ✓" row, the distinction an auditor asks about is gone. (b) leaves the
  transferable part — the ten properties, which are host-independent and were expensive to
  learn — legible only to someone willing to read a kit for a tool they do not use. (c) costs
  one document and nothing at runtime, and it is the honest split: the method is portable, the
  enforcement is not, and the document says so in those words.
- **Consequences** — `METHOD.md` is attest's identity, so it follows README and LICENSE:
  `install.sh` never copies it, and `scripts/template-cleanup.sh` removes it in a generated repo
  **by content guard**, not by name — `METHOD.md` is a generic enough name that an adopter may
  write their own, and the guard matches the file's own first line the way the `smoke.sh` and
  `ci.yml` arms do. One case in `scripts/smoke.sh` pins the removal.

  Two claims in the document are load-bearing and both are stated with their limits, because
  this is the file most likely to be read by someone who has never seen the repo. The dogfood
  result is quoted **with its sample size attached** — six faults, two sandboxes — the way
  `README.md` already quotes it. And property 10 (only reproducible checks may block a merge;
  a model's judgment advises) is written as a property of the method rather than a limitation of
  this kit, which is what it is: it is also the reason no CI gate over the judgment passes is
  planned, and the reason the one deterministic thing the gate does produce — a run record tied
  to a commit — is the part that could become a required check.

## ADR-0049 — a run record is an attestation, not a report · 2026-09-09 · Accepted

  Extends: ADR-0016 (the gate appends a record), ADR-0026 (`.attest/` is append-only plus one
  ignored scratch), ADR-0040 (a record may be redacted once, visibly, for personal data).

- **Context** — the records are committed, which is the whole point of ADR-0016: *"the gate ran"*
  has to be a fact in the repository rather than a memory. Committed means published the moment
  the repository is — and this repository went public on 2026-09-09, which is what surfaced the
  question. A `/gate` record as the kit has been writing them is a continuous narrative of every
  finding: what was wrong, in which file, how it was repaired. A `/audit-history` record is worse
  in kind — it is the one artefact in the kit that can state in public, with a date, exactly
  where a secret used to live. For attest that is harmless and even useful: its findings are its
  documentation, and every one of them is already in an ADR. For an adopter it is a dated,
  pre-indexed inventory of every weakness their codebase has had, published by a kit they
  installed to make them safer. Nothing in ADR-0016, ADR-0026 or ADR-0040 says a word about it:
  ADR-0040 governs personal data in a record, not the record's altitude.
- **Options** — (a) leave it and warn in `GUIDE.md`, telling adopters to `.gitignore` the records
  if they mind (the guard reads them from disk, so an untracked record still works); (b) make the
  detail conditional on whether the repository has a public remote, degrading to a summary when
  it does; (c) narrow what every record carries: an attestation — HEAD, kit version, which passes
  ran, the verdict, the counts, and **one line per blocker and major** giving severity, owning
  pass, class and path — with the narrative going to the session and, if wanted durably, to the
  ignored `.attest/tmp/`.
- **Decision** — (c), universally, no configuration. A project whose findings are its own
  documentation may widen it in its `CLAUDE.md`; attest's own widening is the standing note in
  `docs/attest-progress.md`, since attest has no filled `CLAUDE.md` of its own (ADR-0006).
- **Why** — (a) moves the consequence onto the adopter at exactly the moment they have least
  context, and the kit's own non-goal is that nothing it installs should surprise you later; it
  also answers a data question with documentation, which is the shape of fix this log keeps
  rejecting. (b) is the most correct rule on paper and the wrong one here: the check would be
  performed by a model following prose, so it fails silently and in the exposing direction — the
  failure mode ADR-0038 and ADR-0042 were both written about, and a privacy rule that fails open
  is not a privacy rule. (c) needs no detection, no configuration and no per-repo judgment, and
  it costs almost nothing that matters: the evidence value of a record is *that the gate ran over
  this sha and what it concluded*, which survives intact — what the fix was is already in the
  commit that made it, and who needed the detail was in the session when it was produced.
- **Consequences** — the record shape in `gate/SKILL.md` and `audit-history/SKILL.md`, and both
  descriptions in `GUIDE.md`. **The two machine-parsed lines are untouched** (`- HEAD:`,
  `- findings: <n> blocker …`), so `ship_guard.sh` needs no change and every existing record
  still clears it — this narrows what goes *around* the interface, not the interface (ADR-0037).
  `.attest/` is append-only, so the records already written keep their narrative; the rule binds
  what is written from here on, which is what append-only means. Kit **0.7.0**: it changes what
  the kit writes into an adopter's repository, which is adopter-visible even though nothing
  breaks.

  What this deliberately does **not** do is give the adopter a knob. A switch would have to
  default one way, and whichever way it defaulted would be the setting most repositories ran
  under — so the choice is between a narrow default with a documented widening, and a wide
  default nobody revisits. The kit's own rule about guards applies to records too: the safe
  behaviour has to be the one that survives being forgotten.

## ADR-0050 — a record is matched by what it says, at any abbreviation · 2026-09-10 · Accepted

  Narrows: ADR-0037 (the guard reads the record's content), ADR-0034 (the guard leaves a trace).
  Supersedes the CRLF reasoning in ADR-0039, not its pin.

- **Context** — an external review of `v0.7.0` reproduced a defect the smoke suite could not see,
  and it was reproduced again here before anything was touched. The guard globbed
  `.attest/ship-*"$SHA"*.md` and compared `- HEAD: $SHA` byte for byte, with `$SHA` from
  `git rev-parse --short HEAD`. **`--short` has no stable length**: `core.abbrev` is a config
  value a colleague's global gitconfig may set, and git widens the default as a repository
  grows. When the two sides disagree the guard fails **closed** — but with a false reason, in
  both directions: a record written at 7 read by a guard at 10 produces *"no /audit-history run
  record for HEAD"* while the record sits right there; a record written at 8 read by a guard at 7
  is found by the glob and rejected by the arm, producing *"one of them reports a blocker, or
  predates the record format"* when it reports neither and predates nothing. ADR-0037 exists
  precisely so this hook stops giving false diagnoses. Every fixture in `smoke.sh` used one
  `--short` on both sides, so the suite could not see it. The same review found the CRLF claim in
  `.gitattributes` and `install.sh` — that on a CRLF checkout *"the `- HEAD:` arm never
  matches"* — and measurement here confirmed it false for the shape `/audit-history` actually
  writes: the CR lands after `(branch)`, where the arm's own `*` swallows it. Only a bare
  `- HEAD: <sha>` failed.
- **Options** — (a) pin the abbreviation, writing `--short=12` into the skill and the guard;
  (b) keep the filename match and widen the glob; (c) stop matching bytes and match meaning —
  read the sha out of the record's `- HEAD:` line and accept it when it is a prefix, seven hex or
  longer, of the full `git rev-parse HEAD`.
- **Decision** — (c), with `tr -d '\r'` on both parsed lines, and the trace gaining the payload's
  `permission_mode` as a fifth column.
- **Why** — (a) is a rule two tools have to keep agreeing on forever, and it is unenforceable
  where it matters: the record may have been written by an older kit, on another machine, by
  someone whose git decided differently. (b) treats the filename as the interface, which is what
  ADR-0037 already rejected once for the verdict — a name cannot carry a fact the machine
  depends on. (c) needs no agreement at all: an abbreviated sha *means* "a prefix of this
  commit", so the guard now asks the question the data already answers. The CR strip removes the
  last byte-exactness from the parse, which is why the CRLF claim can simply be deleted rather
  than restated: line endings are a property of a checkout, never of a verdict. The trace column
  closes the other half of the ambiguity ADR-0034 was written for — *"the hook did not fire"* and
  *"the hook fired and the mode auto-approved it"* were still indistinguishable afterwards, and
  the mode costs one `sed`.
- **Consequences** — `ship_guard.sh` reads every `.attest/ship-*.md`, not a sha-shaped glob, and
  decides membership per record; the filename keeps its sha **for people** and is no longer
  load-bearing. Seven hex is the floor: shorter is a coincidence waiting to happen. Uppercase is
  folded — **after** the match, not before, which is the bug the first draft shipped: folding the
  line turns `- HEAD:` into `- Head:` (H is not in `A-F`; E, A and D are), so the anchor stops
  matching and every record goes invisible. The fixture that caught it was the control case, the
  one combination that had worked for months. Eleven new `smoke.sh` cases fail against the
  pre-series hooks; the CRLF template case deliberately **passes** there, because it always did
  and the claim was the thing that was wrong. The header's *"fail-open everywhere"* now says what
  the code does: outside a git checkout the guard **asks**, because with no HEAD "audited" and
  "unaudited" are the same observation. `.gitattributes` keeps the `.attest/*.md` pin as belt and
  braces, with its reasoning rewritten.

## ADR-0051 — writing the evidence is itself a decision · 2026-09-10 · Accepted

  Extends: ADR-0016 (the record is the evidence), ADR-0033 (it is written before the push),
  ADR-0049 (it is an attestation).

- **Context** — the same review named the kit's most uncomfortable gap, and it holds. The ship
  guard's decision is read out of a record that is an ordinary untracked markdown file. Nothing
  signs it. `disable-model-invocation: true` stops the model *invoking* `/audit-history`; it says
  nothing about writing a file, and the guard's `PreToolUse` matcher is `Bash`, so the `Write`
  tool never met it. In a permission mode where file edits inside the working directory are
  auto-approved — the common case — an agent could write `.attest/ship-<sha>.md` saying
  `0 blocker`, push, and the guard would pass it silently. Nobody has to be malicious for this to
  matter: the same path is open to a prompt injection carried in the repository's own content.
  The kit sells *"read-only by capability, not promise"* and had, at its single most load-bearing
  artefact, a promise.
- **Options** — (a) document it and leave it; (b) sign or otherwise bind records to the run that
  produced them; (c) a second `PreToolUse` hook on `Write|Edit` that asks when the path is a ship
  record, plus an arm in the existing guard for the shell shapes that write one, plus a written
  threat model.
- **Decision** — (c). `record_guard.sh`, matcher `Write|Edit`; `ship_guard.sh` gains an arm for
  `>`, `tee`, `cp` and `mv` into `.attest/ship-*`; `README.md` gains *"What it does not defend
  against"* and `METHOD.md` says the same in its own terms.
- **Why** — (b) is the honest fix and the kit cannot have it: any secret the signer holds is
  reachable by whatever runs in the session, so it would sign forgeries with the same key, and a
  signature nobody verifies is decoration. (a) leaves the strongest claim in the README standing
  on the weakest mechanism. (c) is worth stating precisely, because it is easy to oversell:
  **it does not make forgery impossible.** It converts writing the evidence into a prompt at the
  moment the human still knows whether an audit ran — which is strictly earlier and better
  informed than the same click at push time, when the context is gone. That is a real
  improvement and a small one, and the README now says which it is.
- **Consequences** — one extra prompt per `/audit-history` run, which is the price of the record
  meaning anything; that cost is documented in GUIDE 2.3 rather than hidden. **Gate records are
  not hooked**: a `gate-*.md` attests a commit-time run no machine reads, so a prompt there would
  be friction without a decision behind it — the line this hook defends is where a file becomes a
  machine's answer. Coverage is deliberately partial: an editor, a `python -c`, any writer that
  is neither the `Write` tool nor a plain shell redirect goes through untouched, and pretending
  otherwise would be the same overclaim this entry exists to remove. The new hook is POSIX `sh`,
  fails open on a missing payload or path, and traces to the same log in the same shape, so one
  file still answers *"what did the guards decide, and under which mode"*.
