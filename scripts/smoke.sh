#!/usr/bin/env bash
# smoke.sh — attest's own smoke test. Not part of the kit: install.sh never copies
# scripts/, and template-cleanup deletes it in generated repos.
#
# Covers the classes of defect the real audits actually found: hooks crashing on odd
# payloads, a non-idempotent installer, .gitignore corruption, junk files landing, and
# hooks installing silently inert. Run it from anywhere: ./scripts/smoke.sh

set -euo pipefail

# The hooks honour five environment overrides — two paths (ADR-0028) and three headings
# (ADR-0047). A maintainer who sets any of them for this checkout — which docs/attest-progress.md
# tells them to do, so the SessionStart hook is not silent here — would otherwise have that
# ambient value reach every fixture below, and the assertions pinning the DEFAULT document paths
# and headings would fail against files no test wrote. The suite controls its own environment;
# the tests that want an override set it per invocation.
unset ATTEST_BUSINESS ATTEST_THREAD_CARRIER
unset ATTEST_NONGOALS_HEADING ATTEST_STATE_HEADING ATTEST_NEXT_HEADING

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0

ok()   { PASS=$((PASS + 1)); echo "  ok: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "FAIL: $1" >&2; }

check() { # check <description> <command...>
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$desc"; else fail "$desc"; fi
}

says() { # says <description> <text> <pattern> — assert the output contains a pattern
  if printf '%s' "$2" | grep -q "$3"; then ok "$1"; else fail "$1"; fi
}

says_not() { # says_not <description> <text> <pattern> — assert it does not
  if printf '%s' "$2" | grep -q "$3"; then fail "$1"; else ok "$1"; fi
}

# run_install <args...> — capture the run's output. Never aborts the suite: a non-zero exit
# just leaves the caller's assertions to fail and be counted, so the verdict still prints.
run_install() { "$KIT/install.sh" "$@" 2>&1 || true; }

DECL="$KIT/.claude/hooks/session_declaration.sh"
GUARD="$KIT/.claude/hooks/ship_guard.sh"
RGUARD="$KIT/.claude/hooks/record_guard.sh"

# --- 0. the kit carries no interpreter dependency --------------------------------------
echo "kit shape:"
py_count=$(find "$KIT/.claude" -name '*.py' | wc -l)
if [ "$py_count" -eq 0 ]; then ok "no .py anywhere under .claude/"; else fail "no .py anywhere under .claude/ ($py_count found)"; fi
check "no formatter config ships"  test ! -e "$KIT/ruff.toml"
check "no inert .example files ship" test ! -e "$KIT/.mcp.json.example"

# --- 1. hooks: fail-open on every payload ----------------------------------------------
echo "hooks — fail-open:"
for hook in "$DECL" "$GUARD"; do
  name="$(basename "$hook")"
  check "$name survives an empty payload"    sh -c "echo '{}' | sh '$hook'"
  check "$name survives garbage stdin"       sh -c "echo 'not json' | sh '$hook'"
  check "$name survives no stdin at all"     sh -c "sh '$hook' </dev/null"
  check "$name survives a missing project"   sh -c "echo '{}' | CLAUDE_PROJECT_DIR='$WORK/nowhere' sh '$hook'"
done

# --- 2. the declaration hook: silent until something is declared -----------------------
echo "hooks — SessionStart declaration:"
D0="$WORK/decl-empty"; mkdir -p "$D0"
out=$(CLAUDE_PROJECT_DIR="$D0" sh "$DECL")
if [ -z "$out" ]; then ok "silent in a project with no documents"; else fail "silent in a project with no documents"; fi
# The shipped skeletons are <placeholder> text: a fresh install must add no session noise.
D1="$WORK/decl-template"; mkdir -p "$D1"; cp "$KIT/BUSINESS.md" "$KIT/PROGRESS.md" "$D1/"
out=$(CLAUDE_PROJECT_DIR="$D1" sh "$DECL")
if [ -z "$out" ]; then ok "silent while the documents are still the shipped templates"; else fail "silent while the documents are still the shipped templates"; fi
# ...and speaks as soon as a non-goal is real
D2="$WORK/decl-filled"; mkdir -p "$D2"
printf '# B\n\n## Non-goals\n\n- no network access at runtime\n\n## What success looks like\n\n- <ph>\n' > "$D2/BUSINESS.md"
printf '# P\n\n## Current state\n\nEngine wired.\n\n## Next\n\n- tune it\n' > "$D2/PROGRESS.md"
out=$(CLAUDE_PROJECT_DIR="$D2" sh "$DECL")
says     "carries the declared non-goal into the session" "$out" 'no network access at runtime'
says     "carries the live state and the next step"       "$out" 'Engine wired'
says     "…and the next step"                             "$out" 'tune it'
says_not "drops the placeholder sections"                 "$out" '<ph>'
# The cap must trim EACH section, not the block: a single trailing `head` silently dropped
# whichever section came last, plus the closing tag. Fixture deliberately overruns it.
D3="$WORK/decl-huge"; mkdir -p "$D3"
{ echo '# B'; echo; echo '## Non-goals'; echo; i=1
  while [ "$i" -le 60 ]; do echo "- non-goal number $i"; i=$((i + 1)); done; } > "$D3/BUSINESS.md"
printf '# P\n\n## Current state\n\nstate marker\n\n## Next\n\n- next marker\n' > "$D3/PROGRESS.md"
huge=$(CLAUDE_PROJECT_DIR="$D3" sh "$DECL")
says "an overrunning section is trimmed"              "$huge" 'non-goal number 24'
says "…and says how much it dropped"                  "$huge" 'more line(s)'
says_not "…and really does drop it"                   "$huge" 'non-goal number 25'
says "the later section survives the trim"            "$huge" 'state marker'
says "…including the one after that"                  "$huge" 'next marker'
says "the block is always closed"                     "$huge" '</project-declaration>'
lines=$(printf '%s\n' "$huge" | wc -l)
if [ "$lines" -le 55 ]; then ok "output stays bounded ($lines lines)"; else fail "output stays bounded ($lines)"; fi
# A BUSINESS.md with no non-goals section at all must not spill the neighbouring sections in
printf '# B\n\n## Purpose\n\nsecret sauce\n' > "$D2/BUSINESS.md"
says_not "never prints a section it was not asked for" "$(CLAUDE_PROJECT_DIR="$D2" sh "$DECL")" 'secret sauce'
# A repo that ships the kit's documents as templates and keeps its live ones elsewhere
mkdir -p "$D2/docs"
printf '# live\n\n## Non-goals\n\n- never touch production\n' > "$D2/docs/live-business.md"
out=$(CLAUDE_PROJECT_DIR="$D2" ATTEST_BUSINESS=docs/live-business.md sh "$DECL")
says     "ATTEST_BUSINESS redirects it to the live document" "$out" 'never touch production'
says     "…and the heading names the file it actually read"  "$out" 'docs/live-business.md'
says_not "an unset override does not read the live document" "$(CLAUDE_PROJECT_DIR="$D2" sh "$DECL")" 'never touch production'

# A project that writes its documents in another language. Without an override the hook reads
# the file, matches nothing and prints nothing — which from inside a session is the same thing
# as a hook that was never registered, so the silence is asserted first and the fix second
# (ADR-0047).
D4="$WORK/decl-lang"; mkdir -p "$D4"
printf '# B\n\n## Čo nerobíme\n\n- žiadne články\n' > "$D4/BUSINESS.md"
printf '# P\n\n## Stav k 7. 9.\n\nSK marker\n\n## Ďalší krok\n\n- SK next marker\n' > "$D4/PROGRESS.md"
if [ -z "$(CLAUDE_PROJECT_DIR="$D4" sh "$DECL")" ]; then
  ok "non-English headings print nothing without an override"
else
  fail "non-English headings print nothing without an override"
fi
lang=$(CLAUDE_PROJECT_DIR="$D4" \
  ATTEST_NONGOALS_HEADING='Čo nerobíme' ATTEST_STATE_HEADING='Stav' ATTEST_NEXT_HEADING='Ďalší krok' \
  sh "$DECL")
says "ATTEST_NONGOALS_HEADING finds a renamed section"  "$lang" 'žiadne články'
says "ATTEST_STATE_HEADING finds a renamed section"     "$lang" 'SK marker'
says "ATTEST_NEXT_HEADING finds a renamed section"      "$lang" 'SK next marker'
# The defaults are what a project that never sets them keeps getting, and `${VAR:-}` rather
# than `${VAR-}` is what guarantees it. An exported-but-EMPTY override is not "no override":
# an empty awk pattern matches EVERY `## ` heading, so the wrong operator would not blank the
# declaration — it would pour the whole document into it. Asserting the default marker alone
# cannot tell the two apart (it is present either way), so the fixture carries a second section
# the default must NOT reach, and that is the assertion doing the work.
printf '# P\n\n## Current state\n\nEN marker\n\n## Notes\n\nFOREIGN marker\n' > "$D4/PROGRESS.md"
empty=$(CLAUDE_PROJECT_DIR="$D4" ATTEST_STATE_HEADING='' sh "$DECL")
says     "an EMPTY override falls back to the default heading" "$empty" 'EN marker'
says_not "…and does not become a match-everything pattern"     "$empty" 'FOREIGN marker'
# The pattern reaches awk through ENVIRON[], not `-v`, so ONE backslash escapes a metacharacter.
# Under `-v` this exact value arrives as `Current state (WIP)` — a grouping, matching nothing —
# and awk's warning about it lands on the stderr the hook discards, so the miss is silent.
printf '# P\n\n## Current state (WIP)\n\nparen marker\n' > "$D4/PROGRESS.md"
says "a single backslash escapes a metacharacter in an override" \
     "$(CLAUDE_PROJECT_DIR="$D4" ATTEST_STATE_HEADING='Current state \(WIP\)' sh "$DECL")" 'paren marker'
# A regex the engine refuses is the new failure mode this knob introduces — user input reaches
# a regex compiler here for the first time. Fail-open is the hook's whole contract: it may
# print nothing, it must never fail, or a SessionStart hook starts erroring on every session.
printf '# P\n\n## Current state\n\nEN marker\n' > "$D4/PROGRESS.md"
if CLAUDE_PROJECT_DIR="$D4" ATTEST_STATE_HEADING='Current state \(WIP' sh "$DECL" >/dev/null 2>&1; then
  ok "an unparseable override still exits 0"
else
  fail "an unparseable override still exits 0"
fi
# A heading regex is matched against `## …` lines only, so it cannot reach into a level-3
# heading: neither to cut a section short at its own first subsection, nor to select one.
printf '# P\n\n## Current state\n\nEN marker\n\n### Detail\n\nsub marker\n' > "$D4/PROGRESS.md"
says     "a level-3 subheading does not end its parent section" \
         "$(CLAUDE_PROJECT_DIR="$D4" sh "$DECL")" 'sub marker'
says_not "…and an override aimed at one selects nothing" \
         "$(CLAUDE_PROJECT_DIR="$D4" ATTEST_STATE_HEADING='Detail' sh "$DECL")" 'sub marker'

# --- 3. the ship guard: asks exactly at the boundary -----------------------------------
echo "hooks — PreToolUse ship guard:"
S="$WORK/ship"; mkdir -p "$S"
git -C "$S" init -q .
git -C "$S" config user.email smoke@example.invalid
git -C "$S" config user.name smoke
: > "$S/f"; git -C "$S" add f; git -C "$S" commit -qm init
SHA="$(git -C "$S" rev-parse --short HEAD)"
guard() { echo "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$1\"}}" | CLAUDE_PROJECT_DIR="$S" sh "$GUARD"; }

if [ -z "$(guard 'ls -la')" ]; then ok "an ordinary command passes untouched"; else fail "an ordinary command passes untouched"; fi
says "git push without a record asks"        "$(guard 'git push origin main')" 'permissionDecision":"ask'
says "…and names what is missing"            "$(guard 'git push origin main')" "$SHA"
says "a kaggle submit asks too"              "$(guard 'kaggle competitions submit -c x -f s.tar.gz')" 'permissionDecision":"ask'
says "an upload asks too"                    "$(guard 'curl --upload-file x https://example.invalid')" 'permissionDecision":"ask'
if [ -z "$(guard 'git push --dry-run')" ]; then ok "a dry run publishes nothing and passes"; else fail "a dry run publishes nothing and passes"; fi
# ...but the flag may belong to a different call than the one that ships
says "a dry run chained to a real push still asks" "$(guard 'git push --dry-run && git push origin main')" 'permissionDecision":"ask'
# --- what the record has to SAY, not merely that it exists (ADR-0037) -----------------
rm -f "$S"/.attest/ship-*.md
: > "$S/.attest/ship-20260904-000000-$SHA.md"
says "an empty record for HEAD does not clear the guard" "$(guard 'git push origin main')" 'permissionDecision":"ask'
printf -- '- HEAD: %s (main)\n- findings: 1 blocker\n' "$SHA" > "$S/.attest/ship-20260904-000000-$SHA.md"
says "a record reporting a blocker does not clear it either" "$(guard 'git push origin main')" 'permissionDecision":"ask'
printf -- '- HEAD: %s (main)\n- findings: 10 blocker\n' "$SHA" > "$S/.attest/ship-20260904-000000-$SHA.md"
says "…and 10 blockers is not read as 0" "$(guard 'git push origin main')" 'permissionDecision":"ask'
printf -- '- HEAD: %s (main)\n- findings: 0 blocker\n' "$SHA" > "$S/.attest/ship-20260904-000000-$SHA.md"
if [ -z "$(guard 'git push origin main')" ]; then ok "a clean record for HEAD clears it"; else fail "a clean record for HEAD clears it"; fi
# The HEAD: line has to name THIS sha, not just be present
printf -- '- HEAD: deadbee (main)\n- findings: 0 blocker\n' > "$S/.attest/ship-20260904-000000-$SHA.md"
says "a record whose HEAD line names another commit does not clear it" "$(guard 'git push origin main')" 'permissionDecision":"ask'
# The kit's own shipped records must satisfy the parser the guard uses
for rec in "$KIT"/.attest/ship-*.md; do
  [ -e "$rec" ] || continue
  rsha="$(basename "$rec" .md)"; rsha="${rsha##*-}"
  # Shape, not verdict: on the day /audit-history honestly records a blocker, a verdict test
  # would fail on something that is not a defect — and the pressure would be to edit an
  # append-only record.
  check "the kit's own $(basename "$rec") is readable by the guard" \
    sh -c "sed -n '/^- HEAD:/{p;q;}' '$rec' | grep -q '^- HEAD: $rsha' && sed -n '/^- findings:/{p;q;}' '$rec' | grep -q '^- findings:'"
done

rm -f "$S"/.attest/ship-*.md   # the deadbee record above is still present and would fail below
# EVERY record for the sha must be clean, not merely one of them (ADR-0037). The glob expands
# lexicographically, so "the first clean one wins" meant the OLDEST won — and quick-scan-then-
# full-scan is the workflow the guard's own prompt recommends.
printf -- '- HEAD: %s (main)\n- findings: 0 blocker\n' "$SHA" > "$S/.attest/ship-20260101-000000-$SHA.md"
printf -- '- HEAD: %s (main)\n- findings: 3 blocker\n' "$SHA" > "$S/.attest/ship-20260909-235959-$SHA.md"
says "an older clean record does not override a newer blocker" "$(guard 'git push origin main')" 'permissionDecision":"ask'
printf -- '- HEAD: %s (main)\n- findings: 0 blocker\n' "$SHA" > "$S/.attest/ship-20260909-235959-$SHA.md"
if [ -z "$(guard 'git push origin main')" ]; then ok "two clean records for the sha still clear it"; else fail "two clean records for the sha still clear it"; fi
# The parser reads the FIRST header line of each kind — prose at column 0 must not stand in
printf -- '- HEAD: %s (main)\n- findings: 2 blocker\n\nNote:\n- findings: 0 blocker (previous run)\n' "$SHA" > "$S/.attest/ship-20260909-235959-$SHA.md"
says "prose at column 0 cannot stand in for the header line" "$(guard 'git push origin main')" 'permissionDecision":"ask'
rm -f "$S"/.attest/ship-*.md

# --- a record is matched by what it SAYS, at any abbreviation (ADR-0050) ---------------
# `--short` has no stable length: `core.abbrev` is config, and git widens the default as a repo
# grows. Before ADR-0050 the guard globbed `ship-*$SHA*.md` and compared `- HEAD: $SHA` byte for
# byte, so the two sides disagreeing produced a prompt with a FALSE reason in both directions —
# "no record for HEAD" while it sat right there, or "reports a blocker" while it reported none.
# Every case below fails on the pre-ADR-0050 guard; the last two are the controls.
rm -f "$S"/.attest/ship-*.md
for _pair in 7:10 8:7 12:7 40:7 7:7; do
  _rec="${_pair%%:*}"; _cfg="${_pair##*:}"
  rm -f "$S"/.attest/ship-*.md
  git -C "$S" config core.abbrev "$_cfg"
  if [ "$_rec" = 40 ]; then _rs="$(git -C "$S" rev-parse HEAD)"
  else _rs="$(git -C "$S" rev-parse --short="$_rec" HEAD)"; fi
  printf -- '- HEAD: %s (main) · tree: clean\n- findings: 0 blocker\n' "$_rs" \
    > "$S/.attest/ship-20260910-000000-$_rs.md"
  if [ -z "$(guard 'git push origin main')" ]
    then ok "a record written at $_rec clears a guard reading at $_cfg"
    else fail "a record written at $_rec clears a guard reading at $_cfg"; fi
done
git -C "$S" config --unset core.abbrev
# ...but an abbreviation has to be one. Six hex is a coincidence waiting to happen, not a sha.
rm -f "$S"/.attest/ship-*.md
printf -- '- HEAD: %s (main)\n- findings: 0 blocker\n' "$(git -C "$S" rev-parse --short=6 HEAD)" \
  > "$S/.attest/ship-20260910-000000-short.md"
says "a six-hex prefix is not accepted as this commit" "$(guard 'git push origin main')" 'permissionDecision":"ask'
# ...and a prefix of a DIFFERENT commit is still not this one
rm -f "$S"/.attest/ship-*.md
printf -- '- HEAD: deadbeef1 (x)\n- findings: 0 blocker\n' > "$S/.attest/ship-20260910-000000-deadbeef1.md"
says "a record naming another commit does not clear it" "$(guard 'git push origin main')" 'permissionDecision":"ask'

# --- a CRLF checkout is a property of the checkout, never of the verdict (ADR-0050) ----
# The `.gitattributes` pin claimed the `- HEAD:` arm "never matches" on CRLF. It never matched
# the BARE form; the shape /audit-history actually writes — sha, branch, tree — passed anyway,
# because the CR landed where a `*` swallowed it. Both forms are now read the same way.
for _shape in template bare; do
  rm -f "$S"/.attest/ship-*.md
  # the guard's OWN default abbreviation, so this isolates line endings from ADR-0050's sha
  # length. At that length the template shape passed before this series too — which is the
  # point: the `.gitattributes` claim that the arm "never matches" was already false, and only
  # the bare shape below is a regression test. Both are pinned so neither can drift back.
  _cs="$(git -C "$S" rev-parse --short HEAD)"
  if [ "$_shape" = template ]
    then printf -- '- HEAD: %s (main) \xc2\xb7 tree: clean\r\n- findings: 0 blocker \xc2\xb7 0 major\r\n' "$_cs" > "$S/.attest/ship-20260910-000000-$_cs.md"
    else printf -- '- HEAD: %s\r\n- findings: 0 blocker\r\n' "$_cs" > "$S/.attest/ship-20260910-000000-$_cs.md"; fi
  if [ -z "$(guard 'git push origin main')" ]
    then ok "a CRLF record in its $_shape shape clears the guard"
    else fail "a CRLF record in its $_shape shape clears the guard"; fi
done
# an uppercase sha is the same sha
rm -f "$S"/.attest/ship-*.md
printf -- '- HEAD: %s (main)\n- findings: 0 blocker\n' \
  "$(git -C "$S" rev-parse --short HEAD | tr 'a-f' 'A-F')" > "$S/.attest/ship-20260910-000000-up.md"
if [ -z "$(guard 'git push origin main')" ]
  then ok "an uppercase sha in the record is the same sha"
  else fail "an uppercase sha in the record is the same sha"; fi
rm -f "$S"/.attest/ship-*.md

# --- writing the evidence is itself a decision (ADR-0051) -----------------------------
# The record the guard above reads is an ordinary untracked file, and the ship guard judges
# commands and publish tools — so the Write tool went straight past it. These two arms make the
# write a prompt.
rguard() { echo "{\"tool_name\":\"Write\",\"permission_mode\":\"auto\",\"tool_input\":{\"file_path\":\"$1\",\"content\":\"x\"}}" | CLAUDE_PROJECT_DIR="$S" sh "$RGUARD"; }
says "writing a ship record asks"                "$(rguard "$S/.attest/ship-20260910-000000-abc1234.md")" 'permissionDecision":"ask'
if [ -z "$(rguard "$S/src/main.py")" ]; then ok "an ordinary file write passes untouched"; else fail "an ordinary file write passes untouched"; fi
if [ -z "$(rguard "$S/.attest/gate-20260910-000000-abc1234.md")" ]; then ok "a gate record is not gated — no machine reads it"; else fail "a gate record is not gated — no machine reads it"; fi
if [ -z "$(rguard "$S/.attest/tmp/scratch.md")" ]; then ok "the ignored scratch is not gated either"; else fail "the ignored scratch is not gated either"; fi
says "a shell redirect into a record asks too"   "$(guard 'printf x > .attest/ship-20260910-000000-abc1234.md')" 'permissionDecision":"ask'
says "…and so does a tee into one"               "$(guard 'echo x | tee .attest/ship-a.md')" 'permissionDecision":"ask'
if [ -z "$(guard 'cat .attest/ship-20260910-000000-abc1234.md')" ]; then ok "reading a record is not a write"; else fail "reading a record is not a write"; fi
# In-place editing is how a shell rewrites a file it already has — the shape that turns
# "1 blocker" into "0 blocker" without ever touching the Write tool (ADR-0054).
says "sed -i on a record asks"                   "$(guard 'sed -i s/1 blocker/0 blocker/ .attest/ship-a.md')" 'permissionDecision":"ask'
says "…and its long spelling"                    "$(guard 'sed --in-place s/1/0/ .attest/ship-a.md')" 'permissionDecision":"ask'
says "…and perl -pi"                             "$(guard 'perl -pi -e s/1/0/ .attest/ship-a.md')" 'permissionDecision":"ask'
says "…and truncate"                             "$(guard 'truncate -s 0 .attest/ship-a.md')" 'permissionDecision":"ask'
if [ -z "$(guard 'sed -n 1p .attest/ship-a.md')" ]; then ok "a non-editing sed is still a read"; else fail "a non-editing sed is still a read"; fi

# --- the publish path that never opens a shell (ADR-0055) ------------------------------
# A GitHub MCP server ships bytes over the API: `git push` is never typed, so the Bash matcher
# never fires and the gate the README advertises was simply absent there.
rm -f "$S"/.attest/ship-*.md "$S/.attest/tmp/ship-guard.log"
mguard() { # mguard <tool> [tool_input JSON body]
  echo "{\"tool_name\":\"$1\",\"tool_input\":{${2:-}}}" | CLAUDE_PROJECT_DIR="$S" sh "$GUARD"
}
says "an MCP push asks"            "$(mguard mcp__github__push_files)" 'permissionDecision":"ask'
says "an MCP pull request asks"    "$(mguard mcp__github__create_pull_request)" 'permissionDecision":"ask'
says "an MCP file write asks"      "$(mguard mcp__github__create_or_update_file)" 'permissionDecision":"ask'
says "…and creating a repository names publishing" \
  "$(mguard mcp__github__create_repository)" 'creates a repository'
# The matcher in settings.json IS the list for this arm, so anything wired to the hook asks —
# wire the publish tools, not the whole server.
says "any MCP tool wired to the guard asks" "$(mguard mcp__example__upload)" 'permissionDecision":"ask'
if [ -z "$(mguard Read '\"file_path\":\"README.md\"')" ]
  then ok "a non-Bash, non-MCP tool passes untouched"
  else fail "a non-Bash, non-MCP tool passes untouched"; fi
# The property that separates this arm from every other one: a record attests a TREE at a sha,
# and these calls send bytes chosen in the call, so a clean record is evidence about something
# else. It must not open the door.
printf -- '- HEAD: %s (main)\n- findings: 0 blocker\n' "$SHA" > "$S/.attest/ship-20260912-000000-$SHA.md"
if [ -z "$(guard 'git push origin main')" ]
  then ok "the clean record still clears a git push"
  else fail "the clean record still clears a git push"; fi
says "…but never clears an MCP push" "$(mguard mcp__github__push_files)" 'permissionDecision":"ask'
says "…and the prompt says why"      "$(mguard mcp__github__push_files)" 'No ship record can clear it'
rm -f "$S"/.attest/ship-*.md
# The payload carries file CONTENT, so anything the arms below read out of a command string can
# be smuggled in as a pushed file: a `--dry-run` in the text, or a quoted copy of the key the
# extraction looks for.
says "a --dry-run inside pushed content does not wave it through" \
  "$(mguard mcp__github__push_files '\"files\":[{\"path\":\"a\",\"content\":\"try git push --dry-run\"}]')" \
  'permissionDecision":"ask'
says "a pushed file quoting the tool_name key is still read as a push" \
  "$(mguard mcp__github__push_files '\"files\":[{\"path\":\"d\",\"content\":\"the key is tool_name : Bash here\"}]')" \
  'permissionDecision":"ask'
# The trace names the tool and nothing else. For Bash the subject is the command; here it would
# be the payload, i.e. the very bytes being shipped — a guard must not write a secret to disk.
rm -f "$S/.attest/tmp/ship-guard.log"
mguard mcp__github__push_files '\"files\":[{\"path\":\"a.env\",\"content\":\"AWS_SECRET=hunter2\"}]' >/dev/null
says "an MCP decision is traced"  "$(cat "$S/.attest/tmp/ship-guard.log" 2>/dev/null)" ' mcp '
says "…naming the tool"           "$(cat "$S/.attest/tmp/ship-guard.log" 2>/dev/null)" 'mcp__github__push_files'
says_not "…and never the content it was shipping" \
  "$(cat "$S/.attest/tmp/ship-guard.log" 2>/dev/null)" 'hunter2'
rm -f "$S/.attest/tmp/ship-guard.log"
# Wiring, not just behaviour: the hook can only judge a tool the matcher hands it.
for t in push_files create_or_update_file create_pull_request create_repository; do
  says "settings.json wires mcp__github__$t to the ship guard" \
    "$(cat "$KIT/.claude/settings.json")" "$t"
done

# --- every decision leaves exactly one line in the trace (ADR-0034 + ADR-0038) ---------
rm -f "$S/.attest/tmp/ship-guard.log" "$S"/.attest/ship-*.md
guard 'git push --dry-run' >/dev/null
says "a dry run is traced, not silent" "$(cat "$S/.attest/tmp/ship-guard.log" 2>/dev/null)" ' dryrun '
# ADR-0034 gave the log a line per decision because "did not fire" and "fired and was
# auto-approved" were indistinguishable; the mode is the other half of that answer (ADR-0050).
rm -f "$S/.attest/tmp/ship-guard.log"
echo '{"tool_name":"Bash","permission_mode":"bypassPermissions","tool_input":{"command":"git push origin main"}}' | CLAUDE_PROJECT_DIR="$S" sh "$GUARD" >/dev/null
says "the trace records the permission mode the call ran under" "$(cat "$S/.attest/tmp/ship-guard.log" 2>/dev/null)" 'bypassPermissions'
echo '{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}' | CLAUDE_PROJECT_DIR="$S" sh "$GUARD" >/dev/null
says "a payload without a mode still traces, with a dash" "$(tail -1 "$S/.attest/tmp/ship-guard.log" 2>/dev/null)" ' - git push'
rm -f "$S/.attest/tmp/ship-guard.log"
printf -- '- HEAD: %s (main)\n- findings: 1 blocker\n' "$SHA" > "$S/.attest/ship-20260904-000000-$SHA.md"
guard 'git push origin main' >/dev/null
says "a record that fails the check is traced as blocked, not as a bare ask" \
  "$(cat "$S/.attest/tmp/ship-guard.log" 2>/dev/null)" ' blocked '
lines=$(grep -c . "$S/.attest/tmp/ship-guard.log" 2>/dev/null || echo 0)
if [ "$lines" -eq 1 ]; then ok "one decision writes exactly one trace line"; else fail "one decision writes exactly one trace line (got $lines)"; fi
rm -f "$S/.attest/tmp/ship-guard.log" "$S"/.attest/ship-*.md

# A record for SOME other commit must not clear this one — the sha in the name is the check.
mkdir -p "$S/.attest"; : > "$S/.attest/ship-20260101-000000-deadbee.md"
says "a record for another commit does not clear the guard" "$(guard 'git push origin main')" 'permissionDecision":"ask'
printf -- '- HEAD: %s (main)\n- findings: 0 blocker\n' "$SHA" > "$S/.attest/ship-20260828-120000-$SHA.md"
if [ -z "$(guard 'git push origin main')" ]; then ok "a clean record for THIS commit clears the guard"; else fail "a clean record for THIS commit clears the guard"; fi
# Emitted JSON must be parseable — a malformed decision is worse than none. The command is
# deliberately hostile: quotes, backslashes and a substitution the guard must never expand.
rm -f "$S/.attest/ship-20260828-120000-$SHA.md"
# shellcheck disable=SC2016  # the literal $(x) is the point — it must reach the hook unexpanded
json="$(guard 'git push \"weird$(x)\" && echo done')"
# python3 here is the TEST's dependency, not the kit's — nothing installed by install.sh needs
# an interpreter beyond /bin/sh (ADR-0027). So its absence SKIPS this assertion; a kit that just
# dropped that dependency must not fail its own suite for lacking it.
if ! command -v python3 >/dev/null 2>&1; then
  ok "the ask payload is valid JSON (skipped: no python3 to parse it with)"
elif printf '%s' "$json" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; then
  ok "the ask payload is valid JSON even for a hostile command"
else
  fail "the ask payload is valid JSON even for a hostile command"
fi

# The audience boundary, and the one the guard deliberately does NOT hold (ADR-0035).
says "making the repo public asks"            "$(guard 'gh repo edit --visibility public')" 'permissionDecision":"ask'
says "…and the reason names reading, not sending" "$(guard 'gh repo edit --visibility public')" 'changes who can read this repository'
says "the other flag spelling asks too"       "$(guard 'gh repo edit --visibility=public')" 'permissionDecision":"ask'
# An over-match costs a prompt; an under-match costs the gate. Going private matches on purpose.
says "going private asks too, by design"      "$(guard 'gh repo edit --visibility private')" 'permissionDecision":"ask'
says "creating a repo from a local source asks" "$(guard 'gh repo create x --public --source=.')" 'permissionDecision":"ask'
# The two reasons must never be substituted for one another — a guard that cannot back its
# claim is the failure ADR-0034 ended.
says "a push still claims what a push does"   "$(guard 'git push origin main')" 'sends data off the machine'
# Pinned, not an oversight: by merge time the bytes are already on the remote, the merge commit
# does not exist yet, and most merges never touch this machine. Do not "fix" this assertion.
if [ -z "$(guard 'gh pr merge 4 --merge')" ]; then ok "a merge stays silent — a declared gap, not a miss"; else fail "a merge stays silent — a declared gap, not a miss"; fi

# --- 3b. the guard leaves a trace, so "did it fire" is a fact (ADR-0034) ---------------
echo "hooks — ship guard trace:"
G="$WORK/trace"; mkdir -p "$G"
git -C "$G" init -q .
git -C "$G" config user.email smoke@example.invalid
git -C "$G" config user.name smoke
: > "$G/f"; git -C "$G" add f; git -C "$G" commit -qm init
GSHA="$(git -C "$G" rev-parse --short HEAD)"
tguard() { echo "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$1\"}}" | CLAUDE_PROJECT_DIR="$G" sh "$GUARD"; }
LOG="$G/.attest/tmp/ship-guard.log"

tguard 'ls -la' >/dev/null
check "an unmatched command leaves no trace at all"  test ! -e "$LOG"
tguard 'git push origin main' >/dev/null
check "an ask is traced"                             test -f "$LOG"
says "…with its decision and the sha it judged"      "$(cat "$LOG")" "ask $GSHA"
check "the trace sits in the ignored scratch, not beside the records" test ! -e "$G/.attest/ship-guard.log"
# The pass is the case that looked like a dead hook, so it must be traced too.
printf -- '- HEAD: %s (main)\n- findings: 0 blocker\n' "$GSHA" > "$G/.attest/ship-20260831-000000-$GSHA.md"
tguard 'git push origin main' >/dev/null
says "a pass is traced too"                          "$(tail -1 "$LOG")" "pass $GSHA"
if [ "$(grep -c . "$LOG")" -eq 2 ]; then ok "one line per matched command, no more"; else fail "one line per matched command, no more"; fi
# Fail-open: a scratch it cannot write costs the line, never the decision.
rm -f "$G/.attest/ship-20260831-000000-$GSHA.md"
chmod 500 "$G/.attest/tmp"
says "an unwritable scratch still yields a decision" "$(tguard 'git push origin main')" 'permissionDecision":"ask'
chmod 700 "$G/.attest/tmp"

# --- 3b. line endings: a CRLF source must not install a CRLF hook (ADR-0039) -----------
echo "install.sh — CRLF:"
check "the kit ships .gitattributes pinning shell to LF" \
  sh -c "grep -Eq '^\*\.sh[[:space:]]+text eol=lf' '$KIT/.gitattributes'"
check "…covering the hooks directory too" \
  sh -c "grep -q 'claude/hooks' '$KIT/.gitattributes'"
CR="$WORK/crlfkit"; mkdir -p "$CR"
cp -r "$KIT/.claude" "$CR/"; cp "$KIT"/*.md "$KIT/install.sh" "$CR/"
# awk, not `sed 's/$/\r/'`: that is a GNU-ism — BSD/macOS sed inserts a literal `r`, the
# fixture then holds no CR at all, and the whole block would pass without testing anything.
for f in "$CR"/.claude/hooks/*.sh; do
  awk '{ printf "%s\r\n", $0 }' "$f" > "$f.crlf" && mv "$f.crlf" "$f"
done
if grep -q "$(printf '\r')" "$CR/.claude/hooks/ship_guard.sh"; then
  ok "the CRLF fixture really holds CR"
else
  fail "the CRLF fixture really holds CR"
fi
CRT="$WORK/crlftarget"; mkdir -p "$CRT"
"$CR/install.sh" "$CRT" >/dev/null 2>&1 || true
if grep -q "$(printf '\r')" "$CRT/.claude/hooks/ship_guard.sh" 2>/dev/null; then
  fail "a CRLF source installs an LF hook"
else
  ok "a CRLF source installs an LF hook"
fi
check "…and the installed hook is still valid shell" sh -n "$CRT/.claude/hooks/ship_guard.sh"
# An UPGRADE over an existing CRLF hook takes the other branch entirely, and used to call a
# whitespace-only difference "drift" with a "diff against …" most tools render as identical —
# for a file that exits 2 under dash and blocks every Bash call (attest ADR-0044). Both
# directions, because naming the CRLF case is worthless if a real edit stops reading as drift.
CRU="$WORK/crlfupgrade"; mkdir -p "$CRU"
"$KIT/install.sh" "$CRU" >/dev/null
sed -i.bak 's/$/\r/' "$CRU/.claude/hooks/ship_guard.sh" 2>/dev/null || \
  { tr -d '\r' < "$CRU/.claude/hooks/ship_guard.sh" | sed 's/$/\r/' > "$CRU/x" && mv "$CRU/x" "$CRU/.claude/hooks/ship_guard.sh"; }
rm -f "$CRU/.claude/hooks/ship_guard.sh.bak"
cru_out="$(run_install "$CRU")"
says "a CRLF-only copy is named, not called drift"  "$cru_out" 'LINE ENDINGS'
says_not "…and is not reported as ordinary drift"   "$cru_out" 'ship_guard.sh — yours kept, but it DIFFERS'
printf '\n# an edit of my own\n' >> "$CRU/.claude/hooks/session_declaration.sh"
cru_out2="$(run_install "$CRU")"
says "a real content edit still reads as drift"     "$cru_out2" 'session_declaration.sh — yours kept, but it DIFFERS'
# ...and the adopter's own next checkout must not undo it (ADR-0039)
GA="$WORK/gitattr"; mkdir -p "$GA"
"$KIT/install.sh" "$GA" >/dev/null
check "the LF attribute lands in the target"        grep -q 'text eol=lf' "$GA/.gitattributes"
check "…scoped to the kit's own hooks"              grep -q 'claude/hooks' "$GA/.gitattributes"
"$KIT/install.sh" "$GA" >/dev/null
# `|| echo 0`: grep -c exits 1 on zero matches, and under `set -e` that ends the run — which
# once cost this suite 75 of its assertions, silently, including the regression test for a
# destructive bug. Every count in this file is guarded for that reason.
# The installer lands two attributes now — the hooks (ADR-0039) and the records the guard
# parses byte-exactly (ADR-0037). Count each ONE, not the total: a total is the assertion that
# breaks every time the kit legitimately pins one more path, which teaches the reader to raise
# the number rather than ask why it moved.
ga_hooks=$(grep -c '^\.claude/hooks/\*' "$GA/.gitattributes" 2>/dev/null || echo 0)
ga_recs=$(grep -c '^\.attest/\*\.md' "$GA/.gitattributes" 2>/dev/null || echo 0)
if [ "$ga_hooks" -eq 1 ] && [ "$ga_recs" -eq 1 ]; then ok "a re-run duplicates neither attribute line"; else fail "a re-run duplicates neither attribute line (hooks=$ga_hooks records=$ga_recs)"; fi
check "the blanket *.sh rule is NOT written into your repo" \
  sh -c "! grep -qE '^[*][.]sh' '$GA/.gitattributes'"
# A pattern the adopter already decided about is left alone — globs are not regexes, and
# treating them as one is what duplicated these lines in the first draft.
GA2="$WORK/gitattr-own"; mkdir -p "$GA2"; printf '*.sh text=auto\n' > "$GA2/.gitattributes"
"$KIT/install.sh" "$GA2" >/dev/null
check "an existing *.sh rule of yours is not overruled" grep -qx '\*.sh text=auto' "$GA2/.gitattributes"
own_sh=$(grep -c '^\*\.sh' "$GA2/.gitattributes" 2>/dev/null || echo 0)
if [ "$own_sh" -eq 1 ]; then ok "…and nothing is appended under it"; else fail "…and nothing is appended under it ($own_sh)"; fi
check "…while the hooks pattern still lands"        grep -q 'claude/hooks' "$GA2/.gitattributes"

# --- 4. fresh install, then a re-run that must change nothing --------------------------
echo "install.sh — idempotency:"
T1="$WORK/fresh"; mkdir -p "$T1"
"$KIT/install.sh" "$T1" >/dev/null
check "fresh install lands the shared ladder" test -f "$T1/.claude/skills/_shared/audit-ladder.md"
check "fresh install lands /gate"             test -f "$T1/.claude/skills/gate/SKILL.md"
check "fresh install lands the ship guard"   test -f "$T1/.claude/hooks/ship_guard.sh"
check "fresh install lands the declaration hook" test -f "$T1/.claude/hooks/session_declaration.sh"
check "fresh install lands the settings that wire them" test -f "$T1/.claude/settings.json"
check "nothing at all lands under .github/" test ! -e "$T1/.github"
check "attest's own README does not land"   test ! -e "$T1/README.md"
check "attest's own LICENSE does not land"  test ! -e "$T1/LICENSE"
# The skill set is enumerated from the kit, not hardcoded: a skill added upstream must install.
mkdir -p "$WORK/kit-extra"; cp -r "$KIT/.claude" "$KIT"/*.md "$KIT/install.sh" "$WORK/kit-extra/"
mkdir -p "$WORK/kit-extra/.claude/skills/newthing"; echo '# new' > "$WORK/kit-extra/.claude/skills/newthing/SKILL.md"
T1b="$WORK/fresh-extra"; mkdir -p "$T1b"
extra_out=$("$WORK/kit-extra/install.sh" "$T1b" 2>&1 || true)
check "a skill added to the kit installs without an edit to install.sh" test -f "$T1b/.claude/skills/newthing/SKILL.md"
says  "…and shows up in the command list" "$extra_out" '/newthing'
rerun_out=$(run_install "$T1")
says     "a re-run says it changed nothing, in one line" "$rerun_out" 'changed nothing'
says_not "…without listing every group again"            "$rerun_out" 'Documents'
check "second run minted no attest-GUIDE.md" test ! -e "$T1/attest-GUIDE.md"
says_not "re-run does not false-warn about unwired hooks" "$rerun_out" 'NOT wired'
# A locally modified kit-owned file must be called out as drift, not skipped silently
echo '# local modification' >> "$T1/.claude/skills/gate/SKILL.md"
drift_out=$(run_install "$T1")
says "a drifted kit file is called out as DIFFERS" "$drift_out" 'gate/SKILL.md — yours kept, but it DIFFERS'
says "…under a heading that says nothing was overwritten" "$drift_out" 'NEEDS YOU'

# --- 4b. an abort mid-run must still account for what landed ---------------------------
echo "install.sh — partial install:"
TP="$WORK/partial"; mkdir -p "$TP"; touch "$TP/.claude"   # a file where a directory must go
partial_out=$(run_install "$TP")
says "an aborted install says it is PARTIAL"        "$partial_out" 'ABORTED'
says "an aborted install lists what already landed" "$partial_out" '+ CLAUDE.md'
if "$KIT/install.sh" "$TP" >/dev/null 2>&1; then
  fail "an aborted install exits non-zero"
else
  ok "an aborted install exits non-zero"
fi

# --- 4c. the self-install guard covers ancestry, not just equality ---------------------
# Ancestry is exercised against a COPY of the kit inside $WORK, never the real checkout's
# parent: if a guard ever regresses, a passing-by-accident test must not install the kit
# into someone's actual projects directory.
echo "install.sh — self-install guard:"
ANC="$WORK/anc"; mkdir -p "$ANC"
cp -r "$KIT/.claude" "$ANC/kit-copy" 2>/dev/null || true
mkdir -p "$ANC/kit-copy"; cp "$KIT/install.sh" "$KIT"/*.md "$ANC/kit-copy/"
for bad in "$ANC/kit-copy" "$ANC/kit-copy/docs" "$ANC"; do
  mkdir -p "$bad"
  label="the kit itself"
  [ "$bad" = "$ANC/kit-copy/docs" ] && label="a directory inside the kit"
  [ "$bad" = "$ANC" ] && label="a directory containing the kit"
  if "$ANC/kit-copy/install.sh" "$bad" >/dev/null 2>&1; then
    fail "refuses to install into $label"
  else
    ok "refuses to install into $label"
  fi
done
# TARGET=/ is asserted by MESSAGE, not by exit code: an unguarded run aborts on EACCES and
# would pass an exit-code test for entirely the wrong reason.
says "refuses TARGET=/ as an ancestor of the kit" "$(run_install /)" \
  'refusing to install the kit into a directory that contains it'
says "rejects an unknown option rather than treating it as a path" "$(run_install --nope "$WORK/fresh")" \
  'unknown option'

# --- 5. a .gitignore without a trailing newline survives intact ------------------------
echo "install.sh — .gitignore:"
T2="$WORK/nonl"; mkdir -p "$T2"
printf 'node_modules' > "$T2/.gitignore"
"$KIT/install.sh" "$T2" >/dev/null
check "user's rule kept as its own line"  grep -qx 'node_modules' "$T2/.gitignore"
check "kit's ignore line landed whole"    grep -qx '.claude/settings.local.json' "$T2/.gitignore"

# --- 6. junk in the kit tree never installs --------------------------------------------
echo "install.sh — junk filter:"
K2="$WORK/kitcopy"; mkdir -p "$K2"
cp -r "$KIT/.claude" "$K2/"; cp "$KIT"/*.md "$K2/" 2>/dev/null || true
cp "$KIT/install.sh" "$K2/"
mkdir -p "$K2/.claude/hooks/__pycache__"
touch "$K2/.claude/hooks/__pycache__/x.pyc" "$K2/.claude/hooks/.DS_Store" \
      "$K2/.claude/skills/x.swp" "$K2/.claude/skills/y~"
T3="$WORK/junk"; mkdir -p "$T3"
"$K2/install.sh" "$T3" >/dev/null
found=$(find "$T3" \( -name '*.pyc' -o -name '.DS_Store' -o -name '*.swp' -o -name '*~' \) | wc -l)
if [ "$found" -eq 0 ]; then ok "no junk landed"; else fail "no junk landed ($found found)"; fi
# ...and the filter did not achieve that by installing nothing at all
check "the legitimate kit files still landed" test -f "$T3/.claude/skills/gate/SKILL.md"

# --- 7. an existing settings.json: warn only when a hook is really unwired -------------
echo "install.sh — inert hooks warning:"
T4="$WORK/settings"; mkdir -p "$T4/.claude"
echo '{}' > "$T4/.claude/settings.json"
settings_out=$(run_install "$T4")
says "warning printed when settings.json registers no hooks" "$settings_out" 'NOT wired'
# ...and the same file must not also appear as "untouched": one file, one framing (ADR-0031)
says_not "an unwired settings.json is not also listed as untouched" \
  "$(printf '%s' "$settings_out" | sed -n '/YOURS, UNTOUCHED/,/NEEDS YOU/p')" 'settings.json'
# A settings.json that differs from the kit's but registers every guard HAS them wired —
# the categorical warning would be false (an older kit stanza is the common case).
T4b="$WORK/settings-wired"; mkdir -p "$T4b/.claude"
sed '1a\
  "_note": "an older kit stanza",' "$KIT/.claude/settings.json" > "$T4b/.claude/settings.json"
wired_out=$(run_install "$T4b")
says_not "no false unwired warning when every guard is registered" "$wired_out" 'NOT wired'
says     "a differing but wired settings.json is reported as such" "$wired_out" 'registers every'
# ...but naming every hook FILE is not the same as wiring every guard (attest ADR-0055). A
# stanza written before the ship guard's second registration names ship_guard.sh and still
# leaves the non-shell publish path ungated; reporting that as wired is the false assurance.
T4c="$WORK/settings-bash-only"; mkdir -p "$T4c/.claude"
grep -v 'mcp__github__' "$KIT/.claude/settings.json" > "$T4c/.claude/settings.json"
for h in session_declaration ship_guard record_guard; do
  says "the fixture really names $h, so this is not a filename miss" \
    "$(cat "$T4c/.claude/settings.json")" "$h"
done
bashonly_out=$(run_install "$T4c")
says "a Bash-only ship guard is not reported as fully wired" "$bashonly_out" 'NOT wired'
says_not "…and is not reported as wired either" "$bashonly_out" 'registers every'

# --- 8. compliance is opt-in, and adding it later is just a re-run ---------------------
echo "install.sh — compliance opt-in:"
T5="$WORK/optin"; mkdir -p "$T5"
optin_out=$(run_install "$T5")
check "no COMPLIANCE.md by default"       test ! -e "$T5/COMPLIANCE.md"
check "no /compliance skill by default"   test ! -e "$T5/.claude/skills/compliance/SKILL.md"
says  "the report says why it is absent"  "$optin_out" 'compliance — not installed'
for d in CLAUDE.md PROGRESS.md BUSINESS.md DECISIONS.md; do
  check "the non-optional document $d is there" test -f "$T5/$d"
done
later_out=$(run_install --compliance "$T5")
check "--compliance on a re-run adds the document" test -f "$T5/COMPLIANCE.md"
check "…and the skill"                             test -f "$T5/.claude/skills/compliance/SKILL.md"
says  "…and the command is listed"                 "$later_out" 'Commands.*/compliance'
says_not "…without dragging anything into NEEDS YOU" "$later_out" 'NEEDS YOU'
check "a re-run without the flag does not remove it" test -f "$T5/COMPLIANCE.md"
T5b="$WORK/optin-first"; mkdir -p "$T5b"
run_install --compliance "$T5b" >/dev/null
check "the flag works on a first install too" test -f "$T5b/.claude/skills/compliance/SKILL.md"

# --- 9. GUIDE.md collision: the kit's manual lands beside yours, and says when it is stale
echo "install.sh — GUIDE collision:"
T9="$WORK/ownguide"; mkdir -p "$T9"; echo '# my own guide' > "$T9/GUIDE.md"
guide_out=$(run_install "$T9")
check "your own GUIDE.md is untouched"  grep -qx '# my own guide' "$T9/GUIDE.md"
check "the kit's manual lands beside it" test -f "$T9/attest-GUIDE.md"
says  "the NEXT steps point at the file the manual is actually in" "$guide_out" 'attest-GUIDE.md PART 9'
# The commonest upgrade path: the target's GUIDE.md is the kit's own, from an older version.
T9b="$WORK/staleguide"; mkdir -p "$T9b"
{ echo '# GUIDE.md — reference guide'; echo 'old copy'; } > "$T9b/GUIDE.md"
says "an outdated kit GUIDE.md is pointed out, never overwritten" "$(run_install "$T9b")" 'GUIDE.md — an older kit version'
check "…and it is left exactly as it was" grep -qx 'old copy' "$T9b/GUIDE.md"
echo '# stale' >> "$T9/attest-GUIDE.md"
says "a stale attest-GUIDE.md gets the refresh hint" "$(run_install "$T9")" 'attest-GUIDE.md — an older kit version'

# --- 10. template-cleanup removes attest's files and nothing of yours ------------------
echo "template-cleanup:"
GEN="$WORK/generated"; mkdir -p "$GEN"
cp -r "$KIT/.claude" "$GEN/"; cp "$KIT"/*.md "$GEN/"; cp "$KIT/install.sh" "$GEN/"
# Dotfiles too: `cp "$KIT"/*.md` does not glob them, but the template button copies the whole
# tree — which is exactly how a blanket `*.sh` rule reached adopters unseen (attest ADR-0043).
cp "$KIT/.gitattributes" "$GEN/" 2>/dev/null || true
# ...and a line of the adopter's own, added under the kit's header the way a late run would find
printf '*.md diff=markdown\n' >> "$GEN/.gitattributes"
cp "$KIT/LICENSE" "$GEN/"; mkdir -p "$GEN/docs" "$GEN/scripts" "$GEN/.github/workflows"
cp "$KIT"/docs/*.md "$GEN/docs/"; cp "$KIT/scripts/smoke.sh" "$KIT/scripts/template-cleanup.sh" "$GEN/scripts/"
# attest's own audit records: the generated repo must not inherit them (ADR-0041)
mkdir -p "$GEN/.attest"; cp "$KIT"/.attest/*.md "$GEN/.attest/" 2>/dev/null || true
gen_before=$( { find "$GEN/.attest" -maxdepth 1 -name '*-*.md' 2>/dev/null || true; } | wc -l )
# The fixture must be a REAL repository with its own history: the discriminator is whether the
# sha in a record's name resolves here, and outside a repo `git cat-file` fails for every
# record alike — so a non-repo fixture would assert the right outcome through the wrong path,
# which is how the first version of this shipped a destructive bug past a green suite
# (attest ADR-0041).
git -C "$GEN" init -q .
git -C "$GEN" config user.email adopter@example.invalid
git -C "$GEN" config user.name adopter
git -C "$GEN" add -A >/dev/null 2>&1 || true
git -C "$GEN" commit -qm "the adopter's own first commit" >/dev/null 2>&1 || true
GEN_SHA="$(git -C "$GEN" rev-parse --short HEAD 2>/dev/null || echo unknown)"
printf -- '# my own scan\n- kit: 0.5.0\n- HEAD: %s (main)\n- findings: 0 blocker\n' "$GEN_SHA" \
  > "$GEN/.attest/ship-20260904-100000-$GEN_SHA.md"
# Names the kit never writes are the adopter's by construction. Feeding "notes" or "rerun" to
# `git cat-file` merely fails, which under a delete-on-failure rule takes them (attest ADR-0041).
for own in gate-notes.md gate-2026-09-05-pre-release.md "ship-20260904-100000-$GEN_SHA-rerun.md"; do
  printf -- '- kit: 0.5.0\n- a note of my own\n' > "$GEN/.attest/$own"
done
cp "$KIT/.github/workflows/ci.yml" "$GEN/.github/workflows/"
cp "$KIT/METHOD.md" "$GEN/"
# what the user added before the workflow ever ran
echo 'my notes' > "$GEN/docs/design.md"; echo 'echo deploy' > "$GEN/scripts/deploy.sh"
(cd "$GEN" && bash scripts/template-cleanup.sh >/dev/null)
check "attest's own docs are gone"        test ! -e "$GEN/docs/attest-devlog.md"
check "attest's installer is gone"        test ! -e "$GEN/install.sh"
check "attest's own CI is gone"           test ! -e "$GEN/.github/workflows/ci.yml"
check "attest's METHOD.md is gone"        test ! -e "$GEN/METHOD.md"
# The kit needs a blanket `*.sh` pin for its OWN shell; your repo must never inherit it, or the
# kit is editing your code through a rule you never wrote (attest ADR-0043).
check "the blanket *.sh pin does not survive into your repo" \
  sh -c "! grep -qE '^[*][.]sh' '$GEN/.gitattributes'"
check "…while the kit's own hooks stay pinned"  grep -q 'claude/hooks' "$GEN/.gitattributes"
# The narrowing must not take the OTHER kit-scoped pin with it: the guard parses a record
# byte-exactly, so losing this on the template path hands back the CRLF misdiagnosis ADR-0044
# closed on the installer path (attest ADR-0043).
check "…and so does the record pin the guard needs" grep -q '^[.]attest/[*][.]md' "$GEN/.gitattributes"
# Surgical, not a rewrite: a line the adopter added under attest's header survives a late run.
check "a line of your own in .gitattributes survives" grep -q '^\*[.]md diff=markdown' "$GEN/.gitattributes"
check "YOUR docs survive"                 test -f "$GEN/docs/design.md"
check "YOUR scripts survive"              test -f "$GEN/scripts/deploy.sh"
check "the kit itself is left in place"   test -f "$GEN/.claude/skills/gate/SKILL.md"
check "the declaration hook is left in place" test -f "$GEN/.claude/hooks/session_declaration.sh"
check "the ship guard is left in place"      test -f "$GEN/.claude/hooks/ship_guard.sh"
# The template path keeps compliance on purpose: a generated repo has no install.sh to re-run,
# so removing it would be the one state a user cannot undo. /business closes the gap instead.
check "compliance is left for /business to rule on" test -f "$GEN/COMPLIANCE.md"
# attest's own audit records are attest's history, not the generated repo's (ADR-0041)
if [ "${gen_before:-0}" -gt 0 ]; then ok "the fixture really carried attest's records ($gen_before)"; else fail "the fixture really carried attest's records"; fi
# `|| true` inside the group: the suite runs under `set -o pipefail`, and after a clean sweep
# the directory itself is gone, so find exits non-zero and would take the whole run with it.
# Attest's records name attest's commits, which do not exist here; the adopter's names one that
# does. Both halves are asserted — "all gone" alone would pass on a script that deletes blindly.
# Count by exclusion of the adopter's known fixtures, not by sha: two of them deliberately
# carry no sha at all, which is the property under test.
OWN_RECORDS="ship-20260904-100000-$GEN_SHA.md gate-notes.md gate-2026-09-05-pre-release.md ship-20260904-100000-$GEN_SHA-rerun.md"
att_left=0
for f in $( { find "$GEN/.attest" -maxdepth 1 -name '*-*.md' 2>/dev/null || true; } ); do
  case " $OWN_RECORDS " in *" $(basename "$f") "*) continue ;; esac
  att_left=$((att_left + 1))
done
if [ "$att_left" -eq 0 ]; then ok "attest's own .attest records are gone"; else fail "attest's own .attest records are gone ($att_left left)"; fi
check "the adopter's own record survives the sweep" test -f "$GEN/.attest/ship-20260904-100000-$GEN_SHA.md"
for own in gate-notes.md gate-2026-09-05-pre-release.md "ship-20260904-100000-$GEN_SHA-rerun.md"; do
  check "…and so does $own — its tail is not a sha" test -f "$GEN/.attest/$own"
done
# ...and in a SHALLOW clone git answers about HEAD and nothing else. `actions/checkout`
# defaults to `fetch-depth: 1`, and a record names the commit it gated — an ANCESTOR of HEAD by
# ADR-0033, never HEAD itself. So every one of the adopter's records fails to resolve and the
# sweep would take all of them, unattended, with a write token. The fixture above cannot see
# this: it has a single commit, so its record names HEAD (attest ADR-0042).
SHAL="$WORK/shallow-src"; mkdir -p "$SHAL/.attest" "$SHAL/scripts"
cp "$KIT/install.sh" "$SHAL/"; cp "$KIT/scripts/template-cleanup.sh" "$SHAL/scripts/"
cp "$KIT/README.md" "$KIT/LICENSE" "$SHAL/" 2>/dev/null || true
git -C "$SHAL" init -q .
git -C "$SHAL" config user.email adopter@example.invalid
git -C "$SHAL" config user.name adopter
echo one > "$SHAL/f1"; git -C "$SHAL" add -A >/dev/null 2>&1; git -C "$SHAL" commit -qm first >/dev/null 2>&1
SHAL_SHA="$(git -C "$SHAL" rev-parse --short HEAD 2>/dev/null || echo unknown)"
# the adopter's own record, naming the commit it gated — which the next commit makes an ancestor
printf -- '# my own scan\n- kit: 0.5.0\n- HEAD: %s (main)\n- findings: 0 blocker\n' "$SHAL_SHA" \
  > "$SHAL/.attest/ship-20260904-100000-$SHAL_SHA.md"
cp "$KIT"/.attest/gate-*.md "$SHAL/.attest/" 2>/dev/null || true
echo two > "$SHAL/f2"; git -C "$SHAL" add -A >/dev/null 2>&1; git -C "$SHAL" commit -qm second >/dev/null 2>&1
for mode in full shallow; do
  CL="$WORK/clone-$mode"; rm -rf "$CL"
  if [ "$mode" = full ]; then
    git clone -q "file://$SHAL" "$CL" 2>/dev/null || true
  else
    git clone -q --depth 1 "file://$SHAL" "$CL" 2>/dev/null || true
  fi
  # NOT `ok`: a pass for a fixture that never ran is how a suite goes green over a destructive
  # bug, which the comment above the counts already records costing this file 75 assertions.
  if [ ! -d "$CL/.attest" ]; then fail "clone fixture built ($mode) — it did not"; continue; fi
  (cd "$CL" && bash scripts/template-cleanup.sh >/dev/null 2>&1) || true
  mine="$CL/.attest/ship-20260904-100000-$SHAL_SHA.md"
  theirs=$( { find "$CL/.attest" -maxdepth 1 -name 'gate-*.md' 2>/dev/null || true; } | wc -l )
  if [ "$mode" = shallow ]; then
    # git cannot tell whose record is whose here, so it must take nothing — not even attest's
    if [ -f "$mine" ] && [ "$theirs" -gt 0 ]; then
      ok "a shallow clone keeps every record, yours and the kit's alike"
    else
      fail "a shallow clone keeps every record (mine=$([ -f "$mine" ] && echo yes || echo GONE) kit=$theirs)"
    fi
  else
    # ...and with the full history the sweep still does the job it exists for
    if [ -f "$mine" ] && [ "$theirs" -eq 0 ]; then
      ok "a full clone still sweeps the kit's records and keeps your ancestor-named one"
    else
      fail "a full clone sweeps correctly (mine=$([ -f "$mine" ] && echo yes || echo GONE) kit=$theirs)"
    fi
  fi
done

# ...and outside a repository the sweep must remove nothing at all
NOGIT="$WORK/nogit"; mkdir -p "$NOGIT/.attest" "$NOGIT/scripts"
cp "$KIT/install.sh" "$NOGIT/"; cp "$KIT/scripts/template-cleanup.sh" "$NOGIT/scripts/"
cp "$KIT"/.attest/*.md "$NOGIT/.attest/" 2>/dev/null || true
: > "$NOGIT/.attest/ship-20260904-000000-cafebabe.md"
n_before=$( { find "$NOGIT/.attest" -maxdepth 1 -name '*-*.md' 2>/dev/null || true; } | wc -l )
(cd "$NOGIT" && bash scripts/template-cleanup.sh >/dev/null 2>&1) || true
n_after=$( { find "$NOGIT/.attest" -maxdepth 1 -name '*-*.md' 2>/dev/null || true; } | wc -l )
if [ "$n_before" -eq "$n_after" ] && [ "$n_before" -gt 0 ]; then
  ok "outside a git checkout the sweep removes nothing ($n_before kept)"
else
  fail "outside a git checkout the sweep removes nothing ($n_before -> $n_after)"
fi
# Assert the SHAPE, not a domain allowlist: a hard-coded list passes any other domain and any
# third party's address, and writing the maintainer's domain here would add the very kind of
# in-content occurrence this series removed. `.invalid` is reserved by RFC 2606 and is what the
# fixtures use, so it is the only exemption.
# `|| true` on both greps: under `set -o pipefail` a grep that finds nothing exits 1, and
# finding nothing is the passing case here.
stray=$( { grep -rhoE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$GEN" 2>/dev/null || true; } |
  { grep -vE '@(example|test|invalid)\.|\.invalid$|@noreply\.' || true; } | sort -u | head -5)
if [ -z "$stray" ]; then
  ok "no real address survives anywhere in the generated repo"
else
  fail "no real address survives anywhere in the generated repo (found: $stray)"
fi
check "attest's LICENSE became a skeleton" grep -q '<YEAR>' "$GEN/LICENSE"
check "attest's README became a stub"      grep -q '^# <your project>' "$GEN/README.md"
# Files of your own that happen to carry attest's names must survive too.
GEN2="$WORK/generated-own-license"; cp -r "$GEN" "$GEN2"
cp "$KIT/install.sh" "$GEN2/"; cp "$KIT/README.md" "$GEN2/"
echo 'Apache-2.0 — mine' > "$GEN2/LICENSE"
mkdir -p "$GEN2/scripts" "$GEN2/.github/workflows"
echo 'name: my ci' > "$GEN2/.github/workflows/ci.yml"
echo '# my own smoke test' > "$GEN2/scripts/smoke.sh"
(cd "$GEN2" && bash scripts/template-cleanup.sh >/dev/null)
check "YOUR LICENSE is never overwritten"  grep -qx 'Apache-2.0 — mine' "$GEN2/LICENSE"
check "YOUR ci.yml survives"               grep -qx 'name: my ci' "$GEN2/.github/workflows/ci.yml"
check "YOUR smoke.sh survives"             grep -qx '# my own smoke test' "$GEN2/scripts/smoke.sh"
# And an already-cleaned repo is a no-op, not an error
GEN3="$WORK/generated-clean"; mkdir -p "$GEN3"
cp "$KIT/scripts/template-cleanup.sh" "$GEN3/"; echo '# my project' > "$GEN3/README.md"
if (cd "$GEN3" && bash template-cleanup.sh >/dev/null) && [ -f "$GEN3/README.md" ]; then
  ok "an already-cleaned repo is a no-op"
else
  fail "an already-cleaned repo is a no-op"
fi

# --- verdict ---------------------------------------------------------------------------
echo
echo "smoke: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
