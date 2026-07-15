---
name: business
description: >-
  Creates, maintains and audits BUSINESS.md — the project's business context (why
  it exists, for whom, its value, scope and non-goals). Works like /init, but for
  BUSINESS.md: it first establishes the project's ARCHETYPE (library / CLI / service
  / data-pipeline / AI-system), which selects a tailored template and a focused
  question set. Three modes: bootstrap (write the file in a new project),
  update (reconcile it against the project's state), and `audit` (check reality —
  code, commits, diff — against the declared non-goals and scope, read-only).
  Generic — usable in any project. Do NOT use it for live status (that belongs in
  PROGRESS.md) or for rules/conventions (they belong in CLAUDE.md).
disable-model-invocation: true
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

Pick the closest single archetype (a repo can be a CLI *and* handle data — choose the one
that carries the sharpest non-goals). If nothing fits, use a plain label of your own and say
so. **Derive it from the repo** when you can (manifest, entry points, dependencies,
network/DB/model usage); only ask if the repo is genuinely ambiguous.

## Structure of BUSINESS.md

Keep this section order:

1. **Purpose** — what it is and what it does, in 2–4 sentences.
2. **Archetype** — one line: the label above (`library | cli | service | data-pipeline |
   ai-system`, or your own), plus a few words of why.
3. **Target user** — who it is for.
4. **Value** — why it is worth it (speed, privacy, accuracy, cost, ...).
5. **Scope (in-scope)** — what the project covers, including "Later:" items.
6. **Non-goals** — what it deliberately does NOT cover (the project's boundaries).
7. **What success looks like** — what done / good looks like.

Put a short blockquote at the top of the file with the doc router (status → `PROGRESS.md` ·
rules → `CLAUDE.md` · why-we-chose-X → `DECISIONS.md` · posture → `COMPLIANCE.md`), matching
the shipped `BUSINESS.md` header. If the repo already has a `BUSINESS.md` or another doc,
adopt its tone and format; otherwise: short bullets, **bold** keywords, and the same language
as the rest of the repo (documentation, comments).

## Question bank

Ask a **total of 2–4 questions** — the base ones plus a couple from the archetype row.
Never ask what the repo already answers; fill those in directly.

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

## Three modes

### Mode 1 — BUSINESS.md is absent, or still the shipped template (bootstrap)

> **A file whose sections are still `<placeholder>` text counts as absent.** The kit ships
> `BUSINESS.md` as a skeleton, so a fresh project *has* the file without having any content —
> bootstrap over it, do not diff against it. Unfilled placeholders are the signal.

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
3. **Ask me 2–4 targeted questions** from the question bank — the base ones plus the
   archetype's sharpest extensions. Do not ask about things already readable from the repo.
4. **Write `BUSINESS.md`** following the structure above (archetype line included): combine
   the derived facts with my answers. Where something is missing, mark it as open rather
   than guessing.

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

Invoked as **`/business audit`**. This is one of the kit's pre-ship "gate" checks: it does
not touch the document, it **reports** whether what the repo is *doing* still matches what
`BUSINESS.md` *declares*. It owns **non-goal / scope** drift only — an undocumented decision
(a new dependency, a new pattern) is `/decision audit`'s finding and regulated ground is
`/compliance audit`'s, so one hunk is flagged once. You own what the code **does**;
`/audit-history` owns what the repo **ships** (bytes in the tree or history) — so a violated
*behaviour* non-goal ("no network access") is yours, even if it looks like a leak risk.

1. **Read `BUSINESS.md`** — focus on **Non-goals** and **Scope**; note the archetype.
2. **Survey reality** — `git log` / recent commits, the working diff (`git diff` and
   `git diff --staged`), and the code/dependency structure. For an AI-system also note new
   models/automated decisions; for a service/pipeline note new data flows or sources.
3. **Check each declared non-goal** — is the repo now doing the thing it said it would not?
   **Check scope** — is work landing *outside* the stated scope (creep), and are any
   "Later:" items now actually done (stale plan)? Sanity-check the **archetype** still fits.
4. **Return a short verdict** (shared audit ladder — see GUIDE PART 3). For each finding: a
   one-line description, **evidence** (file / commit / diff hunk), and a severity —
   - **blocker** — a stated non-goal is being violated;
   - **major (scope creep)** — real work outside the declared scope, or the archetype no
     longer fits;
   - **minor** — a stale "Later:" item, or wording that has drifted.
   End with a recommended `BUSINESS.md` update (which section, roughly what) — but **do not
   make it**. If nothing drifted, say so in one line. **The audit writes nothing.**

**Audit writes nothing.** If I agree with a finding, I re-run the skill in update mode
(Mode 2) to change the document.

## After editing

- **Bootstrap / update:** do **not** commit automatically — leave the commit to me (`docs:`).
  Briefly summarize which sections you changed/created and why. Change nothing other than
  `BUSINESS.md`.
- **Audit:** read-only — report the verdict, change nothing at all.
