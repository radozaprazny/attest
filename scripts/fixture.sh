#!/usr/bin/env bash
# fixture.sh — build the planted /gate fixture of issue #34 and print its repo path. A pushed
# commit declares a non-goal and two decisions; 4 faults follow (answer key: fixture-key.md).
# Writes only under mktemp -d. Installs attest from this checkout, untracked; --no-kit skips it.
set -euo pipefail
KIT="$(cd "$(dirname "$0")/.." && pwd -P)"; T="$(mktemp -d)"; R="$T/tasks"
git init -q --bare "$T/remote.git"; git init -q -b main "$R"; cd "$R"
git config user.name 'Fixture Author'; git config user.email fixture@example.invalid
git remote add origin "$T/remote.git"; mkdir app
printf '%s\n' '# BUSINESS.md — tasks' '' '## Purpose' \
  'A single-user command-line to-do list that keeps its tasks in one local JSON file.' '' \
  '## Non-goals' '- No network calls from the CLI: a task never leaves the machine.' \
  '- No accounts and no multi-user sync.' '' '## Regulated' \
  "Not in itself: tasks are the user's own notes, stored only on their machine." > BUSINESS.md
printf '%s\n' '# DECISIONS.md — tasks' '' '## 2026-09-01 — Keep tasks in one local JSON file' \
  'No server and no schema. SQLite was the alternative; a short list gains nothing from it.' '' \
  '## 2026-09-02 — Parse arguments with argparse' \
  'The standard library covers one command; click was the alternative.' > DECISIONS.md
printf '# runtime dependencies, one per line\n' > requirements.txt
cat > app/store.py <<'EOF'
import json, pathlib
FILE = pathlib.Path.home() / ".tasks.json"
def load():
    return json.loads(FILE.read_text()) if FILE.exists() else []
def add(text):
    FILE.write_text(json.dumps(load() + [text]))
EOF
cat > app/cli.py <<'EOF'
import argparse
from app.store import add, load
def main():
    parser = argparse.ArgumentParser(prog="tasks")
    parser.add_argument("text", nargs="*")
    words = parser.parse_args().text
    if words:
        add(" ".join(words))
    for i, t in enumerate(load(), 1):
        print(f"{i}. {t}")
EOF
git add -A; git commit -qm 'feat: a local to-do list'; git push -q origin main 2>/dev/null
edit() { awk "$1" app/cli.py > app/cli.tmp && mv app/cli.tmp app/cli.py; }
# (a) a credential-shaped secret in an unpushed commit, built here so this file holds no literal.
printf '# FAKE credential, planted by attest scripts/fixture.sh (issue #34)\nRELEASE_TOKEN = "%s"\n' \
  "ghp_$(printf 'attest fixture 34' | git hash-object --stdin | cut -c1-36)" > app/settings.py
git add app/settings.py; git commit -qm 'chore: release settings'
# (c) a new dependency that DECISIONS.md does not record, in a second unpushed commit.
echo 'rich==13.7.1' >> requirements.txt; edit '{ print } /^import argparse$/ { print "from rich import print" }'
git commit -qam 'feat: coloured task list'
# (d) an uncommitted change that breaks the non-goal "No network calls from the CLI".
edit '/^    for i, t in/ { print "    report_usage(len(load()))" } { print }'
printf '%s\n' 'def report_usage(n):' '    import json, urllib.request' '    body = json.dumps({"tasks": n}).encode()' \
  '    urllib.request.urlopen("https://telemetry.example.com/v1/usage", data=body, timeout=2)' >> app/cli.py
# (b) an untracked data file with a rodné číslo column: mod-11 shaped values, computed here.
{ echo 'id,rodné číslo,okres'; i=0
  for d in 900101 856212 791130; do b=$((d * 1000 + 417)); c=$(((11 - b * 10 % 11) % 11 % 10))
    i=$((i + 1)); printf '%d,%d/417%d,Bratislava\n' "$i" "$d" "$c"; done; } > 'ünï data.csv'
[ "${1:-}" = --no-kit ] || "$KIT/install.sh" "$R" >/dev/null
echo "$R"
