# attest — a compliance-native kit for Claude Code

Most Claude Code starters give you convenience. `attest` gives you **governance**:
a small system of living documents and audit-gate skills that keep an AI-assisted
project honest to what you declared — its purpose, its boundaries, its decisions,
and the rules it must operate under — and prove nothing sensitive leaks when you ship.

Built for work in regulated or high-stakes contexts (EU AI Act, GDPR, …), but useful
to anyone who wants a repo that answers *the questions an auditor asks, not just the
ones a compiler does*.

## The spine

    intent  →  boundaries  →  decisions  →  compliance  →  clean history

Five living documents. Only `CLAUDE.md` is ever held in context; the rest are read
on demand — so the system stays cheap no matter how much it holds.

| Document | Answers | Maintained by | Adopt |
|----------|---------|---------------|-------|
| `CLAUDE.md` | the rules / conventions | edited directly | always — the minimum three |
| `PROGRESS.md` | where we are (thread-carrier across `/clear`) | `/checkpoint` | always — the minimum three |
| `BUSINESS.md` | **why** it exists — purpose, archetype, non-goals | `/business` | always — the minimum three |
| `DECISIONS.md` | **why we chose X over Y** (ADR-lite, append-only) | `/decision` | team / long project |
| `COMPLIANCE.md` | **under what rules** it must operate | `/compliance` | regulated scope |

> Anti-duplication: each fact in exactly one place. **Adopt on a gradient** — the minimum
> viable attest is the three documents marked above; un-adopted ones cost nothing (skills
> read them on demand and degrade to a note when one is absent). Canonical prose: GUIDE
> PART 1.

## The gate

Each of these skills doesn't just help you *write* a document — it **audits reality against
it** (`/audit-history` owns no document — its record is the git history itself; `/checkpoint`
keeps `PROGRESS.md`, but as a live snapshot, not an audit):

- **`/business audit`** — is anything being built violating a stated non-goal or drifting
  past the declared scope (or archetype)?
- **`/decision audit`** — decisions made in code but never recorded?
- **`/compliance audit`** — does the diff touch regulated ground (new PII, a change that
  may bear on the AI-Act classification) against the declared posture? *(optionally
  verified live via a project MCP.)*
- **`/audit-history`** — before the push leaves the machine: secrets, PII, client
  names, metadata leaks.

They compose into two gates. **`/gate`** is the **commit-time** gate as one command: the
`reviewer` subagent's code-level pass plus the first three audits, run in parallel
subagents and merged into one verdict under a shared severity ladder — one hunk is flagged
once. `/audit-history` is the **ship** gate, before anything leaves the machine (the whole
loop is laid out in [`GUIDE.md`](GUIDE.md) PART 9).

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

Every skill here (a) fits the spine and (b) does something a generic plugin can't —
it's *integrated* (the docs cross-link), *gated* (audits that block, not just
document), and *EU-first*. A generic `/deploy` or `/test` fails both tests; the
ecosystem does those better. Breadth isn't the point — a coherent, opinionated
system is.

## Quick start

**A new project** — use the green **"Use this template"** button, or clone:

    git clone https://github.com/radozaprazny/attest.git my-project
    cd my-project && rm -rf .git && git init

**An existing project** — install into it without touching what is already there:

    git clone https://github.com/radozaprazny/attest.git /tmp/attest
    /tmp/attest/install.sh ~/my-project

`install.sh` is **copy-if-absent**: your `CLAUDE.md`, your settings, your ruff config and your
`.gitignore` are never clobbered — it prints exactly what it skipped so you can merge by hand.

## First 5 minutes

The template hands you attest's own files next to your empty ones. **A generated repo cleans
itself:** the `template-cleanup` workflow runs on your first push (or via *Actions → run
workflow*), deletes attest's identity files (`docs/`, `scripts/`, `install.sh`, this README),
leaves an MIT skeleton `LICENSE`, then deletes itself — verify it ran. With Actions disabled,
do steps 1–2 by hand *(they are the template/clone path only — `install.sh` never copies
these files)*:

1. **Replace `README.md`** — this one is attest's front page, not your project's.
2. **Replace `LICENSE`** — as shipped it grants your code away under **someone else's name**.
   Then delete **`docs/`**, **`scripts/`** and **`install.sh`** — they are attest's own
   history, tests and installer, not yours.
3. **Fill `CLAUDE.md`** — it is loaded **every turn** and ships as `<Your Project>` with
   placeholder conventions. No skill owns it; `/init` is the quickest way.
4. **Restart Claude Code** — `.claude/` is a new top-level directory, so the skills only load
   on a fresh session. Until you do, `/business` does not exist.
5. **Declare:** `/business` (intent + archetype) · `/decision` as you choose · `/compliance`
   if you're in scope. Then **gate:** `/gate` before each commit · `/audit-history` before
   you push, `full` before a public release.

For a full, point-by-point guide to every piece, see [`GUIDE.md`](GUIDE.md) — PART 9 is the
whole loop end to end.

## License

MIT.
