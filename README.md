# attest — a compliance-native kit for Claude Code

Most Claude Code starters give you convenience. `attest` gives you **governance**:
living documents, audit-gate skills, and three hooks that run without being asked — together
they keep an AI-assisted project honest to what you declared: its purpose, its boundaries,
its decisions, and the rules it must operate under — and prove nothing sensitive leaks when
you ship.

Built for work in regulated or high-stakes contexts (EU AI Act, GDPR, …), but useful
to anyone who wants a repo that answers *the questions an auditor asks, not just the
ones a compiler does*.

## In 60 seconds

```sh
./install.sh /path/to/your/project     # copy-if-absent; it never overwrites anything of yours
```

Then, in that project: **restart Claude Code** (the skills only load on a fresh session) ·
`/business` to declare what it is for and what it must never do · `/gate` before each commit ·
`/audit-history` before each push. That is the whole loop. Everything below is *why* each piece
is shaped the way it is — read it when you want the reasoning, not to get started.

> **Want the idea without the tool?** [`METHOD.md`](METHOD.md) states the method on its own —
> the spine, the ten properties that make it work, and the four primitives an implementation
> needs from its host. No code, no Claude, MIT.

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
leaves the machine — and it is no longer on your memory: a `PreToolUse` hook matches **a short,
literal list** of commands that publish, submit or upload, finds the `.attest/` run record for
the **current** HEAD and reads it, and asks unless that record attests a clean scan. The list is
substrings, not a category — `git -C … push`, `npm run release` and your own deploy script do not
match, and widening it means adding them (the whole loop is laid out in
[`GUIDE.md`](GUIDE.md) PART 9).

> **"My harness already refuses the obvious — why a guard?"** Because this one is yours and it
> answers a different question. It runs whatever permission mode you are in and does not depend
> on a model's judgement at the moment it matters; it names the classes a generic filter has no
> reason to know — GDPR Art 9 categories, national identifiers, client confidentiality, the
> difference between a maintainer's own address and a third party's; it is scoped by **your**
> declared non-goals rather than by a general notion of harm; and when it passes, it leaves a
> dated attestation you can show someone, which no refusal ever does.

## What it does not defend against

**Forgetting, not forgery.** The gates are built for the failure that actually happens: the
audit you meant to run and didn't, the boundary you declared and drifted past, the key you
committed at 1am. They are not an adversary model. A ship record is an ordinary untracked file
— nothing signs it, and any tool that can write a file can write one; the record guard (PART
2.3) makes that write a **prompt at the moment you still know whether the audit ran**, which is
earlier and better informed than the same click at push time, but it is not a wall. Likewise the
document audits are a model reading a diff: they are stable on the primary finding and vary at
the margins, so they advise a merge, never block one (`METHOD.md` property 10). Where the kit
does have a real boundary it says so and means it — the document auditors run without Bash,
Edit or Write, so they *cannot* change the repository rather than being asked not to.

## Does it hold up?

Dogfooded before shipping: two sandboxes seeded with **known planted faults**, audited by
agents told nothing about them — **6/6 caught at the right severity, 0 false positives**
([the record](docs/attest-devlog.md)). Read that as what it is: a clean sweep of **six** faults
across **two** sandboxes, every one of them counted, not a benchmark — the sample is small
enough to name. The four results that matter:

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
compaction and session-length nags. No inert `.example` files. Three hooks survive that bar, and
each *prevents* rather than reminds: your non-goals go into context at every session start, the
ship guard asks before a push the record does not clear — for the commands on its literal list
(PART 2.2) — and the record guard asks before a ship record is written at all (PART 2.3). **Nothing the kit installs needs an interpreter beyond
`/bin/sh`** — every hook is POSIX shell (`install.sh` itself is bash, but it runs once and
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

`install.sh` is **copy-if-absent**: your `CLAUDE.md`, your settings, your `.gitignore` and your
`.gitattributes` are never clobbered — the last two are appended to, and only ever with lines scoped to the kit's own paths (`.claude/hooks/*`, `.attest/*.md`), never to your source. It reports by **capability** rather than by path — one line per group, plus a
*YOURS, UNTOUCHED* block for what it left alone and a *NEEDS YOU* block for the rare thing you
actually have to merge. A re-run that changed nothing says so in one line. Add `--compliance`
if you are in regulated scope (or let `/business` tell you).

On this path there is nothing to clean up — the installer copies no `README`, no `LICENSE` and
nothing of attest's own. Go straight to **[First 5 minutes → Everyone](#everyone)**, steps 1–3.

## First 5 minutes

**Which steps are yours depends on how you adopted the kit.** Steps **A–B** exist only on the
template/clone path, and there the cleanup workflow normally does them for you. Steps **1–3**
are for everyone. If you came through `install.sh`, skip to *Everyone*.

### Template or clone only — and usually automatic

**A generated repo cleans itself:** the `template-cleanup` workflow runs on your first push (or
via *Actions → run workflow*), removes attest's identity files **by name** (its
`docs/attest-*.md`, its smoke test, `install.sh`, its own `ci.yml`) and rewrites this README and
its `LICENSE` down to stubs for you to fill, then deletes itself — **verify it ran.** It is safe
to run late: it never removes a directory wholesale, so your own `docs/` and `scripts/` survive,
and every file it rewrites or removes under a name you might also use — `README`, `LICENSE`,
`ci.yml`, `scripts/smoke.sh` — is checked for attest's own content first. It also sweeps attest's
own audit records out of `.attest/`: those name attest's commits, which do not exist in your repo,
and that resolution is the test — so a record **you** wrote is kept, and where git cannot answer
about the whole history (no repo yet, no commits yet, or a **shallow** checkout) nothing is
touched at all. And it drops the blanket `*.sh` pin from `.gitattributes`, surgically: that one
line goes, every other line stays, including any you added. The cleanup pushes an **ordinary commit**, never a history rewrite, so
anything it removes is one `git revert` away.

**If it ran, A and B are already done — skip them.** Do them by hand only when Actions are
disabled, or when you checked and the run never happened.

- **A. Replace `README.md`** — this one is attest's front page, not your project's.
- **B. Replace `LICENSE`** — as shipped it grants your code away under **someone else's name**.
  Then delete **`docs/attest-*.md`**, **`scripts/`**, **`install.sh`**,
  **`.github/workflows/template-cleanup.yml`** and **`.github/workflows/ci.yml`** —
  attest's own history, tests, installer, cleanup and CI.
- **C. Drop one line from `.gitattributes`** — the blanket `*.sh text eol=lf`. attest needs it
  for its **own** shell; in your repo it would normalise every `.sh` you ever write, under a
  rule you did not choose. Keep `.claude/hooks/*` and `.attest/*.md` — those are the kit's own
  paths, and the first is what keeps the guard runnable on Windows (attest ADR-0043). **Do this
  even if you skip A and B:** deleting `scripts/` deletes the cleanup that would have done it
  for you.

### Everyone

1. **Fill `CLAUDE.md`** — it is loaded **every turn** and ships as `<Your Project>` with
   placeholder conventions. No skill owns it; `/init` is the quickest way.
2. **Restart Claude Code** — `.claude/` is a new top-level directory, so the skills only load
   on a fresh session. Until you do, `/business` does not exist.
3. **Declare:** `/business` (intent + archetype) · `/decision` as you choose. `/business`
   ends by telling you whether this project is in regulated scope — and what you do with that
   answer depends on how you got here, because the two paths start from opposite defaults:
   - **template or clone** — you already have `COMPLIANCE.md` and `/compliance`. *In scope*
     means fill them; *out of scope* means **delete both** and record the one-sentence reason.
     (You cannot re-run the installer: step **B** told you to delete it.)
   - **`install.sh`** — you have neither, on purpose. *In scope* means re-run the installer
     with `--compliance`; *out of scope* means you are already done, but **record the
     one-sentence reason** anyway — an absent file declares nothing, and a later audit needs
     to know the question was asked.

   Then **gate:** `/gate` before each commit · `/audit-history` before you push, `full` before
   a public release — the ship guard will ask for it if you forget.

For a full, point-by-point guide to every piece, see [`GUIDE.md`](GUIDE.md) — PART 9 is the
whole loop end to end.

## License

MIT.
