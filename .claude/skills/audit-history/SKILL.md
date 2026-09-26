---
name: audit-history
description: >-
  The clean-history leak gate — before code leaves the machine (a push, or a public
  release), scan the git history and working tree for things that must not ship: secrets
  and keys, personal data (EU-first: GDPR ordinary + special-category + national identifiers),
  client/customer names, internal hostnames/paths, metadata and stray large/data files.
  Read-only on your content — it reports a severity-ranked verdict with remediation and never
  rewrites history; its one write is a dated run record under `.attest/`. Two modes:
  default (working tree + staged + the diff about to be pushed) and
  `full` (the entire history — all commits, all branches; run before a public release).
  Generic — usable in any repo. This is the one skill that maintains NO document; its "record"
  is the git history itself.
disable-model-invocation: true
argument-hint: "[full]"
---

# /audit-history — the clean-history leak gate (no doc)

This skill is the kit's **final gate** on the *clean history* spine node: before anything
leaves the machine, it checks that the repo is not carrying something it should not ship. It
**maintains no document** — the thing it guards *is* the git history. It changes nothing you
wrote; its only write is the dated **run record** below, which is what makes *"this state was
audited"* a fact in the repo rather than a memory.

The skill is **generic** — work with what you actually find in the repo, and assume nothing
about the specific project.

> **Router (this skill owns no doc):** status → `PROGRESS.md` · rules → `CLAUDE.md` ·
> why-it-exists → `BUSINESS.md` · why-we-chose-X-over-Y → `DECISIONS.md` · under-what-rules →
> `COMPLIANCE.md`. (full table: GUIDE PART 1)

## Not just a secret scanner

A maintained rule-pack finds API-key-shaped strings better than any reading does, so this skill
uses one when it is installed: **`betterleaks`**, the successor to gitleaks by its original
author — and the ship guard calls it on `git push` too (attest ADR-0070). This skill earns its
place by what a rule-pack cannot do — it is **EU-first and integrated**:

- it looks past key-regexes for **personal data** (GDPR) and **client confidentiality** —
  personal names, customer/client names, internal hostnames — which a regex set misses;
- it reads the project's own declarations to decide what counts as a leak: if `BUSINESS.md` or
  `COMPLIANCE.md` says a **class of data must not exist or must not leave**, then content
  matching it — sitting in the tree or in history — is a finding *here* even if it is not a
  "secret".

> **Boundary — content, not behaviour.** You own what the repo **ships**: bytes in the tree or
> in history. (If `/compliance` is not installed in this project, regulated **content** you find
> is still yours — say what it is; only the *posture* question is unowned, and the ladder says
> so.) You do **not** own what the code **does**. A non-goal like *"no network access"*
> violated by new code is `/business audit`'s finding, not yours — even though it looks like
> an exfiltration risk. If one change both adds forbidden **behaviour** and commits forbidden
> **data**, flag only the data half and name `/business audit` for the rest.

## What it scans (two modes)

- **default (quick)** — the **working tree** + **staged** changes + the **diff about to be
  pushed** (`git diff @{push}..HEAD` when a push target exists, else the last commits and
  untracked files). Run it **before every push**.
- **`full`** — the **entire history**: every commit on every branch. Bare `git grep` only sees
  the current tree, so feed it the commit list to reach old blobs:
  `git grep <pattern> $(git rev-list --all)`. Slower; run it **before a public release / first
  open-sourcing**, where a secret buried in an old commit is exactly the risk. (`full` only
  becomes meaningful once the project has accumulated its own history — a fresh `git init` from
  the template has none yet.)

## The leak taxonomy (EU-first, severity-tiered)

Use the shared audit ladder (see `.claude/skills/_shared/audit-ladder.md`), tiered by real GDPR/confidentiality exposure:

- **blocker**
  - **Secrets / keys** — API keys, tokens, private keys (`-----BEGIN … PRIVATE KEY-----`),
    passwords, `.env` files, connection strings, cloud credentials.
  - **Special-category personal data** (GDPR Art 9) — health, biometric, racial/ethnic,
    political, religious, sexual-orientation, trade-union data.
  - **National identifiers** — passport / ID / tax numbers (e.g. a national birth number).
- **major**
  - **Ordinary personal data** — emails, phone numbers, personal names, postal addresses.
  - **Client / customer names** — confidentiality, not statute; still must not ship.
  - **IP addresses** (personal data per CJEU *Breyer*), online/device identifiers,
    cookies, precise geolocation.
- **minor**
  - Internal **hostnames / absolute paths / usernames**, build **metadata**, and stray
    **large or data files** committed by accident.

Weigh context: a maintainer's own name/email in commit *authorship* of a repo they are
publishing is usually intended (note it, do not alarm); the same data about a **third party**,
or in file *content*, is the real exposure.

## How to run it

1. **Establish scope** for the mode (default vs `full`) with the git commands above; for
   `full`, remember blobs in old commits are not in the current tree — scan the history, not
   just `HEAD`.
2. **Read the project's own boundaries** if present — `BUSINESS.md` non-goals and
   `COMPLIANCE.md` data-handling rules — so a project-specific leak (a forbidden source, a
   data class that must not persist) is caught, not just generic patterns.
3. **Scan** for each taxonomy class. Prefer the repo's own scanner if one is configured; add
   the EU-first / confidentiality classes on top. Anchor every hit to a commit + `file:line`.
4. **For secrets and keys, use `betterleaks` when it is on PATH** (attest ADR-0070). Give every
   call `--redact=100 --no-banner --exit-code 42` and read the exit code: `0` is clean, `42` is a
   finding, and **anything else did not finish** — a degraded layer, never a clean one. `42`
   rather than the tool's default of `1`, because `1` is also what it exits with when it cannot
   open the repository. Which call reaches which part of the scope was measured, not assumed:
   - HEAD's commits not yet on any remote — `betterleaks git . --log-opts="HEAD --not --remotes"`;
     in `full` mode, `--log-opts=--all`;
   - unstaged changes — `betterleaks git . --pre-commit`; staged ones — add `--staged`;
   - untracked files — **one** `betterleaks dir <path> <path> …` call over every path that
     `git -c core.quotepath=off ls-files --others --exclude-standard` lists. `quotepath=off`
     because git otherwise prints a name with diacritics as an escaped string the scanner cannot
     open; one call because `dir` takes several paths and one exit code is easier to read than
     many. **If that list is empty, skip the call** — `betterleaks dir` with no path scans the
     whole directory, and so does `betterleaks dir .`: both read ignored files, so a gitignored
     `.env` that will never ship reports as a leak.

   On a `42`, list the findings for the session with
   `--redact=100 --report-format json --report-path -` added to the call that found them: that
   gives rule, path, commit and the `Fingerprint` a false positive needs in `.betterleaksignore`,
   with the value itself replaced by `REDACTED`. **Never run a listing without `--redact`** — a
   verbose run prints the secret, into a transcript that is saved and sent to the model.
   **Never add `--validation`**: it tests a found secret by sending it to its provider, which is
   a secret leaving the machine in the name of checking whether it left. The record names the
   layer that ran — `betterleaks <version>`, from `betterleaks version`, under what was scanned,
   or, where the tool is absent, a `degraded:` line saying the key-shaped layer was this pass's
   own patterns.

   **A `42` you triage as a false positive** — a test fixture, an example key in documentation —
   is not a finding: say in the record which rule and path it was and why it is not a secret.
   Then tell the person the ship guard will still ask `leak` on this push until the value is
   gone **from the unpushed commits** — a new commit that deletes it does not do that, because
   the scan reads every commit not yet pushed — or its `Fingerprint` is in `.betterleaksignore`.
   That file clears the scan the moment it exists, but commit it, so a `full` audit and every
   clone see it too. A commit moves HEAD, so make it **before** this record is written, or the
   record names a sha that is not the one being pushed.

   The guard's own scan is wider than this one: every local branch and tag not yet on a remote,
   not HEAD's commits alone (attest ADR-0074). So after a clean audit here it can still ask
   `leak`, over a commit this record does not cover; the listing in its prompt names the range.

## Verdict

**Return a short verdict** (shared audit ladder — see `.claude/skills/_shared/audit-ladder.md`). For each finding give: a
one-line description; **evidence** — commit + `file:line` (blob ref for history-only hits);
and a **severity** from the taxonomy above. End with a **recommended remediation** — but
**do not** rewrite history yourself:

- **rotate** the exposed secret (assume it is burned the moment it was committed);
- purge it from history (`git filter-repo` / BFG) **and force-push** — a plain delete-commit
  leaves the data in history (and does **not** satisfy a GDPR Art 17 erasure request);
- EU-first pointer: if the data was ever pushed to a public remote, a **personal-data breach**
  may be in play (GDPR Art 33/34 — a 72-hour notification duty *may* apply) — **consult**, do
  not decide it here.

If nothing is found, say so in one line. **The audit changes no file you wrote** and rewrites
no history.

## The run record — the one write

After reporting, append one record under `.attest/`, mirroring `/gate`'s (attest ADR-0016):

    .attest/ship-<YYYYMMDD>-<HHMMSS>-<short-HEAD-sha>.md

**Two lines are a machine interface — write them exactly** (attest ADR-0037). The ship guard
reads them; prose around them is yours, but these are parsed:

```markdown
- HEAD: <short sha> (<branch>) · tree: <clean | dirty — …>
- findings: <n> blocker · <n> major · <n> minor
```

The guard requires a record whose `HEAD:` line carries the sha it is about **and** whose
`findings:` line begins `0 blocker`. Anything else — a record reporting a blocker, a record in
some older shape, an empty file — makes it ask, because *"this state was audited"* and *"this
state is clean"* are different claims and only the second one should open the door. Get the sha
from `git rev-parse --short HEAD` so the name and the line agree.

Around those two lines write the date, the kit version (from the shared ladder), the mode
(`default` or `full`), the verdict, what was scanned and any remediation — **at the altitude of
an attestation, not a report** (attest ADR-0049): one line per blocker and major, giving the
severity, the class of the thing and the path, with the commit for a history-only hit. Never the
value, never the line number, never an excerpt. This record is committed, so it publishes with
the repository — and a ship record is the one file in this kit that would otherwise state in
public, with a date, exactly where a secret used to live. The full evidence goes to the session,
where the person who has to rotate the key is. **The short SHA in the
filename is load-bearing** — the `PreToolUse` ship guard (`.claude/hooks/ship_guard.sh`) looks for a record
matching the *current* HEAD before a push, a submit or an upload, and then **reads the two lines
above**, so the question it answers is *"was this state audited and did it come back clean"* —
not *"was this repo ever audited"*, and not *"does a file with the right name exist"*
(attest ADR-0028, narrowed by ADR-0037). **One path no record can clear:** a publish made
through an MCP server rather than a shell (`push_files`, `create_pull_request`, …) sends bytes
chosen in the call, which need not be committed or match HEAD — the guard asks there every
time, and a clean record is not the answer to it (attest ADR-0058). Scan what you are about to
send, or push through git so the record covers it. Write the
record even when the verdict is clean: a clean ship is exactly the state the guard must be able
to recognise.

**Where the record lives in history** (attest ADR-0033). Write it **before** the push it gates,
so the sha in its name is the state that actually leaves the machine — which means it is an
**untracked** file at the moment the guard reads it, and the guard reads the filesystem, not the
index. A record can therefore never be contained by the commit it names: commit it afterwards,
under a later sha, and leave that visible. Do **not** rename it to match the commit that carries
it, and do **not** postpone writing it until after the push so the names line up — either would
make the filename a claim about a state nothing audited, which is the trap ADR-0032 already
refused. Read `.attest/` accordingly: `ship-…-<sha>.md` is evidence about `<sha>`, never about
the commit it happens to sit in.

**Write the record and ship in two separate steps.** A `PreToolUse` guard is evaluated *before*
the command it guards runs, so a single step that writes the record and then pushes is judged
against the state where the record does not exist yet — the guard asks, correctly, and the
prompt looks wrong. Write the record, let that step finish, then push.

Never write a record for an audit you did not actually complete — a record for a pass that
degraded says which part degraded, in one line, or it is not written at all.

## Boundary vs the reviewer

The `reviewer` subagent does a **shallow, per-diff** leak sniff as part of commit-readiness.
This skill is the **deep, history-wide** gate run before a push or release — it supersedes
that shallow check when it is time to ship.
