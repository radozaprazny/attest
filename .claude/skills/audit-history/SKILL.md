---
name: audit-history
description: >-
  The clean-history leak gate — before code leaves the machine (a push, or a public
  republish), scan the git history and working tree for things that must not ship: secrets
  and keys, personal data (EU-first: GDPR ordinary + special-category + national identifiers),
  client/customer names, internal hostnames/paths, metadata and stray large/data files.
  Read-only — it reports a severity-ranked verdict with remediation, it never rewrites
  history. Two modes: default (working tree + staged + the diff about to be pushed) and
  `full` (the entire history — all commits, all branches; run before a public release).
  Generic — usable in any repo. This is the one skill that maintains NO document; its "record"
  is the git history itself.
disable-model-invocation: true
---

# /audit-history — the clean-history leak gate (no doc)

This skill is the kit's **final gate** on the *clean history* spine node: before anything
leaves the machine, it checks that the repo is not carrying something it should not ship. It
**maintains no document** — the thing it guards *is* the git history. It **writes nothing**;
it reports.

The skill is **generic** — work with what you actually find in the repo, and assume nothing
about the specific project.

> **Router (this skill owns no doc):** status → `PROGRESS.md` · rules → `CLAUDE.md` ·
> why-it-exists → `BUSINESS.md` · why-we-chose-X-over-Y → `DECISIONS.md` · under-what-rules →
> `COMPLIANCE.md`. (full table: GUIDE PART 1)

## Not just a secret scanner

Generic scanners (`gitleaks`, `trufflehog`) find API-key-shaped strings — run them too if you
have them. This skill earns its place by being **EU-first and integrated**:

- it looks past key-regexes for **personal data** (GDPR) and **client confidentiality** —
  personal names, customer/client names, internal hostnames — which a regex set misses;
- it reads the project's own declarations to decide what counts as a leak: if `BUSINESS.md` or
  `COMPLIANCE.md` says a **class of data must not exist or must not leave**, then content
  matching it — sitting in the tree or in history — is a finding *here* even if it is not a
  "secret".

> **Boundary — content, not behaviour.** You own what the repo **ships**: bytes in the tree or
> in history. You do **not** own what the code **does**. A non-goal like *"no network access"*
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

Use the shared audit ladder (see GUIDE PART 3), tiered by real GDPR/confidentiality exposure:

- **blocker**
  - **Secrets / keys** — API keys, tokens, private keys (`-----BEGIN … PRIVATE KEY-----`),
    passwords, `.env` files, connection strings, cloud credentials.
  - **Special-category personal data** (GDPR Art 9) — health, biometric, racial/ethnic,
    political, religious, sexual-orientation, trade-union data.
  - **National identifiers** — passport / ID / tax numbers (e.g. a national birth number).
- **major (PII / client name)**
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

## Verdict

**Return a short verdict** (shared audit ladder — see GUIDE PART 3). For each finding give: a
one-line description; **evidence** — commit + `file:line` (blob ref for history-only hits);
and a **severity** from the taxonomy above. End with a **recommended remediation** — but
**do not** rewrite history yourself:

- **rotate** the exposed secret (assume it is burned the moment it was committed);
- purge it from history (`git filter-repo` / BFG) **and force-push** — a plain delete-commit
  leaves the data in history (and does **not** satisfy a GDPR Art 17 erasure request);
- EU-first pointer: if the data was ever pushed to a public remote, a **personal-data breach**
  may be in play (GDPR Art 33/34 — a 72-hour notification duty *may* apply) — **consult**, do
  not decide it here.

If nothing is found, say so in one line. **The audit writes nothing** and rewrites no history.

## Boundary vs the reviewer

The `reviewer` subagent does a **shallow, per-diff** leak sniff as part of commit-readiness.
This skill is the **deep, history-wide** gate run before a push or release — it supersedes
that shallow check when it is time to ship.
