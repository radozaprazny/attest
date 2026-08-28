# attest — live status (thread-carrier)

> **This is attest's own status — not part of the kit.** `install.sh` never copies `docs/`.
> The `PROGRESS.md` at the repo root is an empty **template** for *your* project; attest's own
> status lives here, because ADR-0006 (and the Phase 7 devlog) record what happens when the two
> are confused. Decisions → `attest-decisions.md` · history → `attest-devlog.md`.

## Current state

The **audit fix series (phase 10)** is **merged** — PR #3, merge commit `ce439a5`. `main`
carries it.

In progress: the **lean-kit series (phase 11)**, branch `feat/lean-kit`, uncommitted at the
time of writing. It comes from a design pass that asked one question of every component —
*would a new adopter miss this if it were gone?* — and removed everything that answered no.
Measured into an empty directory, a default install goes from **23 items to 18** (16 files +
2 `.gitignore` lines; 20 with `--compliance`) — but the composition is the point, not the
count: **0** of them edit your code, **0** are bound to a language, **0** are inert. The kit
also drops from *"needs `python3` on `PATH`"* to *"needs `git` and `/bin/sh`"*. What it changes, by ADR:

- **ADR-0027** — the formatter is gone: `format_py.py`, `ruff.toml`, the `.ruff_cache/` ignore
  line, `has_ruff_config`/`has_python_markers`, and the cleanup's Python parity branch. Nothing
  in the kit edits your code any more. Supersedes ADR-0015 and ADR-0024.
- **ADR-0028** — the two advisory hooks (`PreCompact` nudge, `Stop` long-session warning) are
  replaced by two that prevent rather than remind:
  - `session_declaration.sh` (`SessionStart`) — reads the **Non-goals** of `BUSINESS.md` and
    the **Current state**/**Next** of `PROGRESS.md` into context at every session start, so a
    blocker-severity rule is known *before* the code exists. Silent while the documents are
    still `<placeholder>` text; capped **per section** (24 / 8 / 8), ~52 lines worst case, and
    a trimmed section says how much it dropped.
  - `ship_guard.sh` (`PreToolUse` on `Bash`) — matches commands that publish/submit/upload and
    answers `permissionDecision: "ask"` unless `.attest/` holds an `/audit-history` record
    naming the **current** HEAD sha. `/audit-history` therefore now writes
    `ship-<date>-<time>-<sha>.md` — its first and only artifact.
- **ADR-0029** — the middle rung loses its per-skill alias; three bare rungs. Supersedes the
  alias half of ADR-0005 (`nit` in the reviewer is untouched).
- **ADR-0030** — `COMPLIANCE.md` and `/compliance` are opt-in (`install.sh --compliance`), and
  `/business` makes the call once it knows the archetype. The ladder gains the absent-owner
  rule; `/gate` distinguishes *"not installed"* from *"skipped"*. The template path keeps both
  files on purpose (a generated repo has no installer to re-run).
- **ADR-0032** — a gate run record may be written **late** and says so in its own first line;
  its filename then carries the write time, so name order in `.attest/` is write order and
  anything scoping to "since the last audit" matches on the HEAD sha instead. Written because
  this series' own second gate run went unrecorded until two runs later.
- **ADR-0031** — the installer reports **capabilities, not paths**: one line per group with
  ✓/·/⚠, a *YOURS, UNTOUCHED* block, a *NEEDS YOU* block, and a single line when a re-run
  changed nothing. `.mcp.json.example` and `ci.yml.example` are gone; `install.sh` now copies
  nothing at all from `.github/`. Supersedes ADR-0021.

Also in the series, without an ADR: the shipped `CLAUDE.md` asks for **your** format command
instead of documenting ruff; GUIDE PART 2 is rewritten around the two hooks and gains a 2.3
naming what the kit deliberately does *not* hook; PART 6 keeps the MCP pattern but writes the
`.mcp.json` shape inline; PART 8 documents the new report and the flag; README gains a "what it
does not ship" paragraph; `ci.yml` drops its ruff step and shellchecks the hooks instead.

**Kit version is now 0.3.0** (`.claude/skills/_shared/audit-ladder.md`).

Repo is **private** on GitHub (`radozaprazny/attest`), template button on. Going public is
a separate, deliberate step.

Baseline stays green — shellcheck is not on `PATH`, use `uvx`:

```bash
uvx --from shellcheck-py shellcheck install.sh scripts/*.sh .claude/hooks/*.sh
./scripts/smoke.sh          # 104 assertions
```

There is no linter step for another language because the kit no longer contains one.

## Next

- **Open the PR.** `/gate` ran **four** times on this working tree (records under `.attest/`,
  committed with the change they gate); every finding was addressed and the baseline is green.

  **It landed as one commit, not the planned commit-per-ADR.** ADR-0027, 0028, 0030 and 0031
  are interleaved through `install.sh` and `scripts/smoke.sh` — the formatter cannot leave
  without `settings.json` and the smoke suite moving with it, and the opt-in flag and the new
  report touch the same functions. Splitting them would have produced intermediate commits
  whose own test suite fails, which is a worse lie about the history than one honest commit
  with six ADRs in its body. ADR-0029 and ADR-0032 *were* separable; they were folded in rather
  than shipped as two one-line commits around a large one.
- **Dogfood the two new hooks in a real project** — they are unit-covered by `smoke.sh` but
  have not yet run inside a live session. The declaration hook wants a project whose
  `BUSINESS.md` non-goals are real; the ship guard wants one push and one refusal.
- **Enable branch protection** on `main` once the `ci` workflow is green — without it the
  CI reports but does not block (noted in ADR-0019).
- **Decide on going public** — before flipping visibility: re-run `/audit-history full`,
  and consider a README demo GIF (open nice-to-have; never fabricate a transcript).
- **Still never exercised in anger:** `/checkpoint` alone (it cannot be, on a template —
  ADR-0006).

## Notes / standing constraints

- **attest's own regulatory posture: out of scope.** No personal data, no model, no automated
  decision, no placement on any market — the kit is markdown and shell that runs on the
  author's machine. Recorded here because ADR-0030 makes *"out of scope, because …"* a
  declaration and an absent file not one, and attest has no filled `BUSINESS.md` of its own to
  put it in. The root `COMPLIANCE.md` stays a template for consumers; it is not attest's
  posture. (Found by the kit's own `/compliance audit` on the phase-11 gate: attest was holding
  exactly the state its new rule forbids.)
- **The `SessionStart` hook is silent in attest's own checkout** unless you set
  `ATTEST_THREAD_CARRIER=docs/attest-progress.md` in `.claude/settings.local.json` (which is
  gitignored). The shipped `.claude/settings.json` stays generic on purpose — it is the
  consumer's file, and attest's own paths must never ride out in it. Same ADR-0006 tension
  `/gate` solves with `$DOCS`. Attest has no `docs/attest-business.md`, so only the carrier
  half applies here.
- **`docs/attest-decisions.md` is append-only.** Check every commit: `git diff -U0
  docs/attest-decisions.md | grep -c '^-[^-]'` must be **0**. ADR-0001…0031 stay
  byte-identical once landed — except the one sanctioned mutation, flipping a superseded
  entry's `Status` (ADR-0003). Phase 11 flipped four: 0005, 0015, 0021, 0024.
- **Cutting a release = bump the `Kit version:` line** in
  `.claude/skills/_shared/audit-ladder.md` (ADR-0018 — the ladder is the version's one
  home; there is no VERSION file).
- **`init-tier` grep hits are deliberate** where they survive: the append-only ADR log
  (verbatim history, ADR-0009 narrates the rename) and the devlog's Phase 2 narrative.
  A hit there is correct, not a miss — do not "fix" them.
- `_shared/` relies on verified-but-undocumented behaviour: a dir under `.claude/skills/`
  with no `SKILL.md` is silently ignored by skill discovery. If that changes, move the file
  and update the references.
- **The template cleanup must stay inert in attest** — the job guards (`is_template` + the
  hard repo-name check per ADR-0012, the fork check, the payload null check) and the
  content guards inside `scripts/template-cleanup.sh` are all load-bearing; never simplify
  any of them. The script is exercised by `smoke.sh`; keep it that way.
- The repo is a **template**: the root docs are the product; attest's own records live in
  `docs/` and `scripts/` and are deleted downstream by the cleanup workflow.
