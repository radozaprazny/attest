# GUIDE.md — reference guide

What this dev-kit contains, **how to run it** and **what it is for**. The kit is reusable —
copy `.claude/` plus the doc templates into a new project (see the end).

> Sections are numbered **per PART** (1.1, 1.2, … then 3.1, 3.2, …) so a new skill can be
> slotted in without renumbering the rest. PARTs are referenced by name ("see PART 6").

---

## PART 1 — Control documents

The kit runs on **five living documents**. Only `CLAUDE.md` is held in context every turn;
the other four are read **on demand** by their skills, so the system stays cheap no matter
how much it holds. (This PART and the README table are the *only* two full enumerations —
everywhere else carries the one-line router below.)

### 1.1 `CLAUDE.md` — project rules and conventions
- **How:** a file in the repo root; loaded **automatically every turn**. Quick add: start a
  prompt with `#` and Claude appends the line for you.
- **What for:** the project's permanent memory (language, tests, commit style). Whatever you
  put here, Claude always knows.
- **When:** settled rules. Keep it **lean** (it is always in context = it costs tokens).
- **Never:** `@path`-import the other four docs here — `@path` imports are always-on and cost
  tokens every turn; skills read them on demand.

### 1.2 `PROGRESS.md` — live status (thread-carrier)
- **How:** sections Current state / Done / Next / Notes. Update it after every block.
- **What for:** carries the thread across `/clear` — after a restart the session picks up
  where you left off. Notes hold only **transient** resume-context (open threads, gotchas) —
  a durable "why we chose X" belongs in `DECISIONS.md`, not here.
- **When:** always before `/clear`. It solves the token problem (you need not hold
  everything in context).

### 1.3 `BUSINESS.md` — business context (why the project exists)
- **How:** purpose / archetype / user / value / scope / non-goals / success.
- **What for:** the "what and for whom" reference — above all **non-goals** (the boundary,
  what NOT to do). Records the project **archetype** (a lightweight kind-of-software label).
- **When:** when deciding direction; check new ideas against it so you do not creep the scope.

### 1.4 `DECISIONS.md` — decision log (why we chose X over Y)
- **How:** an **append-only** ADR-lite log — one short entry per notable choice
  (Context / Options / Decision / Why / Consequences). Never edit a past entry (except
  flipping its `Status` line when superseded); to reverse one, append a superseding entry.
- **What for:** preserves the **roads not taken** — the alternatives weighed and why they
  lost, which a git commit message does not keep queryably.
- **When:** on a choice with lasting rationale (a dependency, an architectural pattern, a
  threshold). A routine change is a commit, not an ADR.

### 1.5 `COMPLIANCE.md` — compliance posture (under what rules it operates)
- **How:** the declared posture — which regimes apply (EU AI Act, GDPR), the self-assessed
  classification and the obligations that follow. **EU-first.** Cites provisions by ID; never
  reproduces the law.
- **What for:** the "under what rules" reference — so a regulated project knows its standing
  duties and can check a diff against them.
- **When:** if the project is in regulated scope. Records provisions & checklists, **never a
  legal verdict**.

> **Anti-duplication rule:** status → PROGRESS · rules → CLAUDE · why-it-exists → BUSINESS ·
> why-we-chose-X → DECISIONS · under-what-rules → COMPLIANCE. **Each fact in exactly one
> place.** The three "why" docs are the collision point: BUSINESS = *why the project exists* ·
> DECISIONS = *why this choice beat the alternative* · COMPLIANCE = *which external rule
> forces it*.

---

## PART 2 — Hooks (`.claude/settings.json` + `.claude/hooks/`)

### 2.1 Auto-format hook (`PostToolUse`)
- **How:** runs **by itself** after every edit of a `.py` file → tidies its imports, then
  runs `ruff format` on it.
- **What for:** the code is always formatted and its imports always sorted; you never think
  about style.
- **This one is a Python example — and it is two files, not one:**
  - `.claude/hooks/format_py.py`, wired in as the `PostToolUse` entry of
    `.claude/settings.json` (lint-fixes and formats, filters on `.py`, and no-ops when the
    file is not Python or `ruff` is not on `PATH`);
  - `ruff.toml` in the repo root (supplies the rules: line length, rule sets).

  The hook auto-fixes **import hygiene only** (`I001`, `E401`). It deliberately does *not*
  run the full `--fix`: `F401` would delete an import the moment you write it, before the
  code that uses it exists. The rest of `[lint]` is yours to run — `ruff check .`.

  Swapping languages means replacing **both** — prettier + `.prettierrc`, rustfmt +
  `rustfmt.toml`, gofmt, ... — and deleting `ruff.toml`.

  **Two caveats the kit will not paper over.** (1) All three hooks are Python scripts run as
  `python3 …`, so **`python3` must be on `PATH`** — in a repo without it they fail on every
  matching event rather than staying quiet. If you are not using them, delete their entries
  from `.claude/settings.json`; the `.py` filter makes the format hook *inert* in a non-Python
  repo, not *absent*. (2) **`ruff.toml` wins over `pyproject.toml`** — ruff resolves
  `ruff.toml` > `.ruff.toml` > `[tool.ruff]` and does **not** merge them. Dropping ours into a
  project that already configures ruff silently overrides your rules while leaving them on
  disk as dead code. `install.sh` therefore refuses to copy it if you configure ruff anywhere.

### 2.2 `PreCompact` hook — nudge toward `/checkpoint`
- **How:** runs **by itself** just before compaction; if the thread-carrier has not changed in
  a while, it reminds you to "run /checkpoint".
- **What for:** a safety-net so you save state before losing context.
- **If your thread-carrier is not `PROGRESS.md`** (some projects call it `TIMESHEET.md`), set
  `ATTEST_THREAD_CARRIER` to its name. If the file does not exist the hook stays **silent** —
  a project that keeps no thread-carrier is not nagged about one.

### 2.3 `Stop` hook — long-session warning
- **How:** runs **by itself** after every response; above 500 transcript lines it warns once:
  "long session → /checkpoint + /clear".
- **What for:** tells you when it is time to clean up the context.

> **The hook pattern:** *event (when) → your shell command (what)*. Exit `2` = block the action.
> Always **fail-open** (an error must not break the session). Verify a new hook via `/hooks`
> (and approve it).

---

## PART 3 — Skills (`.claude/skills/<name>/SKILL.md`)

Each **gate** skill both **writes** its document and **audits** reality against it —
`/init-tier`, `/decision`, `/compliance` (`/audit-history` audits without owning a document;
`/checkpoint` maintains `PROGRESS.md` as a live snapshot, not an audit). All the audits share
one output shape and one severity ladder so they read as a family:

> **Shared audit ladder:** **blocker** (top, always the bare word) / **major (domain alias)** /
> **minor**. Aliases: `/init-tier` *major (scope creep)*, `/decision` *major (undocumented
> decision)*, `/compliance` *major (posture gap)*, `/audit-history` *major (PII / client name)*.
> Always a blocker: a secret, special-category / national-ID personal data, a violated
> non-goal, a prohibited (Art 5) practice. Always minor: metadata, large files, stale wording.
> **Ownership — one hunk is flagged once:** `/decision` owns *a new dependency / swapped
> library / new pattern / notable threshold*; `/init-tier audit` fires only on a non-goal /
> scope violation; `/compliance audit` fires only on regulated ground; `/audit-history` owns
> only what the repo **ships** — content in the tree or history. The line between the last two
> and `/init-tier` is **content vs behaviour**: code that *does* something a non-goal forbids
> is `/init-tier`'s; bytes that must not leave are `/audit-history`'s.

### 3.1 `/init-tier` — creates/maintains/audits `BUSINESS.md`
- **How:** type `/init-tier`. It first fixes the project's **archetype** (library / cli /
  service / data-pipeline / ai-system), which picks a tailored template + question set. Three
  modes: **bootstrap** (file absent), **update** (compare against project state), and
  **`/init-tier audit`** (check reality — code, commits, diff — against the declared
  non-goals/scope; read-only, reports a verdict, changes nothing).
- **What for:** business context — like `/init` for CLAUDE.md, but for BUSINESS.md. The
  archetype is only a **trigger** for `/compliance` (it signals the AI Act *may* apply) — it
  is **not** the legal risk tier, which `/compliance` sets in COMPLIANCE.md.

### 3.2 `/checkpoint` — token/context hygiene
- **How:** type `/checkpoint` (it has `disable-model-invocation` → manual only). Derives
  state from git, updates PROGRESS, advises `/clear` vs `/compact`.
- **What for:** one word pours the session state into PROGRESS → then you can `/clear` safely.
- **When:** before every `/clear`, or when the Stop hook warns you.

### 3.3 `/decision` — records/audits `DECISIONS.md`
- **How:** type `/decision` to **record** a decision just made (append-only ADR-lite entry);
  `/decision audit` finds decisions **made in code but never written down** (a new dependency,
  a swapped library, a new pattern) — read-only.
- **What for:** the queryable log of *why X over Y*, alternatives included. It owns the
  "undocumented decision" finding so the other audits don't double-flag the same hunk.

### 3.4 `/audit-history` — the clean-history leak gate (no doc)
- **How:** `/audit-history` scans the working tree + the diff about to be pushed;
  `/audit-history full` scans the **entire history** (all commits/branches). Read-only.
- **What for:** the pre-ship gate — before code leaves the machine, catch secrets, personal
  data (EU-first GDPR), client names and metadata leaks. It maintains **no document** (its
  record is the git history itself) and never rewrites history — it reports and recommends.

### 3.5 `/compliance` — creates/maintains/audits `COMPLIANCE.md`
- **How:** `/compliance` bootstraps/updates the posture; `/compliance audit` checks whether a
  diff touches **regulated ground** (a new personal-data field, a new model, a new data source)
  against it — read-only. EU-first (AI Act + GDPR as two independent axes). Reads the
  `BUSINESS.md` archetype only as a **trigger**.
- **What for:** the "under what rules" record — self-assessed classification + obligations,
  citing provisions by ID, **never a legal verdict**. Optionally verified live via an
  EU-AI-Act MCP (see PART 6); the core works offline.

> **"tier" ≠ legal tier:** the archetype `/init-tier` records (a.k.a. the project's "tier") is
> **not** the AI-Act risk tier — that is set here, by `/compliance`, in `COMPLIANCE.md`.

> **The skill pattern:** `description` is the brain (when Claude offers it — and when NOT).
> The body is the instructions. A new skill under an existing `.claude/skills/` hot-reloads;
> a **new top-level directory** needs a restart.

---

## PART 4 — Subagent (`.claude/agents/reviewer.md`)

### 4.1 `reviewer` subagent — pre-commit code review
- **How:** ask for it — "use the reviewer subagent to review the diff" — or `@`-mention it
  (`@"reviewer (agent)"`) to guarantee it runs. Read-only.
- **What for:** walks the diff + conventions + tests → returns a **short verdict**
  (blocker/major/minor/nit) in **its own context** → your main context stays clean.
- **When:** before committing a larger change.

> **Subagent vs skill:** a subagent has its **own context window** and returns only the
> conclusion = token hygiene — which is what keeps a long autonomous run affordable.

> **Additive, not a replacement:** native `/code-review` and `/simplify` already cover bugs
> and cleanups. The reviewer checks what they do not — your `CLAUDE.md` conventions,
> commit-readiness, and the anti-duplication rule. Its leak check is a shallow per-diff sniff;
> the deep, history-wide scan is `/audit-history`.

---

## PART 5 — Autonomy (`/loop`, built in)

### 5.1 `/loop` — interval scheduling
- **How:** `/loop 5m <prompt>` runs it every 5 minutes; prompt-only (`/loop <prompt>`) lets
  Claude self-pace.
- **What for:** recurring or polling work — watch a CI run, poll a deploy, re-run a check.
- **When:** you want repetition **on a clock**.
- **Always:** for "keep going until it's done", put a **checkable** stop condition in the
  prompt — one a command can decide (the test command exiting `0`), not a matter of taste.
  Auto mode (`Shift+Tab`) keeps a long run from stopping on approval prompts.

---

## PART 6 — MCP (pattern)

### 6.1 A project MCP server — your app as tools
- **What for:** another AI app (or Claude) can drive **your** application in **natural
  language**, through tools you define — instead of shelling out to your CLI.
- **How:** a small server living in your repo speaks MCP over **stdio**. The pattern, in
  Python with FastMCP (`pip install mcp`):

  ```python
  from mcp.server.fastmcp import FastMCP

  mcp = FastMCP("my-app", instructions="What the client should know up front.")

  @mcp.tool()
  def do_thing(arg: str) -> dict[str, str]:
      """One-line summary the client sees. Document arg formats here."""
      if not arg:
          raise ValueError("arg must not be empty")   # -> a clean tool error, not a traceback
      return {"result": arg}

  def main() -> None:
      mcp.run()   # stdio transport
  ```

  Wire it into the repo with a checked-in `.mcp.json`. The kit ships **`.mcp.json.example`** as
  the single source of truth — rename it, adjust, then approve it once at `claude` startup
  (`/mcp`). Illustrative shape (the real, commented copy is `.mcp.json.example`):

  ```json
  { "mcpServers": { "my-app": {
      "command": "${CLAUDE_PROJECT_DIR:-.}/.venv/bin/python",
      "args": ["-m", "my_app.mcp_server"], … } } }
  ```

  The `${CLAUDE_PROJECT_DIR:-.}` prefix is the load-bearing part — it resolves against the repo
  root so the config travels. Keep secrets out of this file (it is git-tracked); the example
  carries the full warning.
- **Lessons worth keeping:**
  - **Config from env, read per call** (not at import) — the server then does not depend on
    when the client started it, and tests can isolate via `monkeypatch.setenv`.
  - **Raise a plain error with a human message** — MCP turns it into a tool error; never let
    a traceback escape.
  - **Tool functions stay ordinary functions** (the decorator returns them unchanged), so
    you can test them directly — but let at least one test go through the real MCP layer
    (`call_tool`).
  - **Keep the SDK an optional extra**, so the core of your app stays dependency-free.
- **Two layers of MCP:** account connectors (configured in claude.ai, available everywhere)
  vs a **project `.mcp.json`** (lives in the repo, travels with the kit).
- **Consuming someone else's MCP** is the same wiring in reverse: point `.mcp.json` at their
  server (or add it as an account connector) and its tools appear in your session. This is how
  `/compliance` optionally verifies against a live **EU-AI-Act knowledge server** — if one is
  connected it looks up provisions, obligations and deadlines; if not, its baked-in structural
  checklist still works. The kit names no server and requires none: the skill degrades to
  offline rather than failing.

---

## PART 7 — Driving Claude Code (operations)

- **Plan mode** (`Shift+Tab`) — Claude proposes a plan first, you approve → then it acts.
- **Approve modes** — `1. Yes` (once) · `2. don't ask again` (allowlists into
  `settings.local.json`) · auto mode. Allowlist only what is **safe + frequent**
  (`git add`, tests, `ls`); leave `rm`/`push`/`commit` on confirmation.
- **`/clear`** — clean slate (between blocks, after updating PROGRESS). **`/compact`** —
  condense (mid-task).
- **`/model`** — switch model.
- **`/hooks`** — review/approve hooks · **`/mcp`** — MCP servers · **`/agents`** — only
  prints a pointer now (wizard removed in v2.1.198); edit `.claude/agents/` or ask Claude.
- **`/rc`** (`/remote-control`) — watch/drive the session from your phone (claude.ai/code or
  the app). Good for long autonomous runs.
- **`claude install`** — native installer (no sudo, working auto-updates) · **`/doctor`** —
  diagnostics.
- **`#` prefix** — quickly append a rule to CLAUDE.md.
- **Conventional Commits** (`feat:`/`fix:`/`chore:`/`docs:`) + **Co-Authored-By** — clean
  history; one commit = one logical unit; *history should tell the truth*.

---

## PART 8 — Reusing the whole kit

```bash
./install.sh <path-to-your-project>
```

That is the whole procedure — do **not** hand-copy the files. The script is **copy-if-absent**:
every doc, skill, hook, `settings.json` and `ruff.toml` is installed only if the target does
not already have it, `.gitignore` is **appended to** rather than replaced, and `ruff.toml` is
refused outright if you configure ruff anywhere (it would silently override you — see PART 2).
It prints an **INSTALLED** list and a **SKIPPED** list naming every file it refused to touch,
so you can merge those by hand.

It deliberately does **not** copy `README.md`, `LICENSE`, `docs/` or itself — those are
*attest*, not your project. `GUIDE.md` is the one file it always lands, because the installed
skills reference "GUIDE PART 1/2/3" at runtime and the shared audit ladder and the
audit-ownership contract live only there; if you already have a `GUIDE.md` of your own, the
kit's goes in beside it as `attest-GUIDE.md` rather than replacing yours.

Afterwards: **restart Claude Code** (`.claude/` is a new top-level directory, so the skills
only load on a fresh session — until then `/init-tier` does not exist), fill `CLAUDE.md`
(`/init`), then declare with `/init-tier`, `/decision` and `/compliance`. Promote mature skills
into **`~/.claude/skills/`** → available globally, in every project.

---

## PART 9 — The compliance-native workflow

The pieces above compose into one governed lifecycle. It runs on **three cadences** — set up
once, loop every change, gate before you ship — so read it as two loops around a gate, not a
single straight line.

**SETUP — once, at the start**
- `/init-tier` — declare intent + the archetype (`BUSINESS.md`).
- `/compliance` — **only if in regulated scope** — establish the posture (`COMPLIANCE.md`).
  Run `/init-tier` first: `/compliance` reads the archetype (and if it is missing, offers to
  derive a provisional one).

**PER-CHANGE — every unit of work**
1. **Decide → `/decision`** — record a choice worth keeping (append-only) *as you make it*.
2. **Build.**
3. **Gate, before the commit** — separate, cheap steps; each fires only when relevant:
   - the `reviewer` subagent — the code-level pass;
   - `/init-tier audit` — did the work cross a non-goal / creep past scope?
   - `/decision audit` — a choice made in code but never recorded?
   - `/compliance audit` — did the diff touch regulated ground? (skips unless it did)

   Each **owns** its own finding, so one hunk is flagged once.
4. **Commit** (`feat:` / `fix:` / `docs:` …) — one logical unit.
5. **`/checkpoint`** — pour state into `PROGRESS.md`, then `/clear` between blocks.

**SHIP — before code leaves the machine**
- `/audit-history` — the quick leak scan, **every push**.
- `/audit-history full` — the whole-history scan, **before a public release** (a secret or a
  name in *any* old commit, not just `HEAD`).

> **Reading key:** the SETUP row runs **once**; the PER-CHANGE loop repeats **every commit**;
> the SHIP gate fires only when code **leaves the machine**. `/compliance` appears in both —
> *bootstrap* in setup, *audit* in the per-commit gate.

That is the whole claim: a repo that can answer the questions an auditor asks — what it is
for, what it will not do, why it chose what it did, under what rules it operates, and that it
ships nothing it should not — because each of those has a **living document** and a **gate**
that checks reality against it.
