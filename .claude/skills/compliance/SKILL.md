---
name: compliance
description: >-
  Creates, maintains and audits COMPLIANCE.md — the project's declared compliance posture
  (which regimes apply, the self-assessed classification, the obligations that follow, data
  handling). EU-first (EU AI Act + GDPR as two independent axes). Reads BUSINESS.md's archetype
  as a TRIGGER for whether the AI Act may apply — it never assigns the legal tier from the
  archetype alone. Three modes: bootstrap, update, and `audit` (does the diff touch regulated
  ground — a new personal-data field, a new model/automated decision, a new data source —
  against the declared posture; read-only). Surfaces provisions & checklists, NEVER a legal
  verdict. Optionally verifies live via an EU-AI-Act MCP if one is connected; works offline
  without it. Do NOT use it for status (PROGRESS.md), rules (CLAUDE.md), non-goals
  (BUSINESS.md) or decision rationale (DECISIONS.md).
disable-model-invocation: true
argument-hint: "[audit]"
---

# /compliance — declared compliance posture (COMPLIANCE.md)

This skill maintains **`COMPLIANCE.md`** — the record of **under what rules** the project must
operate: which regimes apply, the self-assessed classification, the obligations that follow,
and how personal data is handled. **EU-first.** It records the project's *posture*, not the
law — it cites provisions by article/ID and **never reproduces regulation text or issues a
legal verdict**.

The skill is **generic** — work with what you actually find in the repo, and assume nothing
about the specific project.

## The control documents — keep them separate

**Anti-duplication:** status → `PROGRESS.md` · rules → `CLAUDE.md` · why-it-exists →
`BUSINESS.md` · why-we-chose-X-over-Y → `DECISIONS.md` · under-what-rules → `COMPLIANCE.md`.
Write each fact in exactly one place. (full table: GUIDE PART 1)

> The three "why" docs collide here — fence them. A specific technical **choice and its
> rationale** is a `DECISIONS.md` entry; `COMPLIANCE.md` records only the **standing
> obligation** that binds it, cross-referenced by ADR id. A product **boundary** is a
> `BUSINESS.md` non-goal, not an obligation.

## Two axes, EU-first

The AI Act and the GDPR are **independent axes** — fill each only if its own trigger fires:

- **EU AI Act** — trigger: is it an **AI system** (Art 3(1)) or a **GPAI model**? The
  archetype in `BUSINESS.md` is only a *hint* that it *may* apply — a `service` or
  `data-pipeline` embedding a model is in scope just as an `ai-system` is; a deterministic
  tool is out. The **level** (prohibited Art 5 / high-risk Annex I or III / limited Art 50 /
  minimal) follows the **intended purpose + the Annexes + Art 5**, *not* the archetype.
- **GDPR** — trigger: do you process **personal data of people in the EU**?
  Archetype-independent — it applies in a `library` just as in a `service`. Its own structure:
  lawful basis (Art 6), special categories (Art 9), controller/processor, retention, DPIA
  (Art 35), records (Art 30), transfers (Ch V).

Record the classification as a **self-assessment backed by a cited provision**, under the
standing disclaimer — never as a settled legal fact.

## The optional MCP

The **core works offline**: the structural checklist (the risk pyramid, the Annex III use
cases, the provider/deployer split, Art 50, the GDPR basics) is baked into `COMPLIANCE.md`'s
structure. **Dates, penalties and current status are NOT baked in** — they shift (Art 5,
GPAI and high-risk phase-in; the Digital Omnibus is adopted-but-not-in-force and moving dates).

If an **EU-AI-Act MCP** is connected (an account connector or a project `.mcp.json` — see
GUIDE PART 6), use it to *enrich and verify*: look up a provision, classify a description,
list obligations for a role/risk, check a deadline, check a document for gaps. Where the live
result and the offline checklist **diverge**, report it as **major** ("posture gap — verify"),
never as a verdict for either side. Cite which findings were MCP-verified in §9.

## Three modes

### Mode 1 — COMPLIANCE.md is absent, or still the shipped template (bootstrap)

> **A file whose sections are still `<placeholder>` text counts as absent.** The kit ships
> `COMPLIANCE.md` as a skeleton — bootstrap over it, do not diff against it.
>
> **One thing in the skeleton is not a placeholder: carry it forward.** If this project uses the
> kit's ship guard, `.attest/tmp/ship-guard.log` is a local store the adopter did not create —
> every publish/submit/upload command the guard matched, with addresses, credentialed URLs and
> file paths surviving verbatim. It is gitignored and per-checkout, and nothing in the kit prunes
> it. Write it into §7 with the retention line *"no automatic expiry; manual deletion, per
> machine"*. Bootstrapping over the template would otherwise drop the only notice of it (attest
> ADR-0038).

1. **Read `BUSINESS.md`** — its **Archetype** and **Non-goals**. If `BUSINESS.md` or the
   Archetype line is missing, recommend running `/business` first, or derive a **provisional**
   archetype from the repo (the same derivation `/business` uses) — do not fail.
2. **Run the two triggers** (AI system / GPAI? · personal data of EU people?). Fill only the
   axes that fire; for an axis that does not, record *out of scope* and why.
3. **Classify** — walk the AI-Act axis (§2 threshold → §3–§5) and/or the GDPR axis (§6),
   citing provisions by ID. Use the MCP if present to verify; otherwise mark dates/penalties
   **VERIFY**.
4. **Write `COMPLIANCE.md`** from the shipped structure. Mark every open item; guess nothing.

### Mode 2 — COMPLIANCE.md exists and is filled in (update)

1. **Read** the whole file — if its sections are still `<placeholders>`, go to Mode 1 instead.
2. **Compare** against the project (new data flows, a new model, a
   role change — watch the Art 25 substantial-modification tripwire). 3. **Edit only affected
   sections**; refresh **Last reviewed**. 4. If a regime's applicability changed, say so and
   re-cite. If unsure, **ask** — do not guess a legal conclusion.

### Mode 3 — `audit` (does the diff touch regulated ground?)

Invoked as **`/compliance audit`**. Read-only. It **owns regulated ground** — a scope/non-goal
question is `/business audit`'s and an undocumented decision that lands on no regulated ground
is `/decision audit`'s (the ladder's `/decision` ↔ `/compliance` edge settles the overlap), so
one hunk is flagged once.

### Step 0 — the posture check, before anything else

**You are installed, so this project's posture is your ground whether or not the diff touches
it.** Before the trigger, ask one question: **is a posture declared at all?** *No posture
declared* means either `COMPLIANCE.md` is **absent**, or it exists with its sections still
`<placeholder>` text — the same rule Modes 1 and 2 apply. Both count, and keying this on the
file merely *existing* is how the state comes back: a user told to "delete it" would land in a
repo where this skill still owns regulated ground and nothing ever speaks.

If no posture is declared, say so in **one line**, a **minor**, which never moves the verdict
on its own:

> *"no posture declared (`COMPLIANCE.md` absent / still placeholders) while `/compliance` is
> installed — run `/compliance` to fill it, or remove **both** `COMPLIANCE.md` and
> `.claude/skills/compliance/` and record in one sentence why the project is out of scope."*

Removing **both** is what the rest of the kit says (README, GUIDE PART 9, the template-cleanup
stub README) and it is the only remedy that leaves a consistent state: with the skill gone, the
ladder re-assigns this ground to another audit; with the skill present and the file gone,
nobody owns it. Never advise deleting the file alone.

**One escape.** If the project *ships* `COMPLIANCE.md` as a template for someone else and keeps
its own posture elsewhere — the kit's own repo is the case, and `/gate`'s `$DOCS` and the
declaration hook's `ATTEST_BUSINESS` handle the same ADR-0006 tension — then a posture recorded
in that other place satisfies this check. Say where you found it and move on.

Report this once, here. Do **not** repeat it in step 1 of the full pass.

### The trigger check

**Do this on the diff and nothing else** (step 0 above has already run): no `COMPLIANCE.md`, no
MCP call, no other document. Look for any of —

- a new or renamed **field, column, parameter or log line** that can hold personal data (name,
  email, phone, address, IP, device or account identifier, location, or anything
  special-category under Art 9 — health, biometrics, ethnicity, beliefs, sex life);
- a new **model, inference call, score, ranking or automated decision** about people;
- a new **data source, export, third-party SDK, or cross-border transfer**;
- anything resembling a **prohibited (Art 5)** practice.

**No hit → return step 0's line, if it applied, plus exactly `out of scope — nothing in this
diff touches regulated ground`, and stop.** That is the whole audit; it is the common case and
it is a correct result. One hit → the full pass:

1. **Read `COMPLIANCE.md`** — the declared posture. If step 0 already found none, carry that
   forward and do not compare the diff against an empty file; do not file the finding twice.
2. **Scan the diff for regulated ground** — a new **personal-data field**, a new **model or
   automated decision**, a new **data source / transfer**, a feature touching a **prohibited
   (Art 5)** practice (biometric categorisation, emotion recognition, scraping, scoring →
   highest severity).
3. **Compare to the posture** — is this covered, or a gap? Use the MCP to check obligations /
   gaps if present.
4. **Return a short verdict** (shared audit ladder — see `.claude/skills/_shared/audit-ladder.md`). For each finding: a
   one-line description, **evidence** (`file:line` / commit), and a severity —
   - **blocker** — a new feature bearing on a **prohibited (Art 5)** practice, personal data
     handled with no lawful basis in the posture, or any **special-category (Art 9) or
     national-ID** field: the ladder's floor is absolute and applies here first, before this
     list;
   - **major** — regulated ground the declared posture does not cover;
   - **minor** — a stale citation, a missing **Last reviewed**, an un-cited obligation.

   If the hunk is also an **unrecorded decision** (a new dependency, a swapped library), it is
   still yours alone under the ladder's `/decision` ↔ `/compliance` edge — name the missing ADR
   in one clause of your finding rather than leaving it to a second one.
   Phrase findings as *"this diff may bear on Art X — re-check the classification"*, **never**
   *"this is now high-risk / non-compliant"* (that is for a human/DPO). End with a recommended
   `COMPLIANCE.md` update — but **do not** make it. If the full pass finds the posture already
   covers everything the trigger caught, say so in one line. **The audit writes nothing.**

## After editing

- **Bootstrap / update:** do **not** commit automatically — leave the commit to me (`docs:`).
  Change nothing other than `COMPLIANCE.md`. Summarize what you classified and every open gap.
- **Audit:** read-only — report the verdict, change nothing at all.
