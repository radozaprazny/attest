# attest — a compliance-native kit for Claude Code

Most Claude Code starters give you convenience. `attest` gives you **governance**:
living documents, audit-gate skills, and three hooks that run without being asked — together
they keep an AI-assisted project honest to what you declared: its purpose, its boundaries,
its decisions, and the rules it must operate under — and turn the leak scan from something you
have to remember into a gate that stops you at the moment you would have forgotten it.

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
`reviewer` subagent's code-level pass plus the document audits **the diff actually needs** — a
POSIX shell stage reads the diff and decides, before any subagent exists — run in
parallel subagents and merged into one verdict under a shared severity ladder — one hunk is
flagged once. **`/gate full`** runs every pass over the whole branch, once, before a push:
the light gate triggers on keyword sets, and a keyword set finds what a word can find and
nothing else. Its document audits run in a subagent that **cannot** write or run commands
(read-only by capability, not promise), and every run **appends a dated run record** under
`.attest/` — HEAD SHA, kit version, which passes ran, the verdict — so *"the gate ran"* is
a fact in the repo, not a memory. `/audit-history` is the **ship** gate, before anything
leaves the machine — and it is no longer on your memory: a `PreToolUse` hook matches **a short,
literal list** of commands that publish, submit or upload, finds the `.attest/` run record for
the **current** HEAD and reads it, and asks unless that record attests a clean scan. The list is
substrings, not a category — the common registries' publish commands are on it (`npm`, `pnpm`,
`yarn`, `bun`, `uv`, `poetry`, `twine`, `cargo`, `gem`), every other registry's is not, and
`npm run release`, `make deploy` and your own deploy script do not match either; widening it
means adding them. What the list no longer reads, for `git`, is **spelling** (`pnpm -r publish`
is still silent, attest ADR-0072): the command is normalised first, so `git -C … push`,
`git -c k=v push`, `git --no-pager push` and `git --work-tree … push` all reach the same entry,
and the `--dry-run` exemption now needs a simple, unquoted command to apply at all (attest
ADR-0069). It also covers the publish path that
never opens a shell — a GitHub MCP server's `push_files`, `create_or_update_file`,
`create_pull_request`, `create_repository` — where it always asks, because those calls send
bytes chosen in the call and a record about your HEAD is evidence about a different thing (the
whole loop is laid out in [`GUIDE.md`](GUIDE.md) PART 9). And if you have
[`betterleaks`](https://github.com/betterleaks/betterleaks) installed, a `git push` is also
scanned by it over the commits not yet on any remote: a leak asks even when the record is clean,
and nothing about the guard changes when the tool is absent (attest ADR-0070).

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

**And the ship guard sees what it is pointed at, nothing more.** It is a list, so a deploy
script of your own, an exfiltrating `curl`, or a publish tool you never wired past it leave no
prompt behind — the trace under `.attest/tmp/` shows what it decided, and an empty one means
only that nothing it knows about ran. The scan itself is a model reading a diff and a history,
not a proof — which is why the kit uses a maintained rule-pack for the one class a rule-pack
reads better, keys and tokens, **when you have installed one**: `betterleaks`, the successor to
gitleaks by its original author. It is optional, so the kit does not install it and cannot
promise it ran; the ship record says whether it did, and so does the guard's trace. What the kit does give you is that the
check is no longer yours to remember, and that when it passes it leaves a dated attestation —
which is a different and smaller claim than *nothing sensitive can leave*.

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
ship guard asks before a push the record does not clear — for the commands on its literal list,
and for a publish made through an MCP server rather than a shell (PART 2.2) — and the record
guard asks before a ship record is written at all (PART 2.3).
**Nothing the kit installs needs an interpreter beyond
`/bin/sh`** — every hook is POSIX shell (`install.sh` itself is bash, but it runs once and
installs nothing that depends on it). The one outside program a hook will call, `betterleaks`,
is used only if you put it on your PATH yourself.

Every skill here (a) fits the spine and (b) does something a generic plugin can't —
it's *integrated* (the docs cross-link), *gated* (audits that return a verdict and leave
a dated record — the mechanism attests, the discipline of honoring the verdict stays
yours), and *EU-first*. A generic `/deploy` or `/test` fails both tests; the
ecosystem does those better. Breadth isn't the point — a coherent, opinionated
system is.

## Quick start

Install into your project, new or existing, without touching what is already there:

    git clone https://github.com/radozaprazny/attest.git /tmp/attest
    /tmp/attest/install.sh ~/my-project

`install.sh` is **copy-if-absent**: your `CLAUDE.md`, your settings, your `.gitignore` and your
`.gitattributes` are never clobbered — the last two are appended to, and only ever with lines scoped to the kit's own paths (`.claude/hooks/*`, `.attest/*.md`), never to your source. It reports by **capability** rather than by path — one line per group, plus a
*YOURS, UNTOUCHED* block for what it left alone and a *NEEDS YOU* block for the rare thing you
actually have to merge. A re-run that changed nothing says so in one line. Add `--compliance`
if you are in regulated scope (or let `/business` tell you).

## First 5 minutes

1. **Fill `CLAUDE.md`** — it is loaded **every turn** and ships as `<Your Project>` with
   placeholder conventions. No skill owns it; `/init` is the quickest way.
2. **Restart Claude Code** — `.claude/` is a new top-level directory, so the skills only load
   on a fresh session. Until you do, `/business` does not exist.
3. **Declare:** `/business` (intent + archetype) · `/decision` as you choose — one entry when a
   choice lands, so an empty `DECISIONS.md` on day one is the correct state. `/business`
   ends by telling you whether this project is in regulated scope. You have neither
   `COMPLIANCE.md` nor `/compliance`, on purpose. *In scope* means re-run the installer with
   `--compliance`; *out of scope* means you are already done, but **record the one-sentence
   reason** anyway — an absent file declares nothing, and a later audit needs to know the
   question was asked.

   Then **gate:** `/gate` before each commit · `/audit-history` before you push, `full` before
   a public release — the ship guard will ask for it if you forget.

For a full, point-by-point guide to every piece, see [`GUIDE.md`](GUIDE.md) — PART 9 is the
whole loop end to end.

## License

MIT.
