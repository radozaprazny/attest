# COMPLIANCE.md — compliance posture

> Under **what rules** the project must operate. **EU-first.** Records THIS project's
> *posture*, not the law — cite provisions by article/ID; never paste regulation text (look it
> up live via a connected AI-Act MCP, or by ID). status → `PROGRESS.md` · why-it-exists →
> `BUSINESS.md` · rules → `CLAUDE.md` · why-we-chose-X-over-Y → `DECISIONS.md`.
> (full table: GUIDE PART 1)

<!--
How to use this file:
  - Run /compliance to bootstrap/update this posture. Run /compliance audit to check whether
    a diff touches regulated ground against it (read-only). The audit fires ONLY on regulated
    ground (new personal-data field, new model/automated decision, new data source) — not on
    every diff.
  - Reads BUSINESS.md §Archetype as a TRIGGER only ("the AI Act MAY apply — run the real
    classification"), never as the tier itself. A non-ai-system archetype (a service, a
    data-pipeline, even a library) can still be in scope.
  - AI Act and GDPR are TWO INDEPENDENT axes. Fill each only if its trigger fires.
  - Self-assessment — surfaces provisions/checklists and gaps, NEVER a legal verdict.
  - A compliance-relevant CHOICE is recorded once: its why/alternatives in DECISIONS.md, its
    regulatory consequence here, cross-referenced by ADR id.
  - If BUSINESS.md / its Archetype line is missing: run /business first, or derive a
    provisional archetype from the repo — do not fail.
-->

## 1. Regulatory scope

- **Applies:** <which regimes — EU AI Act, GDPR, … — and *why*>.
- **Does not apply:** <regimes ruled out, and why — scoping is as valuable as a non-goal>.
- **Territorial:** <EU AI Act Art 2 / GDPR Art 3 — placed on the EU market? EU data subjects?>

## 2. AI Act — threshold (if this fires, fill §3–§5)

- Is it an **'AI system'** (Art 3(1): machine-based, autonomy, inference) or a **GPAI model**
  (Art 3(63))? <yes / no>. If **no** → *out of AI-Act scope*, skip to §6.

## 3. AI Act — role (self-assessed)

- **Role:** <provider / deployer / importer / distributor> — obligations follow role more
  than tier.
- **Tripwire — Art 25 substantial modification:** a deployer who materially changes a system,
  or puts its own name on it, becomes a **provider**. <does this apply?>

## 4. AI Act — risk level (self-assessment, provision-cited)

- **Level:** <prohibited (Art 5) / high-risk (Annex I product safety, or Annex III + which
  point) / limited — transparency (Art 50) / minimal>. Cite the provision that puts it there.
- **GPAI (separate axis):** <if a GPAI model — Art 53 obligations; systemic-risk Art 55?>

## 5. AI Act — obligations + phase-in

- <obligations that follow from §3+§4: transparency, human oversight, records/logging,
  fundamental-rights impact assessment (FRIA, Art 27, for high-risk), conformity assessment,
  registration>.
- **Dates:** <phase-in per obligation> — **VERIFY live** (Art 5 / GPAI / high-risk dates are
  shifting post-Digital-Omnibus; confirm via a connected AI-Act MCP or the official
  text; do not hardcode).

## 6. GDPR posture (independent axis — fill if you process personal data of people in the EU)

- **Personal data processed?** <what, whose>.
- **Lawful basis:** <Art 6 — consent / contract / legitimate interest / …>.
- **Special categories (Art 9):** <health, biometric, … — present? extra conditions?>.
- **Role:** <controller / processor>.
- **Retention & minimisation · data-subject rights · DPIA (Art 35) · records (Art 30) ·
  transfers (Ch V)** — <one line each that applies>.

<!-- If you use the kit's ship guard, one local store exists that you did not create:
     `.attest/tmp/ship-guard.log` — every publish/submit/upload command the guard matched, with
     only JSON-breaking characters stripped, so an address or a credentialed URL survives
     verbatim — a path or filename counts, not only an address. Gitignored and never shipped, so
     it exists once per developer checkout and syncs with nothing; nothing in the kit rotates,
     truncates or expires it. The §7 retention line is therefore "no automatic expiry; manual
     deletion, per machine" — and an Art 17 request reaches it only clone by clone.
     Name it below if this project is in scope (attest ADR-0038, GUIDE PART 2.2). -->

## 7. Data handling (the concrete map — §6 says *which* duties apply, §7 the actual values)

- <PII inventory · where each field is stored · the actual retention windows · sub-processors /
  transfer destinations>.

## 8. Posture & gaps

- Per obligation: **met / open / N-A** + one line of evidence.
- **Re-check triggers:** a new personal-data field · a new model or automated decision · a new
  data source.
- **Last reviewed:** YYYY-MM-DD.

## 9. Sources

- <provisions relied on — article/ID refs; mark which were MCP-verified>.

> **Disclaimer (standing):** Self-assessment. Provisions & checklists only — **NOT legal
> advice**. Confirm with your DPO / legal counsel. Deadlines and penalties: verify live
> (Digital Omnibus pending). The archetype label lives in `BUSINESS.md`; the legal
> classification it may *trigger* — never determine — lives only here.
