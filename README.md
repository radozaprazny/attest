# attest — a compliance-native kit for Claude Code

Most Claude Code starters give you convenience. `attest` gives you **governance**:
living documents, audit-gate skills, and two hooks that run without being asked — together
they keep an AI-assisted project honest to what you declared: its purpose, its boundaries,
its decisions, and the rules it must operate under — and prove nothing sensitive leaks when
you ship.

Built for work in regulated or high-stakes contexts (EU AI Act, GDPR, …), but useful
to anyone who wants a repo that answers *the questions an auditor asks, not just the
ones a compiler does*.

## The spine

    intent  →  boundaries  →  decisions  →  compliance  →  clean history

Four living documents, plus an opt-in fifth. Only `CLAUDE.md` is loaded **every turn**; the
rest are read on demand — so the system stays cheap no matter how much it holds. (One
exception, by design: the `SessionStart` hook injects a capped extract of `BUSINESS.md`'s
non-goals and `PROGRESS.md`'s state once per session, so the boundaries are known before the
first edit.)

| Document | Answers | Maintained by | Adopt |
|----------|---------|---------------|-------|
| `CLAUDE.md` | the rules / conventions | edited directly | always — the minimum three |
| `PROGRESS.md` | where we are (thread-carrier across `/clear`) | `/checkpoint` | always — the minimum three |
| `BUSINESS.md` | **why** it exists — purpose, archetype, non-goals | `/business` | always — the minimum three |
| `DECISIONS.md` | **why we chose X over Y** (ADR-lite, append-only) | `/decision` | team / long project |
| `COMPLIANCE.md` | **under what rules** it must operate | `/compliance` | regulated scope — **opt-in**, `install.sh --compliance` |

> Anti-duplication: each fact in exactly one place. **Adopt on a gradient** — the minimum
> viable attest is the three documents marked above; un-adopted ones cost nothing (skills
> read them on demand and degrade to a note when one is absent). `COMPLIANCE.md` and
> `/compliance` do not install unless you ask: at install time nobody knows the archetype yet,
> and an empty posture file reads as *"declared"* to every later audit. `/business` makes that
> call once it does know. Canonical prose: GUIDE PART 1.

## The gate

Each of these skills doesn't just help you *write* a document — it **audits reality against
it** (`/audit-history` owns no document — its record is the git history itself; `/checkpoint`
keeps `PROGRESS.md`, but as a live snapshot, not an audit):

- **`/business audit`** — is anything being built violating a stated non-goal or drifting
  past the declared scope (or archetype)? Where `/compliance` was not installed, it also
  inherits the ladder's fallback row for regulated ground.
- **`/decision audit`** — decisions made in code but never recorded?
- **`/compliance audit`** — does the diff touch regulated ground (new PII, a change that
  may bear on the AI-Act classification) against the declared posture? *(optionally
  verified live via a project MCP.)*
- **`/audit-history`** — before the push leaves the machine: secrets, PII, client
  names, metadata leaks. Read-only on your content; it appends one dated run record under
  `.attest/`, which is what the ship guard checks.

They compose into two gates. **`/gate`** is the **commit-time** gate as one command: the
`reviewer` subagent's code-level pass plus every document audit the project installed, run in
parallel subagents and merged into one verdict under a shared severity ladder — one hunk is
flagged once. Its document audits run in a subagent that **cannot** write or run commands
(read-only by capability, not promise), and every run **appends a dated run record** under
`.attest/` — HEAD SHA, kit version, which passes ran, the verdict — so *"the gate ran"* is
a fact in the repo, not a memory. `/audit-history` is the **ship** gate, before anything
leaves the machine — and it is no longer on your memory: a `PreToolUse` hook matches the
commands that publish, submit or upload, checks `.attest/` for a run record naming the
**current** HEAD, and asks if there is none (the whole loop is laid out in
[`GUIDE.md`](GUIDE.md) PART 9).

## Does it hold up?

Dogfooded before shipping: two sandboxes seeded with **known planted faults**, audited by
agents told nothing about them — **6/6 caught at the right severity, 0 false positives**
([the record](docs/attest-devlog.md)). The four results that matter:

- `/business` derived the archetype **`service`, not `ai-system`** — the project had no
  server-side model. The tailoring restrains itself.
- A **planted false non-goal was caught**; the true ones cleared.
- `/decision audit` found **four real unrecorded decisions** — and correctly did *not*
  re-flag the one already recorded.
- `/audit-history full` caught a **secret alive only in history** — planted in an old
  commit, deleted at HEAD. Which is the whole reason `full` exists.

## Not a kitchen sink

**What it does not ship, on purpose:** no formatter and no language config — nothing in this
kit edits your code. No warning you cannot act on at the moment it fires, which rules out the
compaction and session-length nags. No inert `.example` files. Two hooks survive that bar, and
both *prevent* rather than remind: your non-goals go into context at every session start, and
the ship guard asks before an unaudited push. **Nothing the kit installs needs an interpreter beyond
`/bin/sh`** — both hooks are POSIX shell (`install.sh` itself is bash, but it runs once and
installs nothing that depends on it).

Every skill here (a) fits the spine and (b) does something a generic plugin can't —
it's *integrated* (the docs cross-link), *gated* (audits that return a verdict and leave
a dated record — the mechanism attests, the discipline of honoring the verdict stays
yours), and *EU-first*. A generic `/deploy` or `/test` fails both tests; the
ecosystem does those better. Breadth isn't the point — a coherent, opinionated
system is.

## Quick start

**A new project** — use the green **"Use this template"** button, or clone:

    git clone https://github.com/radozaprazny/attest.git my-project
    cd my-project && rm -rf .git && git init

**An existing project** — install into it without touching what is already there:

    git clone https://github.com/radozaprazny/attest.git /tmp/attest
    /tmp/attest/install.sh ~/my-project

`install.sh` is **copy-if-absent**: your `CLAUDE.md`, your settings and your `.gitignore` are
never clobbered. It reports by **capability** rather than by path — one line per group, plus a
*YOURS, UNTOUCHED* block for what it left alone and a *NEEDS YOU* block for the rare thing you
actually have to merge. A re-run that changed nothing says so in one line. Add `--compliance`
if you are in regulated scope (or let `/business` tell you).

## First 5 minutes

The template hands you attest's own files next to your empty ones. **A generated repo cleans
itself:** the `template-cleanup` workflow runs on your first push (or via *Actions → run
workflow*), removes attest's identity files **by name** (its `docs/attest-*.md`, its smoke
test, `install.sh`, its own `ci.yml`) and rewrites this README and its `LICENSE` down to
stubs for you to fill, then deletes itself —
verify it ran. It is safe to run late: it never removes a directory wholesale, so your own
`docs/` and `scripts/` survive, and every file it rewrites or removes under a name you might
also use — `README`, `LICENSE`, `ci.yml`, `scripts/smoke.sh` — is checked for attest's own
content first. The cleanup pushes an **ordinary commit**, never a history rewrite, so anything
it removes is one `git revert` away. With Actions disabled, do steps 1–2 by hand *(they are the template/clone
path only — `install.sh` never copies these files)*:

1. **Replace `README.md`** — this one is attest's front page, not your project's.
2. **Replace `LICENSE`** — as shipped it grants your code away under **someone else's name**.
   Then delete **`docs/attest-*.md`**, **`scripts/`**, **`install.sh`**,
   **`.github/workflows/template-cleanup.yml`** and **`.github/workflows/ci.yml`** —
   attest's own history, tests, installer, cleanup and CI.
3. **Fill `CLAUDE.md`** — it is loaded **every turn** and ships as `<Your Project>` with
   placeholder conventions. No skill owns it; `/init` is the quickest way.
4. **Restart Claude Code** — `.claude/` is a new top-level directory, so the skills only load
   on a fresh session. Until you do, `/business` does not exist.
5. **Declare:** `/business` (intent + archetype) · `/decision` as you choose. `/business`
   ends by telling you whether this project is in regulated scope. **On this path the
   template already gave you `COMPLIANCE.md` and `/compliance`** — so *in scope* means fill
   them, and *out of scope* means delete both and record the one-sentence reason. (The
   `install.sh --compliance` flag is the other adoption path's answer to the same question;
   step 2 told you to delete the installer.) Then **gate:** `/gate` before each commit ·
   `/audit-history` before you push, `full` before a public release — the ship guard will ask
   for it if you forget.

For a full, point-by-point guide to every piece, see [`GUIDE.md`](GUIDE.md) — PART 9 is the
whole loop end to end.

## License

MIT.
