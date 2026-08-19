# attest — decision log (ADR-lite, append-only)

> **This is attest's own decision log — not part of the kit.** `install.sh` never copies it.
> If you generated your repo from the **template button**, delete `docs/` and `install.sh`
> (see README "First 5 minutes"). The `DECISIONS.md` at the repo root is an empty template for
> *your* project; this is where the kit's own "why X over Y" lives, so attest never ships its
> author's decisions as yours. Status/history → `docs/attest-devlog.md`.
>
> Append-only — never edit or delete a past entry (except flipping its `Status` line when
> superseded); to reverse one, **append** a new entry that supersedes it.

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

## ADR-0005 — One 3-rung severity ladder with a domain alias, not per-skill vocabularies · 2026-07-15 · Accepted

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

## ADR-0015 — Install Python tooling only into Python projects · 2026-07-22 · Accepted

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

## ADR-0021 — `ci.yml.example` ships to consumers; it is the one file under `.github/` that is theirs · 2026-08-11 · Accepted

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

## ADR-0024 — hooks act only inside the project, and never leave cache behind · 2026-08-11 · Accepted

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
