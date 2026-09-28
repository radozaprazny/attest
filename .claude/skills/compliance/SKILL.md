---
name: compliance
description: >-
  Writes or updates COMPLIANCE.md, the project's self-assessed posture under the EU AI Act and
  the GDPR, starting from BUSINESS.md's Regulated line. Cites provisions by ID; never a legal
  verdict, never a legal date.
disable-model-invocation: true
---

# /compliance — under what rules it operates (COMPLIANCE.md)

The argument `audit` is retired: say `/gate` checks regulated ground before a push, and stop.

Only the posture goes here: status → `PROGRESS.md` · rules → `CLAUDE.md` · why it exists →
`BUSINESS.md` · why X over Y → `DECISIONS.md`. A compliance-relevant choice keeps its rationale
in a `DECISIONS.md` entry; this file records the obligation and names that entry's heading.

## 1. Start from BUSINESS.md

Read `## Regulated` in `BUSINESS.md`. It is a trigger, never the classification.

- Missing: suggest `/business` first; go on only if the person says so.
- `No`: say so; write only §1 of the template, and only if the person wants the reason kept.
- `Yes`: read the README, manifest, model and data code, then walk both axes: the AI Act if
  it is an AI system (Art 3(1)) or a GPAI model (Art 3(63)); the GDPR if it processes
  personal data of people in the EU. An axis that does not fire gets "out of scope —
  <why>".

## 2. Create or update

- No `COMPLIANCE.md`, or only the kit's old `<placeholder>` template: write the template below,
  filled from the repo. Unknowns become `Open:` bullets, never a guess.
- A filled file: compare it with the project (the §8 re-check triggers; a role change under
  Art 25(1)), edit only the affected sections and refresh `Last reviewed`.
- Keep the §7 ship-guard line if `.claude/hooks/ship_guard.sh` exists; otherwise drop it.

## 3. Rules

- Cite provisions by ID; never paste regulation text.
- Every posture line is a self-assessment citing its provision ("high-risk, Annex III 4(a)"),
  never a settled legal fact such as "compliant" or "lawful".
- No legal date comes from this skill. Check application dates, penalties, national law and
  amendments live (a connected EU AI Act MCP, else EUR-Lex); record the date checked and the
  consolidated version served. Where the live text and the file disagree, write "posture gap —
  verify".
- When unsure, ask.

## 4. Close

Do not commit. Touch no file but `COMPLIANCE.md`. Summarise the role, the level and every
`Open:` item.

## Template

```markdown
# COMPLIANCE.md — compliance posture

> Self-assessment, not legal advice: each line cites a provision; none is a verdict.
> AI Act: Regulation (EU) 2024/1689, consolidated · GDPR: Regulation (EU) 2016/679.

## 1. Scope

- **Applies:** <regimes and why; territorial: AI Act Art 2(1), GDPR Art 3>
- **Does not apply:** <regimes ruled out, and why>

## 2. AI Act — threshold (tick what holds)

- [ ] Not an AI system (Art 3(1)): AI Act out of scope, go to §6.
- [ ] An AI system (Art 3(1)) we provide or deploy.
- [ ] A GPAI model we provide (Art 3(63)): Art 53; Art 55 if systemic risk (Art 51).
- [ ] A system built on a GPAI model, ours or a third party's: we are its downstream provider
  (Art 3(68)); a general-purpose AI system if it serves many purposes (Art 3(66)).
- **Art 2 exclusions:** <none, or which: national security 2(3); sole-purpose research 2(6);
  pre-market R&D, not real-world testing 2(8); personal use 2(10); open-source unless
  high-risk, Art 5 or 50 2(12)>

## 3. AI Act — role and level

- **Role:** <provider Art 3(3) / deployer Art 3(4) / importer / distributor>
- **Level:** <prohibited, Art 5(1) point; high-risk, Art 6(1) + Annex I or Art 6(2) +
  Annex III point; minimal, no Art 5 or 6 ground>
- **Art 5(1) ruled out:** <(a) manipulation; (b) exploiting vulnerabilities; (ba)
  non-consensual intimate imagery of an identifiable person and (bb) child sexual abuse
  material, both read with 5(1a); (c) social scoring; (f) emotion inference at work or school>
- **Art 6(3) derogation:** <not claimed / Annex III point, condition (a)–(d), no profiling;
  documented (Art 6(4)), registered (Art 49(2))>
- **Art 25(1) tripwire:** a distributor, importer, deployer or other third party becomes a
  high-risk provider if it:
  - (a) puts its name or trademark on one already on the market;
  - (b) substantially modifies one that stays high-risk;
  - (c) changes a non-high-risk system's intended purpose, general-purpose ones included, so
    it becomes high-risk.

  <none / which limb>

## 4. AI Act — duties at every level

- **Art 4 AI literacy:** providers and deployers support their operating staff's AI literacy:
  <measures>
- **Art 50 transparency**, alongside any level (Art 50(6)); per paragraph, <how, or n/a>:
  - (1) provider: people told they interact with an AI system
  - (2) provider: synthetic audio, image, video or text marked machine-readable
  - (3) deployer: people exposed to emotion recognition or biometric categorisation told
  - (4) deployer: deep fakes, and AI text published on matters of public interest, disclosed

## 5. AI Act — high-risk duties by role (keep yours)

Provider:

- Art 16: Section 2 requirements, quality management, documentation, logs, conformity
  assessment, declaration, CE marking, corrective action.
- EU database registration: Annex III except point 2 (Art 49(1)); Art 6(3) derogations
  (Art 49(2)).
- Post-market monitoring (Art 72), serious incidents (Art 73).

Deployer (Art 26):

- Use per instructions 26(1), human oversight 26(2), input data 26(4), monitoring 26(5),
  logs 26(6), telling workers 26(7) and affected people 26(11).
- Registration only as a public authority or Union body (Art 26(8), Art 49(3)).
- Art 27 fundamental rights impact assessment (FRIA) only as a public-law body, a private
  provider of public services, or under Annex III 5(b) creditworthiness or 5(c) life and health
  insurance pricing; never point 2. It may reuse the DPIA (27(4)).

## 6. GDPR (personal data of people in the EU)

- **Personal data:** <what, whose>; **role:** <controller / processor>
- **Lawful basis (Art 6)**, **special categories (Art 9)**, retention and minimisation,
  data-subject rights, DPIA (Art 35), records (Art 30), transfers (Ch V): <each that applies>

## 7. Data handling

- <each personal-data field: where stored, retention, sub-processors, transfer destinations>
- **`.attest/tmp/ship-guard.log`** (the kit's ship guard): a local store you did not create,
  every publish, submit or upload command it matched, cut at 120 characters: addresses and
  paths verbatim, credentials masked. Gitignored, per checkout, no automatic expiry: manual
  deletion per machine, so an erasure request (GDPR Art 17) reaches it clone by clone.

## 8. Posture and gaps

- Per duty: met / open / n/a + evidence; unknowns as `Open:` bullets.
- **Application dates** per duty: verify live, record the date checked.
- **National layer**, authorities (Art 70) and penalties (Art 99): verify live, record the
  date checked.
- **GDPR joints**, DPIA input (Art 26(9)), the FRIA–DPIA link in §5, bias-detection data
  (Art 4a): verify live, record the date checked.
- **Re-check on:** a new personal-data field, model, automated decision or data source; a role
  change.
- **Decisions:** <the `DECISIONS.md` entry heading per compliance-relevant choice>
- **Last reviewed:** <date>

## 9. Sources

- <provisions relied on; for each checked live: where, consolidated version, date>
```
