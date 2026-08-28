---
name: business
description: >-
  Creates, maintains and audits BUSINESS.md — the project's business context (why
  it exists, for whom, its value, scope and non-goals). Works like /init, but for
  BUSINESS.md: it first establishes the project's ARCHETYPE (library / CLI / service
  / data-pipeline / AI-system / local-app), which selects a tailored template and a focused
  question set. Three modes: bootstrap (write the file in a new project),
  update (reconcile it against the project's state), and `audit` (check reality —
  code, commits, diff — against the declared non-goals and scope, read-only; in a project
  that did not install /compliance it also inherits the shared ladder's fallback row for
  regulated ground). Bootstrap and update end by making the compliance call — whether this
  project needs COMPLIANCE.md at all.
  Generic — usable in any project. Do NOT use it for live status (that belongs in
  PROGRESS.md) or for rules/conventions (they belong in CLAUDE.md).
disable-model-invocation: true
argument-hint: "[audit]"
---

# /business — business context + archetype (BUSINESS.md)

This skill maintains **`BUSINESS.md`** — the document about **why the project exists**. It
changes rarely. It works much like `/init` (which creates `CLAUDE.md`), but focuses purely
on business context, and it opens by establishing the project's **archetype** so the
questions it asks and the template it writes fit the *kind* of software in front of it.

The skill is **generic** — work with what you actually find in the repo, and assume nothing
about the specific project.

## The control documents — keep them separate

**Anti-duplication:** status → `PROGRESS.md` · rules → `CLAUDE.md` · why-it-exists →
`BUSINESS.md` · why-we-chose-X-over-Y → `DECISIONS.md` · under-what-rules → `COMPLIANCE.md`.
Write each fact in exactly one place. (full table: GUIDE PART 1)

> This skill only maintains `BUSINESS.md`; treat the others as sources of context if they
> exist. If you catch yourself writing current status ("done", "running", "6 tests green") or
> a technical rule (language version, commit style) into `BUSINESS.md` — it belongs elsewhere,
> leave it out. A specific choice and *why it beat the alternative* is a `DECISIONS.md` entry,
> not a non-goal.

## The archetype

Before writing anything, decide **what kind of software this is**. The archetype is a
lightweight label — not a legal judgement. It does two jobs: it picks the right questions
and template below, and it is recorded as one line in `BUSINESS.md` as a **trigger** for a
later `/compliance` pass — it signals the EU AI-Act / GDPR *may* apply; `/compliance` then
runs the real classification. It does **not** determine the legal tier: a non-`ai-system`
archetype (a service, a data-pipeline, even a library) can still be in scope. Keep the
*legal* classification out of `BUSINESS.md` (that is `COMPLIANCE.md`'s job) — here you
record only the archetype.

| Archetype          | What it is                              | Template emphasis / sharpest non-goals to probe |
|--------------------|-----------------------------------------|--------------------------------------------------|
| **library**        | reusable code, no runtime users/data    | non-goals usually: *no* app, *no* persistence, *no* network. Value = API surface, stability. |
| **cli**            | tool run on the user's own machine      | watch: destructive operations, handling of local files/secrets. Value = speed, offline use. |
| **service**        | network-facing app / web / API          | personal-data & auth surface. Non-goals often bound *whose* data and *how long*. |
| **data-pipeline**  | ingests / stores data at scale          | source legality (robots/ToS), consent, retention, PII minimisation. Non-goals bound sources & scope. |
| **ai-system**      | model-driven outputs or decisions       | automated-decision surface. Non-goals bound what stays under human control. |
| **local-app**      | GUI/desktop/mobile app on the user's own device | local personal data & files; watch what **leaves** the device (telemetry, sync, crash reports). Value = privacy, offline-first. |

Pick the closest single archetype (a repo can be a CLI *and* handle data — choose the one
that carries the sharpest non-goals). If nothing fits, use a plain label of your own and say
so. **Derive it from the repo** when you can (manifest, entry points, dependencies,
network/DB/model usage); only ask if the repo is genuinely ambiguous.

## Structure of BUSINESS.md

Keep this section order:

1. **Purpose** — what it is and what it does, in 2–4 sentences.
2. **Archetype** — one line: the label above (`library | cli | service | data-pipeline |
   ai-system | local-app`, or your own), plus a few words of why.
3. **Target user** — who it is for.
4. **Value** — why it is worth it (speed, privacy, accuracy, cost, ...).
5. **Scope (in-scope)** — what the project covers, including "Later:" items.
6. **Non-goals** — what it deliberately does NOT cover (the project's boundaries).
7. **What success looks like** — what done / good looks like.

Put a short blockquote at the top of the file with the doc router (status → `PROGRESS.md` ·
rules → `CLAUDE.md` · why-we-chose-X → `DECISIONS.md` · posture → `COMPLIANCE.md`), matching
the shipped `BUSINESS.md` header. When bootstrapping over the shipped skeleton, keep its
router blockquote, its archetype trigger-note blockquote and its how-to HTML comment —
replace only the section bodies. If the repo already has a `BUSINESS.md` or another doc,
adopt its tone and format; otherwise: short bullets, **bold** keywords, and the same language
as the rest of the repo (documentation, comments).

## Question bank

Ask **2–4 questions** when the repo pre-answers part of the base set; on a bare repo where
nothing is derivable, up to **5**. When trimming, **non-goals and success are never
dropped** — they are the two the repo can never answer. If the archetype itself had to be
asked, its extension questions follow in a second, shorter round. Never ask what the repo
already answers; fill those in directly.

**Base (every project):**
- Purpose / value — what pain does it solve, why is it worth doing?
- Target user — who is it for?
- Non-goals — what is explicitly **out of scope**? (the most valuable answer)
- Success — what does "done / good" look like?

**Archetype extension — add the sharpest 1–2:**
- **library** — what must the public API *never* do (no I/O, no global state, ...)? what
  breaks if it grows an app around itself?
- **cli** — does it ever mutate/delete the user's files? does it touch secrets or the network?
- **service** — whose personal data does it hold, and for how long? what is out of bounds for
  that data (selling, profiling, sharing)?
- **data-pipeline** — which sources are in/out of bounds (ToS, robots, licences)? what is the
  retention/consent boundary?
- **ai-system** — what is the **intended purpose**, and what decisions must a human keep? what
  automated use is explicitly a non-goal?
- **local-app** — what does it store on the device, and does **any** of it leave (sync,
  telemetry, crash reports)? what must never require an account or the network?

## Three modes

**Dispatch — pick the mode first:**

- invoked as **`/business audit`** → **Mode 3**;
- `BUSINESS.md` absent, or with **no user-written content** (every section still the shipped
  `<placeholder>` text) → **Mode 1**;
- anything else → **Mode 2**. A **half-filled** file is Mode 2, not Mode 1: sections a person
  wrote are never rewritten wholesale; only sections still holding `<placeholder>` text are
  filled in, with Mode 1's explore-then-ask care. "Bootstrap over it" licenses overwriting
  the shipped skeleton — never hand-written text.

### Mode 1 — BUSINESS.md is absent, or still the shipped template (bootstrap)

> **A file whose sections are still `<placeholder>` text counts as absent.** The kit ships
> `BUSINESS.md` as a skeleton, so a fresh project *has* the file without having any content —
> bootstrap over it, do not diff against it. Unfilled placeholders are the signal. (A file
> where only *some* sections are placeholders is Mode 2 — see the dispatch above.)

Proceed like `/init` — **explore, determine the archetype, then ask, then write**:

1. **Explore the repo** and derive whatever you can without asking:
   - `README*`, `docs/`, any web page or project description;
   - `CLAUDE.md` / `AGENTS.md` / `PROGRESS.md`, if they exist;
   - the package manifest (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, ...)
     — name, description, entry points, dependencies;
   - the structure of `src/` and the main modules / commands;
   - `git log` — what is actually being built, and in which direction.
2. **Determine the archetype** from what you found (see the table). If the repo is
   genuinely ambiguous, make it one of your questions.
3. **Ask me the questions the bank yields** — 2–4 when the repo pre-answers part of the
   base set, up to 5 on a bare repo, per the bank's trimming and second-round rules. Do
   not ask about things already readable from the repo.
4. **Write `BUSINESS.md`** following the structure above (archetype line included): combine
   the derived facts with my answers. Where something is missing, mark it as open with an
   `Open:` bullet rather than guessing — never with `<angle-bracket>` text, which the
   dispatch above reads as "still the shipped skeleton".

### Mode 2 — BUSINESS.md exists and is filled in (update)

1. **Read** the whole `BUSINESS.md` first. If its sections are still `<placeholders>`, this is
   a fresh install — go to Mode 1 instead.
2. **Compare it against the state of the project** — go through the README, the code,
   `PROGRESS.md` and recent commits, and note what was added or changed relative to what is
   written.
3. **Only edit the affected sections** — do not touch unchanged parts.
4. **Check consistency:** move completed "Later:" items from the plan into the real scope
   (in-scope); verify the non-goals still hold (what was once out of scope may have become a
   goal — or the reverse); **re-check the archetype still fits** (a library that grew a
   service is no longer a library).
5. If you are unsure about a change of direction, **ask** — do not guess.

### Mode 3 — `audit` (check reality against the declared intent)

Invoked as **`/business audit`**. This is one of the kit's **commit-time gate** checks (the
ship gate is `/audit-history`): it does
not touch the document, it **reports** whether what the repo is *doing* still matches what
`BUSINESS.md` *declares*. It owns **non-goal / scope** drift only — an undocumented decision
(a new dependency, a new pattern) is `/decision audit`'s finding and regulated ground is
`/compliance audit`'s, so one hunk is flagged once.

> **Unless `/compliance` is not installed** (`.claude/skills/compliance/` absent — the project
> opted out, attest ADR-0030). Then its ground is re-assigned by the ladder's table and its
> last row is **yours**: regulated ground with no choice and no bytes behind it is a finding
> *here*, because what is missing is a **declaration**. That covers the whole of the row —
> a bare new personal-data field, a model or automated decision wired in with nothing to
> weigh, a new data source / export / transfer, a feature on prohibited (Art 5) ground.
> Report it **once**, with the clause *"regulated ground; /compliance is not installed in this
> project."*
>
> **Take the severity from the ladder, not from this paragraph.** Its floor stands in every
> audit: special-category or national-ID personal data, or an Art 5 practice, is a
> **blocker** — inheriting a ground must never be able to lower what it would have scored.
> Everything else on the row is **major**. This is the only thing that makes you fire on
> something other than a non-goal, and only while that skill is absent.

You own what the code **does**;
`/audit-history` owns what the repo **ships** (bytes in the tree or history) — so a violated
*behaviour* non-goal ("no network access") is yours, even if it looks like a leak risk.

1. **Read `BUSINESS.md`** — focus on **Non-goals** and **Scope**; note the archetype.
2. **Survey reality** — the working diff (`git diff` and `git diff --staged`), the commits
   since the last audit or the last `BUSINESS.md` edit (not the whole history — repeated
   gate runs must not re-flag the same old drift), and the code/dependency structure. For an
   AI-system also note new models/automated decisions; for a service/pipeline note new data
   flows or sources.
   *Run as a `/gate` pass you have no git at all* — scope from the material handed to you
   instead: `diff.patch` is the change under audit, `log-docs.txt` dates the last
   `BUSINESS.md` edit, and the names in `gate-records.txt` carry the shas they gated — match on
   the sha, not on the order (a record may be written late, so name order is write order;
   attest ADR-0032). Take the later of those two as the window's start. If neither file reached
   you, audit the diff alone and **say so in the verdict** — an unscoped pass may re-flag
   drift a previous run already reported.
3. **Check each declared non-goal** — is the repo now doing the thing it said it would not?
   **Check scope** — is work landing *outside* the stated scope (creep), and are any
   "Later:" items now actually done (stale plan)? Sanity-check the **archetype** still fits.
4. **Return a short verdict** (shared audit ladder — see `.claude/skills/_shared/audit-ladder.md`). For each finding: a
   one-line description, **evidence** (file / commit / diff hunk), and a severity —
   - **blocker** — a stated non-goal is being violated;
   - **major** — real work outside the declared scope, or the archetype no
     longer fits;
   - **minor** — a stale "Later:" item, or wording that has drifted.
   End with a recommended `BUSINESS.md` update (which section, roughly what) — but **do not
   make it**. If nothing drifted, say so in one line. **The audit writes nothing.**
5. **One extra verdict line, only when it applies.** If `/compliance` is **not installed** and
   this diff (or the archetype no longer fitting) plainly triggers regulated scope, add:
   *"the compliance call may need re-making: &lt;the trigger&gt;; re-run `install.sh --compliance`
   — or, in a repo generated from the template, `COMPLIANCE.md` and
   `.claude/skills/compliance/` are already there and only need filling."* A pointer, not a
   finding: it never moves the verdict line. Without it the call made at bootstrap is never
   revisited, and the trigger is an event that arrives later (attest ADR-0030).

**Audit writes nothing.** If I agree with a finding, I re-run the skill in update mode
(Mode 2) to change the document.

## The compliance call — make it here, once, after the archetype

`/compliance` and `COMPLIANCE.md` are **opt-in**: `install.sh` does not land them, because at
install time nobody yet knows whether the project is in regulated scope, and an empty
`COMPLIANCE.md` is worse than none — it reads as *"posture declared"* to every later audit
while declaring nothing (attest ADR-0030). The archetype you just established is the first
moment the question can actually be answered, so answer it here.

After bootstrap or update (**not** in `audit` mode), check whether `.claude/skills/compliance/`
exists, and weigh what you just recorded — the archetype, the target user, whether personal
data or a model-driven decision is anywhere in scope.

**If the skill is present and the project is plainly in scope**, check whether `COMPLIANCE.md`
actually says anything: if its sections are still `<placeholder>`, say so and point at
`/compliance` — a present-but-empty posture file is the state ADR-0030 calls worse than none,
and the template path produces it by default. If it is filled, say nothing; it is where it
belongs. **If it is present and the project is plainly out of scope** (a repo generated from
the template button gets it whether or not it needs it), say so and recommend deleting
`COMPLIANCE.md` and `.claude/skills/compliance/`, plus recording the one-sentence reason as
below. **If it is absent**, say **one** of two things, in one or two lines:

- **In scope, or genuinely uncertain** — name the trigger you saw (personal data, an
  automated decision, an EU market placement, a regulated sector) and tell me to re-run the
  installer with `--compliance`, then `/compliance`. Uncertainty resolves toward installing
  it: the cost of the skill sitting unused is a directory, the cost of a missing posture is
  a finding nobody owns.
- **Out of scope** — say so plainly with the reason in one clause, and recommend I record
  that single sentence somewhere durable (a line in `BUSINESS.md`'s non-goals is the usual
  home: *"no personal data, no EU market placement — regulatory posture out of scope"*).
  A recorded "out of scope, because …" is a real declaration; an absent file is not.

**In `audit` mode the call is not re-opened here.** Mode 3 step 5 carries the one exception —
a single pointer line when a later change triggers regulated scope — and it is written there
rather than restated here because Mode 3 is the section `/gate` hands to the subagent. Two
copies of one rule drift apart; this one did.

Never create `COMPLIANCE.md` yourself, and never guess a legal tier — the archetype is a
trigger, not a classification (attest ADR-0001).

## After editing

- **Bootstrap / update:** do **not** commit automatically — leave the commit to me (`docs:`).
  Briefly summarize which sections you changed/created and why. Change nothing other than
  `BUSINESS.md`.
- **Audit:** read-only — report the verdict, change nothing at all.
