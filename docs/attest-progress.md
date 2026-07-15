# attest — live status (thread-carrier)

> **This is attest's own status — not part of the kit.** `install.sh` never copies `docs/`.
> The `PROGRESS.md` at the repo root is an empty **template** for *your* project; attest's own
> status lives here, because ADR-0006 (and the Phase 7 devlog) record what happens when the two
> are confused: attest shipped its own phase log to every downstream repo, and `/checkpoint` is
> delta-only so it could never clear what it inherited. Decisions → `attest-decisions.md` ·
> history → `attest-devlog.md`.

## Current state

Working through a post-audit fix series: **8 commits planned, 2 landed, tree clean.**
Branch `main`, nothing pushed. Approved plan: `~/.claude/plans/eager-meandering-quail.md`.

Baseline is green and must stay green. **Neither tool is on `PATH`** — use `uvx`:

```bash
uvx ruff@0.15.21 check .
uvx ruff@0.15.21 format --check .
uvx --from shellcheck-py shellcheck install.sh
```

## Done

- **`1ea4760` `refactor: rename /init-tier to /business`** — `git mv` + all 43 hits rewritten
  except the append-only ADR log. Deleted the collision-only disambiguation (GUIDE's
  `"tier" ≠ legal tier` blockquote, three `("tier")` aliases in the skill); kept every
  substantive archetype-is-a-trigger-not-a-legal-tier statement (ADR-0001 logic). Appends
  **ADR-0009**.
- **`95d1806` `refactor: move audit ladder into .claude/skills/_shared`** — new
  `.claude/skills/_shared/audit-ladder.md` is now canonical; the 4 audit skills + reviewer read
  it at runtime instead of "GUIDE PART 3". GUIDE keeps a summary, marked as one. `install.sh`
  GUIDE warning softened. Appends **ADR-0010**.

## Next — in order

3. **`docs: note /reload-skills and the SKILL.md-text-only reload caveat`** — the **downgraded**
   FIX 3. See "The one finding that flipped" below before touching this. Enrichment only.
4. **`fix: skip stray files (pycache, .DS_Store, editor backups) on install`** — add to
   `copy_tree_if_absent`'s `find` in `install.sh:~46`:
   `! -name '*.pyc' ! -name '.DS_Store' ! -name '*.swp' ! -name '*~' ! -path '*/__pycache__/*'`.
   Bug is **reproduced**: plant those four in a kit copy, run `install.sh` into an empty dir,
   all four land. Re-run to confirm zero. `shellcheck` must stay clean.
5. **`ci: add template-cleanup workflow so generated repos start clean`** (+ **ADR-0012**) —
   ⚠️ **safety-critical, see below.**
6. **`ci: add opt-in ci.yml.example (ruff + shellcheck)`** — commented out, header "rename to
   ci.yml and adapt". `.github/` is confirmed **absent** from install.sh's copy list.
7. **`feat: add /gate — one command for the commit-time gate`** (+ **ADR-0011**) — biggest
   remaining piece. `.claude/skills/gate/SKILL.md`, `disable-model-invocation: true`. All five
   skills are `disable-model-invocation: true`, so **`/gate` cannot invoke them via the model** —
   it reads their `SKILL.md` and runs their audit sections, and the skill body must say so
   explicitly. Delegates each audit to a **subagent** (reviewer + 3 general-purpose), which is
   the kit's own token-hygiene principle (GUIDE PART 4); running 4 audits inline pulls 4
   SKILL.mds + 3 docs + the diff into main context. Merges under `_shared/audit-ladder.md`,
   applies the ownership contract, returns **one** verdict. Scope is the **commit-time** gate
   (reviewer + `/business` + `/decision` + `/compliance` audits); `/audit-history` stays the
   separate **ship** gate — GUIDE PART 9 keeps those cadences apart. Update GUIDE PART 3 + 9
   and the README.
8. **`docs: lead the README with real audit results and the adoption gradient`** (+ **ADR-0013**).
   - Verdict block: source **strictly** from `attest-devlog.md`. **Do not fabricate a terminal
     transcript or invent `file:line` evidence** — a compliance kit faking an audit output in
     its own public README is the exact failure it exists to prevent. The four real results:
     archetype came out `service` not `ai-system` (no server-side model) · a planted false
     non-goal caught · `/decision audit` found four real unrecorded decisions and correctly did
     *not* re-flag the recorded one · `full` caught a secret alive only in history.
   - Adoption gradient: "minimum viable attest is three documents" (CLAUDE + PROGRESS +
     BUSINESS); DECISIONS at team/long-project scale; COMPLIANCE only if regulated. README
     table gains an "Adopt" column (inside the enumeration ADR-0002 already sanctions, so it
     opens no new duplication site); GUIDE PART 1 carries the principle as canonical prose.
9. **Final** — acceptance sweep, then a multi-lens adversarial review of the whole diff, then
   the `reviewer` subagent, as requested.

## ⚠️ The one finding that flipped — read before doing #3

The audit's **FIX 3 is wrong** and I downgraded it *with the user's approval*. It wanted GUIDE
PART 3's hot-reload claim rewritten to *"slash-only skills always need a RESTART;
`/reload-skills` doesn't rebuild the slash index."* Verified against Claude Code **v2.1.210**:

- `/reload-skills` **does exist** (in the binary: *"Pick up skills added or changed on disk
  during this session"*). Its impl re-scans skills and emits a change event.
- The claim that reload doesn't rebuild the slash index is **unsupported**. The only documented
  reload caveat is for **plugin** folders (`hooks/`, `.mcp.json`, `agents/`, `output-styles/`
  → `/reload-plugins`).
- `disable-model-invocation: true` governs **auto-invocation only**, not reload. Docs:
  *"prevent Claude from automatically loading this skill. Use for workflows you want to trigger
  manually with `/name`."*
- Official [skills.md § Live change detection](https://code.claude.com/docs/en/skills.md):
  adding a skill under an existing `.claude/skills/` *"takes effect within the current session
  without restarting"*; creating the **top-level** skills dir mid-session *"requires restarting"*.

**GUIDE's existing sentence is a faithful paraphrase of that and stays.** Executing FIX 3 would
put a falsehood in a public repo's manual. README step 4 / `install.sh` NEXT 1 already say
"restart" for the correct reason (attest's install *creates* `.claude/` — the documented case).
The audit looks like a correct observation generalised one step too far. #3 is now: add
`/reload-skills` as the manual nudge + note live detection covers `SKILL.md` text only.

## ⚠️ Safety-critical for #5

`gh repo view` → `isTemplate: true`, so `github.event.repository.is_template == false` holds the
cleanup workflow inert in attest. **That guard is one GitHub toggle away from deleting attest's
own README, `docs/` and `install.sh`.** Use **both**:

```yaml
if: github.event.repository.is_template == false && github.repository != 'radozaprazny/attest'
```

Also add `workflow_dispatch` (repo-creation pushes don't reliably fire). The workflow deletes
`docs/`, `install.sh`, `.github/workflows/ci.yml.example`, stubs README, rewrites LICENSE to an
MIT skeleton with `<YEAR>`/`<YOUR NAME>`, commits, then deletes itself. **No warning header in
LICENSE** — the devlog records that one broke GitHub's licence detection and was reverted.

## Notes / standing constraints

- **`docs/attest-decisions.md` is append-only.** Check every commit: `git diff -U0
  docs/attest-decisions.md | grep -c '^-[^-]'` must be **0**. ADR-0001…0008 stay byte-identical.
- **`init-tier` survives in exactly 13 places, all deliberate**: 6 in ADR-0001…0008 (verbatim
  history), 6 in ADR-0009 (narrating the rename), 1 in the devlog (phase 2's narrative). A grep
  hit there is correct, not a miss.
- ADR numbering: **0009, 0010 landed**; **0011** = `/gate`, **0012** = template-cleanup,
  **0013** = payoff-forward. ADR-0009/0010 deliberately do **not** supersede ADR-0001/0005 —
  those decisions still stand; only individual *consequences* were retired.
- `_shared/` relies on verified-but-undocumented behaviour: a dir under `.claude/skills/` with
  no `SKILL.md` is silently ignored (tested — real skills loaded, `_shared` neither listed nor
  warned about). If that changes, move the file and update the 5 references.
- Repo is **public** and a **template**. Nothing is pushed yet — push is the user's call.
