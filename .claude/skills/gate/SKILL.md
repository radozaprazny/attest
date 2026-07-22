---
name: gate
description: >-
  The commit-time gate as one command. Runs the code-level reviewer subagent plus the three
  document audits — /business audit (non-goals/scope), /decision audit (unrecorded
  decisions), /compliance audit (regulated ground) — each in its own subagent, then merges
  their findings under the shared audit ladder and ownership contract into ONE verdict and
  appends a dated run record under .attest/ (the attestation that the gate ran). Touches no
  control document and changes no code — the run record is its only write. Does NOT include
  /audit-history (that is the separate ship gate, run before a push/release). Generic —
  usable in any repo. Run it before a commit; each sub-audit fires only where relevant.
disable-model-invocation: true
---

# /gate — the commit-time gate, one command

One command instead of four. `/gate` runs the **commit-time** half of GUIDE PART 9's loop —
the `reviewer` subagent (code-level) plus the three document audits — and returns **one**
merged verdict. The **ship** gate stays separate: run `/audit-history` before a push and
`/audit-history full` before a public release; `/gate` deliberately excludes it so the two
cadences (every commit vs. leaving the machine) stay distinct.

The skill is **generic** — work with what you actually find in the repo, and assume nothing
about the specific project.

> **Router (this skill owns no doc):** status → `PROGRESS.md` · rules → `CLAUDE.md` ·
> why-it-exists → `BUSINESS.md` · why-we-chose-X-over-Y → `DECISIONS.md` · under-what-rules →
> `COMPLIANCE.md`. (full table: GUIDE PART 1)

## How to run the four passes

**Do not invoke the audit skills as skills.** Every skill in this kit is
`disable-model-invocation: true` — they cannot be model-invoked from here. Instead, **read
each skill's `SKILL.md` and hand its audit-mode section to a subagent**:

1. **Scope first, cheaply, in the main context** — `git status --porcelain`,
   `git diff HEAD --stat`. If the tree is clean, gate the last commit (`git show HEAD`)
   and say so in the verdict.
2. **Launch four subagents in parallel**, each read-only, each returning only findings:
   - the **`reviewer` subagent** (`.claude/agents/reviewer.md`) — the code-level pass,
     run as itself;
   - one **general-purpose subagent per document audit**, each given: the audit-mode
     section of its skill (`.claude/skills/business/SKILL.md` Mode 3 ·
     `.claude/skills/decision/SKILL.md` Mode 2 · `.claude/skills/compliance/SKILL.md`
     Mode 3), the shared ladder (`.claude/skills/_shared/audit-ladder.md`), and the
     instruction to apply its skill's own skip/trigger rules (`/compliance audit` runs its
     cheap trigger check first and returns "out of scope" on no hit).

   This is the kit's own token-hygiene rule (GUIDE PART 4): four audits inline would pull
   four SKILL.mds, three documents and the diff into the main context; in subagents each
   runs in its own context and returns a summary.

   A missing piece **degrades, never fails**: no `BUSINESS.md` → note "nothing declared —
   run `/business`" and skip that pass; a document still the shipped skeleton → same; the
   reviewer agent absent → say so and run the other three.
3. **Merge under the ownership contract** (`_shared/audit-ladder.md`): if two passes return
   the same hunk, keep the **owner's** finding and drop the other — the contract names the
   owner. Order everything by the shared ladder, domain aliases intact.
4. **Return ONE verdict:**
   - one line overall — ✅ *ready to commit* / ⚠️ *commit after changes* — plus a one-liner
     per pass, including the clean and skipped ones (a short clean gate is a correct
     result);
   - findings ordered by severity, each with its **owner**, **evidence** (`file:line` /
     commit / hunk) and a **severity** from the ladder;
   - each pass's recommended document update, if any — but **make none of them**.
5. **Append the run record** — the gate's only write (attest ADR-0016). Create `.attest/`
   if absent and write one new file, `.attest/gate-<UTC yyyymmdd-HHMMSS>-<HEAD short sha>.md`:

   ```markdown
   # gate run — <UTC ISO timestamp>
   - HEAD: <sha> (<branch>) · tree: <dirty — gated the working diff | clean — gated HEAD>
   - kit: <the "Kit version:" value from .claude/skills/_shared/audit-ladder.md, if present>
   - passes: reviewer <ran|skipped|degraded> · business <…> · decision <…> · compliance <…>
   - verdict: <✅ ready to commit | ⚠️ commit after changes>
   - findings: <n> blocker · <n> major · <n> minor <(owner per finding, one line each)>
   ```

   The directory is append-only: never edit or delete a previous record. Recommend staging
   the record **with the commit it gates** — that is what makes "the gate ran" a fact in
   history rather than a memory. The record holds the verdict summary only: never the
   findings' full text, and never a fact whose home is a control document (the router
   stands).

**The gate writes nothing to the control documents and nothing to code** — the run record
above is its one artifact. If a finding warrants a document change, that is the owning
skill's write mode, run by me afterwards — recording stays a separate, human-approved step.
