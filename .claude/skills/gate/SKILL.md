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
   `git diff HEAD --stat`. Then write the material the document audits will read to a
   temp dir, **redirected so it never enters this context**. Run it as **one** Bash
   invocation — shell state does not survive between calls, and a split run would leave `$M`
   empty and redirect to `/diff.patch`:

   `$DOCS` below is the control documents **as this repo actually keeps them** — usually
   `BUSINESS.md DECISIONS.md COMPLIANCE.md` at the root, but a repo that ships those as
   templates keeps its live ones elsewhere (attest's own are `docs/attest-*.md`). Use what
   scoping just showed you; a hardcoded list would log the skeletons and miss the real log.
   The clean-tree case is a branch **inside** the same invocation — never a second command:

   ```bash
   M=$(mktemp -d) && DOCS="BUSINESS.md DECISIONS.md COMPLIANCE.md" &&
   { git diff --quiet HEAD && git show HEAD || git diff HEAD; } > "$M/diff.patch" &&
   git status --porcelain > "$M/status.txt" &&
   git log -n 20 --date=short --format='%h %ad %s' > "$M/log.txt" &&
   git log -n 5 --date=short --format='%h %ad %s' -- $DOCS > "$M/log-docs.txt" &&
   ls -1 .attest 2>/dev/null | grep -v '^tmp$' | tail -n 3 > "$M/gate-records.txt"; echo "$M"
   ```

   `status.txt` is the full porcelain status, untracked files included. `log.txt` is **dated**
   and `log-docs.txt` holds the commits that last touched each control document — together
   with the newest `.attest/` record names (each carries the HEAD sha it gated) they are what
   lets an audit scope itself to *"since the last audit"* without git of its own. If the tree
   was clean the diff is `git show HEAD` — **say so in the verdict**, you gated the last
   commit, not pending work. **Echo `$M` and hand the absolute paths on** — step 2's
   subagents cannot expand a variable from your shell.
2. **Launch four subagents in parallel**, each returning only findings — the three
   document audits read-only **by capability**, the reviewer read-only **by rule** (it
   keeps Bash to run the tests; see its ground rules):
   - the **`reviewer` subagent** (`.claude/agents/reviewer.md`) — the code-level pass,
     run as itself;
   - one **`doc-auditor` subagent per document audit** (`.claude/agents/doc-auditor.md` —
     tools `Read, Grep, Glob`: it cannot run git, edit or write; attest ADR-0017), each
     given: the audit-mode section of its skill (`.claude/skills/business/SKILL.md` Mode 3 ·
     `.claude/skills/decision/SKILL.md` Mode 2 · `.claude/skills/compliance/SKILL.md`
     Mode 3), the shared ladder (`.claude/skills/_shared/audit-ladder.md`), the `$M` paths
     (its git material — the agent has no Bash), and the
     instruction to apply its skill's own skip/trigger rules (`/compliance audit` runs its
     cheap trigger check first and returns "out of scope" on no hit).

   This is the kit's own token-hygiene rule (GUIDE PART 4): four audits inline would pull
   four SKILL.mds, three documents and the diff into the main context; in subagents each
   runs in its own context and returns a summary.

   A missing piece **degrades, never fails**: no `BUSINESS.md` → note "nothing declared —
   run `/business`" and skip that pass; a document still the shipped skeleton → same; the
   reviewer agent absent → say so and run the other three; the `doc-auditor` agent absent
   (an older install) → fall back to general-purpose subagents with the same material and
   say in the verdict that those passes were read-only by instruction only. If a subagent
   reports it **cannot read `$M`** (a temp dir is outside the project, and a harness may
   refuse it), re-write the same material under `.attest/tmp/` inside the repo, re-run that
   pass, and delete the directory afterwards — it is scratch, never a record.
3. **Merge under the ownership contract** (`_shared/audit-ladder.md`): if two passes return
   the same hunk, keep the **owner's** finding and drop the other — the contract names the
   owner, including for the two edges it resolves explicitly. Order everything by the shared
   ladder, domain aliases intact. Reviewer `nit`s stay nits and sort last; they never change
   the verdict line.
4. **Return ONE verdict:**
   - one line overall — ✅ *ready to commit* / ⚠️ *commit after changes* — plus a one-liner
     per pass, including the clean and skipped ones (a short clean gate is a correct
     result);
   - findings ordered by severity, each with its **owner**, **evidence** (`file:line` /
     commit / hunk) and a **severity** from the ladder — plus the reviewer's `nit`s last,
     if any;
   - each pass's recommended document update, if any — but **make none of them**.
5. **Append the run record** — the gate's only write (attest ADR-0016). Create `.attest/`
   if absent and write one new file, `.attest/gate-<UTC yyyymmdd-HHMMSS>-<HEAD short sha>.md`:

   ```markdown
   # gate run — <UTC ISO timestamp>
   - HEAD: <sha> (<branch>) · tree: <dirty — gated the working diff | clean — gated HEAD>
   - kit: <the "Kit version:" value from .claude/skills/_shared/audit-ladder.md, if present>
   - passes: reviewer <ran|skipped|degraded> · business <…> · decision <…> · compliance <…>
   - verdict: <✅ ready to commit | ⚠️ commit after changes>
   - findings: <n> blocker · <n> major · <n> minor · <n> nit <(owner per finding, one line each)>
   ```

   The directory is append-only: never edit or delete a previous record. Its one exception
   is the `.attest/tmp/` scratch of step 2, which is ignored by git and deleted by the run
   that made it (attest ADR-0026) — a record is never written there. Recommend staging
   the record **with the commit it gates** — that is what makes "the gate ran" a fact in
   history rather than a memory. The record holds the verdict summary only: never the
   findings' full text, and never a fact whose home is a control document (the router
   stands).

**The gate writes nothing to the control documents and nothing to code** — the run record
above is its one artifact. If a finding warrants a document change, that is the owning
skill's write mode, run by me afterwards — recording stays a separate, human-approved step.
