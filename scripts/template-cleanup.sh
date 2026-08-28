#!/usr/bin/env bash
# template-cleanup.sh — strip attest's own identity from a repo generated with the template
# button, leaving the kit itself (the five documents, .claude/, GUIDE.md) in place. Run once
# from the repo root by .github/workflows/template-cleanup.yml, which deletes this script and
# itself afterwards. Not part of the kit: install.sh never copies scripts/.
#
# Every act that could destroy something of yours is guarded by a content check ON ITS OWN
# TARGET; attest's own uniquely-named files (docs/attest-*.md, install.sh) ride the single
# installer sentinel above them. The guards matter because this can run
# late — repo-creation pushes do not reliably fire — by which point the repo already holds
# YOUR docs/, YOUR scripts/ and YOUR LICENSE. So attest's files go by name, never a directory
# wholesale, and README/LICENSE are rewritten only while they are still attest's own
# (attest ADR-0022). Recoverable either way: the workflow pushes an ordinary commit, never a
# history rewrite.

set -euo pipefail

# The identity marker is attest's installer, by content — NOT the README. Replacing the
# README first is a normal first step and must never be what disables the cleanup.
if [ ! -f install.sh ] || ! grep -q '^# install.sh — install the attest kit into a project' install.sh; then
  echo "template-cleanup: no attest installer here — nothing of attest's left to remove."
  exit 0
fi

echo "template-cleanup: removing attest's own files"
rm -f docs/attest-decisions.md docs/attest-progress.md docs/attest-devlog.md install.sh

# smoke.sh and ci.yml are generic names — ci.yml is what you are most likely to write first.
# So they go only if they are still attest's own, by content. Leaving one behind costs
# nothing: attest's ci.yml is guarded to attest's repo name and never runs anywhere else.
if grep -q "^# smoke.sh — attest's own smoke test" scripts/smoke.sh 2>/dev/null; then
  rm -f scripts/smoke.sh
fi
if grep -q "^# ci.yml — attest's OWN gate" .github/workflows/ci.yml 2>/dev/null; then
  rm -f .github/workflows/ci.yml
fi
# rmdir, never rm -rf: a directory that still holds files of yours is left exactly as it is.
rmdir docs 2>/dev/null || true

if grep -q '^# attest — a compliance-native kit' README.md 2>/dev/null; then
  echo "template-cleanup: replacing attest's README with a bootstrap stub"
  # The heredoc body sits at column 0 on purpose — it is the file's content, not shell.
  cat > README.md <<'EOF'
# <your project>

Bootstrapped from the [attest](https://github.com/radozaprazny/attest) kit —
five living documents plus audit-gate skills that keep the project honest to
what it declares.

First steps (the kit's README calls this "First 5 minutes"):

1. Replace this file with your project's README.
2. Fill `LICENSE` (`<YEAR>`, `<YOUR NAME>`) — the cleanup left you an MIT skeleton.
3. Fill `CLAUDE.md` (`/init` is the fastest way), restart Claude Code.
4. Declare: `/business` · `/decision` as you choose · `/compliance` if in scope.
5. Not in regulated scope? Delete `COMPLIANCE.md` and `.claude/skills/compliance/` —
   `/business` will tell you which way this project goes. An empty posture file reads
   as "declared" to every later audit.
6. Everything else: `GUIDE.md` PART 9.
EOF
else
  echo "template-cleanup: README.md is no longer attest's — left untouched"
fi

if grep -q '^Copyright (c) 2026 Rado' LICENSE 2>/dev/null; then
  echo "template-cleanup: replacing attest's LICENSE with an MIT skeleton"
  cat > LICENSE <<'EOF'
MIT License

Copyright (c) <YEAR> <YOUR NAME>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
else
  echo "template-cleanup: LICENSE is no longer attest's — left untouched"
fi

# COMPLIANCE.md and .claude/skills/compliance/ are deliberately LEFT here, even though
# install.sh does not ship them without --compliance (ADR-0030). The two paths disagree on
# purpose: a generated repo has no install.sh to re-run, so removing them would be the one
# state a user cannot get out of without going back to the kit. /business closes the gap from
# the other side — it tells you to delete them when the archetype says out of scope.

echo "template-cleanup: done"
