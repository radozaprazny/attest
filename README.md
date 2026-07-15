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

| Document | Answers | Maintained by |
|----------|---------|---------------|
| `CLAUDE.md` | the rules / conventions | edited directly |
| `PROGRESS.md` | where we are (thread-carrier across `/clear`) | `/checkpoint` |
| `BUSINESS.md` | **why** it exists — purpose, archetype, non-goals | `/init-tier` |
| `DECISIONS.md` | **why we chose X over Y** (ADR-lite, append-only) | `/decision` |
| `COMPLIANCE.md` | **under what rules** it must operate | `/compliance` |

> Anti-duplication: each fact in exactly one place.

## The gate

Each of these skills doesn't just help you *write* a document — it **audits reality against
it** (`/audit-history` owns no document — its record is the git history itself; `/checkpoint`
keeps `PROGRESS.md`, but as a live snapshot, not an audit):

- **`/init-tier audit`** — is anything being built violating a stated non-goal or drifting
  past the declared scope (or archetype)?
- **`/decision audit`** — decisions made in code but never recorded?
- **`/compliance audit`** — does the diff touch regulated ground (new PII, a change that
  may bear on the AI-Act classification) against the declared posture? *(optionally
  verified live via a project MCP.)*
- **`/audit-history`** — before the push leaves the machine: secrets, PII, client
  names, metadata leaks.

Run together, their audit modes are a **pre-ship gate** — intent, decisions,
regulation, and leakage checked in one pass. The `reviewer` subagent runs the
code-level pass; it and the doc-audits form the commit-time gate as separate
steps (the whole loop is laid out in [`GUIDE.md`](GUIDE.md) PART 9).

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

The template hands you attest's own files next to your empty ones. Straighten that out before
you commit anything *(steps 1–2 are the template/clone path only — `install.sh` never copies
those two files)*:

1. **Replace `README.md`** — this one is attest's front page, not your project's.
2. **Replace `LICENSE`** — as shipped it grants your code away under **someone else's name**.
   Then delete **`docs/`** and **`install.sh`** — they are attest's own history and installer,
   not yours. (`install.sh` never copies these three; the template button copies everything.)
3. **Fill `CLAUDE.md`** — it is loaded **every turn** and ships as `<Your Project>` with
   placeholder conventions. No skill owns it; `/init` is the quickest way.
4. **Restart Claude Code** — `.claude/` is a new top-level directory, so the skills only load
   on a fresh session. Until you do, `/init-tier` does not exist.
5. **Declare:** `/init-tier` (intent + archetype) · `/decision` as you choose · `/compliance`
   if you're in scope · `/audit-history` before you push, `full` before a public release.

For a full, point-by-point guide to every piece, see [`GUIDE.md`](GUIDE.md) — PART 9 is the
whole loop end to end.

## License

MIT.
