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
