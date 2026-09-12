# GUIDE.md — reference guide

What this dev-kit contains, **how to run it** and **what it is for**. The kit is reusable —
install it into any project with `install.sh` (PART 8; never by hand-copying).

> Sections are numbered **per PART** (1.1, 1.2, … then 3.1, 3.2, …) so a new skill can be
> slotted in without renumbering the rest. PARTs are referenced by name ("see PART 6").

---

## PART 1 — Control documents

The kit runs on **four living documents, plus one opt-in fifth**. Only `CLAUDE.md` is held in
context **every turn**; the others are read **on demand** by their skills, so the system stays
cheap no matter how much it holds. One deliberate exception: the `SessionStart` hook injects a
capped extract of `BUSINESS.md`'s non-goals and `PROGRESS.md`'s state once per session (PART
2.1) — bounded, and only from those two sections. (This PART and the README table are the *only* two full enumerations —
everywhere else carries the one-line router below.)

**Adopt on a gradient.** The minimum viable attest is **three documents** — `CLAUDE.md` +
`PROGRESS.md` + `BUSINESS.md`: rules, thread, boundary. `DECISIONS.md` earns its keep at
team scale or on a long project, when *"why did we do it this way?"* outlives anyone's
memory; `COMPLIANCE.md` only in regulated scope — and that one is **opt-in at install time**:
`install.sh` does not land it or its skill unless you pass `--compliance`, because an empty
posture file reads as *"declared"* to every later audit while declaring nothing (attest
ADR-0030). `/business` makes that call for you once it knows the archetype. Documents you have
not adopted cost nothing — the skills read them on demand, and an audit degrades to a note
("nothing declared") when one is absent.

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
- **Opt-in.** Neither this document nor `/compliance` installs by default. Re-run the
  installer with `--compliance` when `/business` tells you the archetype triggers it. If you
  are **out** of scope, record that in one sentence (a `BUSINESS.md` non-goal is the usual
  home) — a recorded *"out of scope, because …"* is a declaration; an absent file is not.
  With the skill absent its ground is **re-assigned**, never dropped — the shared ladder's
  table names the owner for each kind of hunk (attest ADR-0030).

> **Anti-duplication rule:** status → PROGRESS · rules → CLAUDE · why-it-exists → BUSINESS ·
> why-we-chose-X → DECISIONS · under-what-rules → COMPLIANCE. **Each fact in exactly one
> place.** The three "why" docs are the collision point: BUSINESS = *why the project exists* ·
> DECISIONS = *why this choice beat the alternative* · COMPLIANCE = *which external rule
> forces it*.

---

## PART 2 — Hooks (`.claude/settings.json` + `.claude/hooks/`)

**Three hooks, and the bar they had to clear.** A hook is a shell command the *harness* runs on
an event — not something Claude decides to do — so it cannot be forgotten. That is its whole
advantage over a skill, and the kit spends it on exactly two jobs: putting the project's
boundaries in front of the agent **before** it writes, and asking about data at the moment it
would leave the machine. Anything that merely *reminds* you of something you can already see
is not worth an event (attest ADR-0028).

Both are POSIX `sh`. The kit needs no interpreter beyond `/bin/sh` and **installs nothing that
edits your code** — there is no formatter here, by design (attest ADR-0027).

### 2.1 `SessionStart` — the declaration hook (`session_declaration.sh`)
- **How:** at the start of every session it reads the **Non-goals** section of `BUSINESS.md`
  and the **Current state** / **Next** sections of `PROGRESS.md`, and prints them. SessionStart
  stdout is added to the session's context.
- **What for:** a violated non-goal is *always a blocker* on the shared ladder — but `/gate`
  can only find one after the code exists. This hook is the **prevention** half of that rule:
  the boundaries are in context before the first edit, not after it.
- **It stays quiet unless you have declared something.** A section still holding the shipped
  `<placeholder>` text counts as undeclared and prints nothing, so a fresh install adds no
  noise. Output is capped **per section** — 24 lines of non-goals, 8 of current state, 8 of
  next — so no section can crowd out another, and a trimmed one says how much it dropped.
  With framing and truncation notices the worst case is ~52 lines; this text is prepended to
  *every* session, so it has to stay cheap.
- **If your live documents are not at those names,** set `ATTEST_BUSINESS` and
  `ATTEST_THREAD_CARRIER` — in the `env` block of `.claude/settings.json`, or in your
  environment. Paths are relative to the project root. This is the case for any repo that
  ships the kit's documents as *templates* and keeps its real ones elsewhere (attest's own
  live in `docs/attest-*.md` — the same distinction `/gate` scopes with `$DOCS`).
- **If your sections are not called that either,** set `ATTEST_NONGOALS_HEADING`,
  `ATTEST_STATE_HEADING` and `ATTEST_NEXT_HEADING` the same way. The defaults are the kit's
  English headings, and a project writing its documents in another language gets **silence**
  without this — the hook reads the file, matches nothing and prints nothing, which from
  inside a session is indistinguishable from a hook that was never registered (attest
  ADR-0047). Each value is a **POSIX ERE** matched against the whole `## …` line. A heading
  with no regex metacharacters needs no ceremony — `ATTEST_STATE_HEADING='Stav'` finds
  `## Stav k 7. 9.` — and one that has them takes a **single** backslash:
  `ATTEST_STATE_HEADING='Stav \(WIP\)'`. Leaving a variable set but **empty** is not "no
  override": an empty pattern matches every heading, so the kit treats empty as unset and falls
  back to the default. The section itself must still be a **level-2** heading — its body runs
  until the next `## `, so `### Ďalší krok` is read as a subsection of whatever precedes it and
  has to be promoted to `## `.

### 2.2 `PreToolUse` on `Bash` and the publish MCP tools — the ship guard (`ship_guard.sh`)
- **How:** before Claude runs a Bash command, the hook matches it against a short list of
  commands that **publish, submit or upload** — `git push`, `gh pr create`, `gh release
  create`, `npm publish`, `twine upload`, `cargo publish`, `docker push`, a Kaggle submit,
  `scp`/`rsync`, `aws s3 cp`, `curl --upload-file` — plus the one that changes **who may read**
  what you already sent: `gh repo edit --visibility` and `gh repo create`. On a hit it looks
  under `.attest/` for an `/audit-history` run record naming the **current** HEAD sha **and
  reads it** (see *"What the record has to prove"* below). Anything short of a clean record for
  this HEAD answers with `permissionDecision: "ask"`, and the reason says which of the two it
  was — no record, or a record that does not attest a clean scan.
- **The list is literal, and that is the coverage.** It is a `case` of fixed substrings, not a
  category of command. `git -C … push`, `git --no-pager push`, `npm run release`, `make deploy`
  and a deploy script of your own do **not** match, and a non-matching command leaves no trace
  line either — so an empty log is not proof the hook is alive, only that nothing it knows about
  ran. This is a net for *forgetting*, not for variants; widen it by adding your own project's
  commands to that `case`.
- **The publish path that never opens a shell** (attest ADR-0058). A GitHub MCP server pushes
  files, opens pull requests and creates repositories over the API — `git push` is never typed,
  so the `Bash` matcher never fires and, until this arm, the gate was simply absent there. The
  kit registers the same hook a second time for `mcp__github__push_files`,
  `create_or_update_file`, `create_pull_request` and `create_repository`.
  - **For this arm the list lives in `.claude/settings.json`, not in the hook** — and that is
    the honest place for it. For Bash the matcher is the word `Bash`, so the list of ship
    commands has to be inside the script; an MCP tool only ever reaches a hook the matcher
    **names**, so the matcher *is* the list. Wiring a tool to this hook is the statement that it
    publishes: anything `mcp__*` that gets there asks. Wire the publish tools, not the server.
  - **It asks every time and never consults a record.** Every other arm passes on a clean record
    for HEAD. This one cannot: a record attests the **tree at a commit**, and these calls send
    bytes chosen **in the call**, which need not be committed and need not match HEAD. Passing
    on evidence about something else is the believed-but-false gate ADR-0035 refuses; the prompt
    says so, and points you at `git push` if you want the record to cover the thing you send.
  - **The trace names the tool and nothing else.** For Bash the subject is the command; here the
    payload *is* the file content, so quoting it would write the very secret being shipped into
    a prompt and into a log on disk.
  - **Upgrading from a pre-0.9 stanza:** `install.sh` now requires the MCP matcher as well as
    the three hook filenames before it calls your `settings.json` wired — a file that names
    `ship_guard.sh` under `Bash` alone is reported, with the kit's stanza to merge in.
- **The visibility flip is the one with the largest blast radius.** A push exposes the tree you
  just wrote; making a repository public exposes **every commit and every old blob**, including
  the ones you have not re-read in a year — and it is the one action you cannot take back by
  reverting. It is also the only entry where the recommended mode is `/audit-history full`
  rather than the default, which is why the prompt says so (attest ADR-0035). Turning a repo
  *private* asks too: narrowing the pattern to the value would need one more spelling per flag
  form, and this hook's standing rule is that an extra prompt beats a miss.
- **What for:** `/audit-history` is the kit's ship gate, and until now it was purely advisory —
  you had to remember it at exactly the moment you had stopped thinking. This makes the
  boundary real without making it absolute.
- **It asks, it never forbids.** The answer is an ordinary permission prompt you can approve.
  A guard that cannot be overridden gets deleted; one that states what is missing gets used.
- **What the record has to prove.** The guard matches the sha in the record's *name*, then
  reads two lines inside it: `- HEAD: <sha> …` and `- findings: 0 blocker …`. So the question is
  *"was this state audited **and** did it come back clean"* — not *"was this repo ever audited"*,
  and not *"does a file exist"*. A record reporting a blocker does not open the door; neither
  does an empty one (attest ADR-0037). That is why `/audit-history` writes a record even when the
  verdict is clean: a clean ship is the state the guard has to be able to recognise.
- **It leaves a trace.** Every matched command appends one line — UTC timestamp, decision,
  HEAD sha, sanitised command — to `.attest/tmp/ship-guard.log`, the **pass** as well as the ask.
  A hook that decides silently cannot be told apart from one that was never registered, which is
  exactly how a real push once slipped past unexplained; `cat` that file to see whether the guard
  is alive and what it decided (attest ADR-0034). It is ignored by git, never a record, and safe
  to delete at any time.
- **Adding your own ship command:** it is a `case` statement near the top of the script. Put
  your deploy script or submit CLI in it literally — do not make the patterns clever.
- **A dry run publishes nothing** and is allowed through (`--dry-run`) — but only when the
  dry run is the *whole* command. In a compound one the flag may belong to a different call
  than the one that ships (`git push --dry-run && git push origin main`), so anything holding
  `;` `&&` `||` `|` or a newline is judged as a whole and still asks.

### 2.3 `PreToolUse` on `Write|Edit` — the record guard (`record_guard.sh`)
- **How:** before a file is written, the hook looks at `tool_input.file_path`. Anything that is
  not a `.attest/ship-*.md` passes untouched; a ship record makes it **ask**, naming the file.
- **Why:** 2.2's decision is read out of that file, and the file is ordinary and untracked —
  nothing signs it, and `disable-model-invocation: true` stops the model *invoking*
  `/audit-history`, not *writing a file*. The ship guard judges commands and publish tools, so
  the `Write` tool went straight past it. That left the kit's most load-bearing artefact resting on a promise, which
  is the one thing this kit tells you not to accept (attest ADR-0051).
- **What it is worth, exactly:** it does not make a forged record impossible. It makes writing
  one a prompt **at the moment you still know whether an audit ran** — earlier and better
  informed than the same click at push time. A real capability boundary (a writer that cannot
  audit, an auditor that cannot write) needs a primitive no host here provides; see
  `METHOD.md` §"What it costs, and where it is thin".
- **Cost:** one extra prompt per `/audit-history` run, which is the price of the record meaning
  anything. A shell write into a record (`… > .attest/ship-….md`, `tee`, `cp`, `mv`, and the
  in-place editors `sed -i`, `sed --in-place`, `perl -pi`, `truncate`) is
  caught by 2.2's own arm; an editor or `python -c` is not, and is not meant to be.
  - **That arm is judged one command *part* at a time** (attest ADR-0060), unlike every other
    arm in 2.2, which reads the command whole. As a single pattern it saw a redirect belonging
    to one command and a record path belonging to another as a write — `grep … > /tmp/n && ls
    .attest/ship-a.md` merely *reads* the record and still asked. Splitting on `;` `|` `&` first
    costs nothing and keeps every real write, since a redirect and its target are in the same
    part by definition. `>` must also come *before* the path, so `cat .attest/ship-a.md >/tmp/x`
    reads rather than writes.
- **Gate records are not hooked.** A `gate-*.md` attests a commit-time run that no machine
  reads, so a prompt there would be friction without a decision behind it.

### 2.4 What the kit deliberately does **not** hook
- **No formatter.** Anything that rewrites your code after every edit belongs to your own
  toolchain, at your own moment. attest audits; it does not edit (attest ADR-0027).
- **No warning you cannot act on when it fires.** That rules out the compaction nudge
  (compaction is already under way) and the session-length warning (transcript lines are a poor
  proxy, and Claude Code shows context pressure natively) — attest ADR-0028. The one nudge that
  survives is a *line*, not an event: the declaration hook prints
  *"/checkpoint owns this file"* under the `PROGRESS.md` half, where you can act on it.
- **No merge gate.** `gh pr merge` is deliberately *not* in the ship guard's list. By the time
  you merge, every byte is already on the remote — put there by a push the guard did gate — so
  the prompt's own claim would be false; the merge commit does not exist yet, so no record could
  ever name it (attest ADR-0033); and most merges never touch your machine at all — the web
  button, auto-merge, a colleague. Matching only the CLI form would advertise a coverage the
  hook cannot have, and a believed-but-false gate is worse than a declared gap. That boundary
  belongs to **branch protection and required CI**, which are server-side and catch every path
  (attest ADR-0035).
- **Not every MCP tool that touches GitHub is wired** (attest ADR-0058). `merge_pull_request` is
  out for exactly the reason `gh pr merge` is, above. `delete_file` and `create_branch` send no
  content off the machine. `fork_repository` has no Bash counterpart on the list, and adding one
  spelling of a thing while missing the others advertises coverage the hook does not have. The
  comment and review tools (`add_issue_comment`, `pull_request_review_write`, …) do send text
  off the machine, and they are still out: what they send is not the tree, so the one piece of
  evidence this gate reads — a record about a commit — has nothing to say about them, and a
  prompt on every comment would train the click-through that makes the other arms worthless.
  Wire them yourself if your project wants them; the matcher is one line.
- **Nothing is forbidden to you.** A project that wants edit-time formatting can still have it —
  it is one `PostToolUse` entry in `.claude/settings.json` pointing at your own formatter. The
  kit simply does not ship one, and will not install one over your toolchain (attest ADR-0027).

> **What the trace can hold.** The guard's log line carries the matched command with only
> JSON-breaking characters removed — `@ . - _ : = /` and the space all survive, which is what an
> address, a credentialed URL **and a filesystem path** are made of. Seven of the matched
> patterns are local-file transfers whose argument is a path, so
> `aws s3 cp /home/alice/patients-2026.csv s3://…` lands verbatim as readily as
> `git send-email --to alice@example.com` does, and a filename can name a data subject or imply
> a special category. Up to 120 characters, appended to `.attest/tmp/ship-guard.log`. That file is gitignored and never
> shipped — but unlike the permission prompt it is **persistent and unbounded**, so deleting it
> is the retention control, and in a regulated project it is a local store to declare rather than
> to discover (`COMPLIANCE.md` §7).

> **What the hooks send.** All three put text into the model's context: the declaration hook
> prints your non-goals and live state at every session start, and the ship guard puts the
> matched command into the permission prompt. In a **regulated** project that is a data flow
> like any other — if your control documents can contain personal data, name the destination in
> `COMPLIANCE.md` (§7, sub-processors / transfers). Neither hook sends anything anywhere by
> itself; both only print, and what reaches the provider is whatever your session already does.

> **Reading the trace.** Five columns — timestamp · decision · short sha · permission mode ·
> sanitised subject — and six decision words: `pass` (a clean record cleared it) · `blocked`
> (a record for this commit exists and does not attest a clean scan) · `ask` (no record at
> all) · `dryrun` (waved through as a simple dry run) · `record` (something was writing a ship
> record, from either hook) · `mcp` (a publish tool that never opens a shell, which no
> record can clear — ADR-0058; the subject column is the tool name there, never the bytes
> it was sending). The **mode** column is what tells "the hook did not fire" from
> "the hook fired and the mode auto-approved it" (attest ADR-0050); a payload without one
> logs `-`. `blocked` and `ask` are both a permission
> prompt — the difference is what is missing, and afterwards only the log can tell them apart
> (attest ADR-0038). A command the matcher does not recognise writes **no** line, so an empty
> log means "nothing I know about ran", not "the hook is dead".

> **The hook pattern:** *event (when) → your shell command (what)*. Exit `2` = block the
> action; a `PreToolUse` hook can also print JSON with `permissionDecision: "ask"` to prompt
> instead of blocking. Always **fail-open** — an error, an unreadable file or an unparseable
> payload must let the session proceed untouched. Verify a new hook via `/hooks` (and
> approve it).

---

## PART 3 — Skills (`.claude/skills/<name>/SKILL.md`)

Each **gate** skill both **writes** its document and **audits** reality against it —
`/business`, `/decision`, `/compliance` (`/audit-history` audits without owning a document;
`/checkpoint` maintains `PROGRESS.md` as a live snapshot, not an audit; `/gate` owns no
document either — it runs the commit-time audits together, see 3.6). All six are
**manual-only** (`disable-model-invocation: true`): Claude never auto-offers them — you type
the command; costs ~0 tokens when idle. All the audits share
one output shape and one severity ladder so they read as a family:

> **The ladder and the ownership contract live in
> [`.claude/skills/_shared/audit-ladder.md`](.claude/skills/_shared/audit-ladder.md) — that
> file is canonical, this is a summary.** It sits next to the skills because they **read it at
> runtime**: it installs when they install, so an audit's severity is never undefined (attest
> ADR-0010 — the kit's own decision log, not your `DECISIONS.md`).
>
> **Ladder:** **blocker** / **major** / **minor** — three bare words, one vocabulary, no
> per-skill variants (attest ADR-0029): every finding already names its owner, so say what the
> problem *is* in the description instead.
> Always a blocker: a secret, special-category / national-ID personal data, a violated
> non-goal, a prohibited (Art 5) practice. Always minor: metadata, large files, stale wording.
> **Ownership — one hunk is flagged once:** `/decision` owns *a new dependency / swapped
> library / new pattern / notable threshold*; `/business audit` fires only on a non-goal /
> scope violation; `/compliance audit` fires only on regulated ground — **and where it is not
> installed, its ground is re-assigned by the ladder's table** — to `/decision audit` if a
> choice sits behind it, to `/audit-history` if it is bytes, otherwise to `/business audit` —
> and the finding names what it would have been, at the severity the ladder would have given it
> (attest ADR-0030); `/audit-history` owns only what the repo **ships** —
> content in the tree or history. The line between the last two
> and `/business` is **content vs behaviour**: code that *does* something a non-goal forbids
> is `/business`'s; bytes that must not leave are `/audit-history`'s.

### 3.1 `/business` — creates/maintains/audits `BUSINESS.md`
- **How:** type `/business`. It first fixes the project's **archetype** (library / cli /
  service / data-pipeline / ai-system / local-app), which picks a tailored template +
  question set. Three
  modes: **bootstrap** (file absent — or still the shipped `<placeholder>` skeleton), **update**
  (compare against project state), and
  **`/business audit`** (check reality — code, commits, diff — against the declared
  non-goals/scope; read-only, reports a verdict, changes nothing). In a project that did not
  install `/compliance`, the audit also inherits the ladder's fallback row — regulated ground
  with no choice and no bytes behind it, because what is missing there is a *declaration*.
- **What for:** business context — like `/init` for CLAUDE.md, but for BUSINESS.md. The
  archetype is only a **trigger** for `/compliance` (it signals the AI Act *may* apply) — it
  is **not** the legal risk tier, which `/compliance` sets in COMPLIANCE.md.

### 3.2 `/checkpoint` — token/context hygiene
- **How:** type `/checkpoint`. Derives
  state from git, updates PROGRESS, advises `/clear` vs `/compact`.
- **What for:** one word pours the session state into PROGRESS → then you can `/clear` safely.
- **When:** before every `/clear`. Nothing warns you any more — the session-length hook is
  gone (PART 2.4); the declaration hook's *"/checkpoint owns this file"* line is what carries
  the reminder now, at the start of the next session rather than the end of this one.

### 3.3 `/decision` — records/audits `DECISIONS.md`
- **How:** type `/decision` to **record** a decision just made (append-only ADR-lite entry);
  `/decision audit` finds decisions **made in code but never written down** (a new dependency,
  a swapped library, a new pattern) — read-only.
- **What for:** the queryable log of *why X over Y*, alternatives included. It owns the
  "undocumented decision" finding so the other audits don't double-flag the same hunk.

### 3.4 `/audit-history` — the clean-history leak gate (no doc)
- **How:** `/audit-history` scans the working tree + the diff about to be pushed;
  `/audit-history full` scans the **entire history** (all commits/branches). **Read-only on
  your content.**
- **What for:** the ship gate — before code leaves the machine, catch secrets, personal
  data (EU-first GDPR), client names and metadata leaks. It maintains **no document** (its
  record is the git history itself) and never rewrites history — it reports and recommends.
- **Its one write:** a dated run record, `.attest/ship-<date>-<time>-<short HEAD sha>.md`,
  appended **even when the verdict is clean** — that is what the `PreToolUse` ship guard
  reads before a push or a submit (PART 2.2). Nothing else on disk is touched. Like `/gate`'s,
  it names findings at **attestation altitude** — severity, class, path; never the value and
  never the line, because the record publishes with the repo (attest ADR-0049).

### 3.5 `/compliance` — creates/maintains/audits `COMPLIANCE.md`
- **How:** `/compliance` bootstraps/updates the posture; `/compliance audit` checks whether a
  diff touches **regulated ground** (a new personal-data field, a new model, a new data source)
  against it — read-only. EU-first (AI Act + GDPR as two independent axes). Reads the
  `BUSINESS.md` archetype only as a **trigger**.
- **What for:** the "under what rules" record — self-assessed classification + obligations,
  citing provisions by ID, **never a legal verdict**. Optionally verified live via an
  EU-AI-Act MCP (see PART 6); the core works offline.

### 3.6 `/gate` — the commit-time gate, one command
- **How:** type `/gate` before a commit. It scopes the diff, then runs the `reviewer`
  subagent plus every installed document audit in **parallel subagents** — it reads each skill's
  audit section at runtime (the skills are manual-only and cannot be model-invoked) — and
  merges the findings under the shared ladder + ownership contract into **one** verdict. What
  flips that line is the ladder's to say, not the gate's — see *What flips the verdict line*
  there (attest ADR-0055); minors and nits are reported and counted, never restated as a second
  rule here. The last line it prints is what to **do** — *commit*, or *fix these N, then
  `/gate`* — and on a ✅ that is the end of the round: minors travel to `PROGRESS.md` *Next*,
  they do not buy another run (attest ADR-0061, the reason in the ladder under *✅ ends the
  round*).
- **What for:** the whole per-change gate in one invocation. Touches no document and
  no code; its one write is a dated **run record** under `.attest/` — SHA, kit version,
  passes, verdict, and findings at **attestation altitude** (severity · pass · class · path,
  never values or line numbers — the record publishes with the repo; attest ADR-0049) — the
  attestation that the gate ran (attest ADR-0016; stage it with the commit it gates). The document audits run in the `doc-auditor` agent — no Bash/Edit/Write,
  read-only **by capability** (attest ADR-0017; see 4.2). A missing piece degrades to a
  note, never a failure.
- **Not included:** `/audit-history` — that is the **ship** gate; run it before a push.

> **The skill pattern:** `description` is the brain (when Claude offers it — and when NOT)
> — that applies to auto-invocable skills; this kit's are all manual-only, so their
> descriptions are what you read in the picker. The body is the instructions. A new skill under an existing `.claude/skills/` hot-reloads
> — live change detection covers `SKILL.md` text, and `/reload-skills` is the manual nudge
> when it has not kicked in; a **new top-level directory** needs a restart.

---

## PART 4 — Subagents (`.claude/agents/`)

### 4.1 `reviewer` subagent — pre-commit code review
- **How:** ask for it — "use the reviewer subagent to review the diff" — or `@`-mention it
  (`@"reviewer (agent)"`) to guarantee it runs. Read-only — by capability for Edit/Write
  (they are stripped from its tools), **by rule** for Bash, which it keeps because it must
  run `git`, your tests and your lint.
- **What for:** walks the diff + conventions + tests → returns a **short verdict**
  (blocker/major/minor/nit) in **its own context** → your main context stays clean.
- **When:** before committing a larger change.

### 4.2 `doc-auditor` subagent — the gate's capability-restricted audit pass
- **How:** not usually invoked by hand — `/gate` launches one per document audit, handing
  it the skill's audit-mode section, the shared ladder and pre-scoped git material written
  to files (the agent cannot run `git` itself).
- **What for:** enforcement instead of promise. Its toolset is `Read, Grep, Glob` — no
  Bash, no Edit, no Write — so "the audit writes nothing" is a **property of the agent**,
  not a sentence it was asked to honor (attest ADR-0017).

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
  Auto mode (`Shift+Tab` cycles the permission modes) keeps a long run from stopping on
  approval prompts.

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

  Wire it into the repo with a checked-in `.mcp.json`, then approve it once at `claude`
  startup (`/mcp`). The kit ships no stub for this — a generic `my_app` skeleton taught
  nothing the shape below does not (attest ADR-0031). Write it yourself:

  ```json
  { "mcpServers": { "my-app": {
      "command": "${CLAUDE_PROJECT_DIR:-.}/.venv/bin/python",
      "args": ["-m", "my_app.mcp_server"] } } }
  ```

  Keep real tokens out of it — the file is git-tracked.

  The `${CLAUDE_PROJECT_DIR:-.}` prefix is the load-bearing part — it resolves against the repo
  root so the config travels.
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

- **Plan mode** (`Shift+Tab` cycles to it) — Claude proposes a plan first, you approve → then it acts.
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
./install.sh [--compliance] <path-to-your-project>
```

That is the whole procedure — do **not** hand-copy the files. The script is **copy-if-absent**:
every doc, skill, hook and `settings.json` is installed only if the target does not already
have it, and `.gitignore` is **appended to** rather than replaced. It appends **two** lines to
`.gitattributes` too — `.claude/hooks/* text eol=lf` and `.attest/*.md text eol=lf`. Both are
scoped to paths the kit itself owns and no wider, because `text` normalises on `git add` and a
blanket `*.sh` would rewrite your own scripts (attest ADR-0039); the second exists because the
ship guard parses two lines out of a record byte-exactly, so a CRLF record fails closed with a
reason that blames its age instead of its line endings (attest ADR-0037, ADR-0044). If you have
already ruled on either pattern, it is left alone. The template path reaches the same place by
subtraction: the kit's own `.gitattributes` carries a blanket `*.sh` pin it needs for its own
shell, and `template-cleanup.sh` drops exactly that line from a generated repo (attest
ADR-0043).

**What it prints** is grouped by capability, not by path (attest ADR-0031): one line per
group — documents, commands, checks, guards, manual — with `✓` for *landed*, `·` for
*already there* and `⚠` for *something is yours to look at*. Two blocks follow only when
they have content: **YOURS, UNTOUCHED** (files the kit also ships and did not overwrite —
the designed outcome, not a warning) and **NEEDS YOU** (a kit-owned file that drifted from
upstream, or a hook on disk that your `settings.json` leaves unwired). A re-run that changed
nothing says exactly that, in one line.

`--compliance` adds `COMPLIANCE.md` and `/compliance`; without it neither lands (attest
ADR-0030). Adding it later is the same command again — copy-if-absent means a re-run only
fills the gap.

It deliberately does **not** copy `README.md`, `LICENSE`, `docs/`, `scripts/`, anything under
`.github/`, or itself — those are *attest*, not your project.

`GUIDE.md` lands as the kit's reference manual: a copy the kit
itself installed is recognized on re-runs (current → skipped, outdated → pointed out for a
by-hand refresh); a guide of your own keeps its name and the kit's goes in beside it as
`attest-GUIDE.md`; only with both names taken is it skipped. It is **not** a
runtime dependency: the shared audit ladder and the ownership contract live in
`.claude/skills/_shared/audit-ladder.md` and install with the skills that read them (attest
ADR-0010), so a missing GUIDE costs a reader a lookup, not an audit its severity.

**If you add CI of your own,** the kit ships no starting point for it — what your project runs
is your decision, and a fully commented-out example file taught nothing a sentence does not
(attest ADR-0031). Two habits are worth carrying over from attest's own workflows, and they are
the whole of what that example existed to teach:

- **Pin the tool version.** An unpinned `uvx ruff` (or `npx prettier`, or `go test` on `latest`)
  turns your gate red the day upstream changes a rule or a default, with nothing of yours
  having moved.
- **Pin GitHub Actions by commit SHA, not by tag** — `uses: actions/checkout@11d5960… # v4`.
  A tag is a mutable pointer: whoever controls it decides what runs in your job. Keep the
  version as a trailing comment so the diff stays readable (attest ADR-0025).

**Upgrading** — pull the kit and re-run it; that is the whole procedure here too:

```bash
git -C /tmp/attest pull && /tmp/attest/install.sh <path-to-your-project>
```

Re-running is safe: copy-if-absent never touches your files, and a `GUIDE.md` the kit itself
installed is recognized rather than duplicated (an outdated kit copy in the `GUIDE.md` slot
is pointed out for a by-hand refresh, never overwritten). The SKIPPED list
names every file left alone — and says of each kit-owned skill/hook/agent file whether it
is **identical to the kit's** (a re-run, nothing to do) or **DIFFERS** (yours or stale —
diff it against the kit checkout and merge by hand), so a stale install is never silent
(attest ADR-0018). The
kit's version is the `Kit version:` line in `.claude/skills/_shared/audit-ladder.md` — it
travels inside the ladder, so the installed version is always the one your audits actually
used, and `/gate`'s run record cites it.

Afterwards: **restart Claude Code** (`.claude/` is a new top-level directory, so the skills
only load on a fresh session — until then `/business` does not exist), fill `CLAUDE.md`
(`/init`), then declare with `/business` and `/decision` — `/business` will tell you whether
this project needs `--compliance` too. Promote mature skills
into **`~/.claude/skills/`** → available globally, in every project — **but not the audit
family** (`/business`, `/decision`, `/compliance`, `/audit-history`, `/gate`): those read
`.claude/skills/_shared/audit-ladder.md` and `.claude/agents/` by **project-relative** path,
so a promoted copy silently loses its ladder exactly in the projects promotion is meant to
serve — the ones without the kit. The audit family travels by `install.sh`, never by
promotion (attest ADR-0010: the contract installs with its consumers).

---

## PART 9 — The compliance-native workflow

The pieces above compose into one governed lifecycle. It runs on **three cadences** — set up
once, loop every change, gate before you ship — so read it as two loops around a gate, not a
single straight line.

**SETUP — once, at the start**
- `/business` — declare intent + the archetype (`BUSINESS.md`). **It ends by making the
  compliance call**: either *"in scope, here is the trigger"* or *"out of scope, record that
  sentence"* (attest ADR-0030). What you then do depends on how you adopted the kit — with
  `install.sh`, re-run it with `--compliance` to add the pair; from the **template button**,
  they are already in the repo, so being out of scope means **deleting** `COMPLIANCE.md` and
  `.claude/skills/compliance/` instead. The two paths differ on purpose: a generated repo has
  no installer to re-run.
- `/compliance` — **only if in regulated scope**, and only once it is installed — establish
  the posture (`COMPLIANCE.md`). It reads the archetype `/business` recorded.
- From here on the hooks work without you: the **declaration hook** puts your non-goals
  in front of the agent at every session start, and the **ship guard** asks before a push or a
  submit that no `/audit-history` run has cleared — for the commands on its literal list and for
  the publish tools wired to it, and it never forbids; the answer is an ordinary permission
  prompt (PART 2.2).

**PER-CHANGE — every unit of work**
1. **Decide → `/decision`** — record a choice worth keeping (append-only) *as you make it*.
2. **Build.**
3. **Gate, before the commit — one command: `/gate`.** It runs the installed passes in parallel
   subagents, merges one verdict, and appends a dated **run record** under `.attest/`
   (stage it with the commit — that is the attestation the gate ran); each pass fires only
   when relevant:
   - the `reviewer` subagent — the code-level pass;
   - `/business audit` — did the work cross a non-goal / creep past scope?
   - `/decision audit` — a choice made in code but never recorded?
   - `/compliance audit` — did the diff touch regulated ground? (skips unless it did; absent
     entirely in a project that did not opt in — the ladder says who reports instead)

   Each **owns** its own finding, so one hunk is flagged once. (The pieces stay separately
   runnable when you want just one.)
4. **Commit** (`feat:` / `fix:` / `docs:` …) — one logical unit.
5. **`/checkpoint`** — pour state into `PROGRESS.md`, then `/clear` between blocks.

**SHIP — before code leaves the machine**
- `/audit-history` — the quick leak scan, **every push**. It appends
  `.attest/ship-…-<HEAD sha>.md`.
- `/audit-history full` — the whole-history scan, **before a public release** (a secret or a
  name in *any* old commit, not just `HEAD`).
- You no longer have to remember either: for the commands on its literal list — and for a
  publish made through an MCP server rather than a shell — the ship guard asks at the moment one
  of them is about to run and names what is missing (PART 2.2).

> **Reading key:** the SETUP row runs **once**; the PER-CHANGE loop repeats **every commit**;
> the SHIP gate fires only when code **leaves the machine**. `/compliance` appears in both —
> *bootstrap* in setup, *audit* in the per-commit gate.

That is the whole claim: a repo that can answer the questions an auditor asks — what it is
for, what it will not do, why it chose what it did, under what rules it operates, and that it
ships nothing it should not — because each of those has a **living document** and a **gate**
that checks reality against it.
