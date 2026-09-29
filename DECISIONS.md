# DECISIONS.md — attest

Choices that still bind. The full log, ADR-0001 to ADR-0078, is frozen in
`docs/archive/attest-decisions.md`; each entry names its source there.

## 2026-08-28 — Write every hook in POSIX sh
Hooks run under `/bin/sh` with nothing beyond `git`, so an adopter installs no runtime. Python
hooks and tooling were dropped. `install.sh` and `scripts/*.sh` stay bash. (ADR-0027)

## 2026-09-04 — Clear a push only on a record naming its HEAD with 0 blockers
The guard reads the record's `HEAD:` and `findings:` lines, not that a file exists. A commit
that only adds records passes as the commit they name (2026-09-28). (ADR-0037, ADR-0077)

## 2026-09-09 — Keep records at attestation altitude
A record names a finding's severity, class and path, never its value, line or excerpt: it is
committed and publishes with the repository. (ADR-0049)

## 2026-09-10 — Ship no legal date
Deadlines move with amendments; the kit points at the law and leaves dates to a live source.
(ADR-0053)

## 2026-09-16 — Keep betterleaks optional
The guard scans with betterleaks when it is installed, and a scan can only add a question,
never clear one. Without it, the guard decides as it would with no scan. (ADR-0070)

## 2026-09-26 — Stay repo-resident, not a plugin
A `.claude/` in the repository reaches every collaborator and cloud session with no
per-machine install; `install.sh` is the only way in. (epic #28 D5, ADR-0075)

## 2026-09-26 — Break cleanly for v1
v1.0.0 removes what the cut removes with no aliases and no deprecation window; a migration note
of ≤15 lines tells an adopter how to move. (epic #28, #43)

## 2026-09-28 — Ask by default, deny only by opt-in
An ask needs a human; `ATTEST_GUARD=deny` turns every ask into a deny where nobody answers.
Denying by default would block every mention of a push in an attended session. (ADR-0078)
