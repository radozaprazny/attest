---
name: compliance
description: >-
  Creates and maintains COMPLIANCE.md — the project's declared compliance posture
  (which regimes apply, the self-assessed classification, the obligations that follow, data
  handling). EU-first (EU AI Act + GDPR as two independent axes). Reads BUSINESS.md's archetype
  as a TRIGGER for whether the AI Act may apply — it never assigns the legal tier from the
  archetype alone. Two modes: bootstrap and update. Surfaces provisions & checklists, NEVER
  a legal verdict. Optionally verifies live via an EU-AI-Act MCP if one is connected; works
  offline without it. Do NOT use it for status (PROGRESS.md), rules (CLAUDE.md), non-goals
  (BUSINESS.md) or decision rationale (DECISIONS.md).
disable-model-invocation: true
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
structure. **Dates, penalties and current status are NOT baked in** — they shift (Art 5, GPAI
and high-risk phase-in). Nothing in this file is a source for what the law says **today**: check
it. Two different instruments share the name *Digital Omnibus* and they are not in the same
state — the one on **AI** amends the AI Act itself, the one on **data** would amend the Data Act
and repeal the DGA — so a line about "the Omnibus" is ambiguous before it is stale. This
paragraph carries no date on purpose: a kit that ships a legal status ships a fact with a
shelf life, and this one is written to send you to a live source instead.

If an **EU-AI-Act MCP** is connected (an account connector or a project `.mcp.json` — see
GUIDE PART 6), use it to *enrich and verify*: look up a provision, classify a description,
list obligations for a role/risk, check a deadline, check a document for gaps. Where the live
result and the offline checklist **diverge**, mark it open ("posture gap — verify"),
never as a verdict for either side. Cite which findings were MCP-verified in §9.

## Two modes

The argument `audit` is retired: say `/gate` checks regulated ground before a push, and stop.

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

## After editing

- Do **not** commit automatically — leave the commit to me (`docs:`).
  Change nothing other than `COMPLIANCE.md`. Summarize what you classified and every open gap.
