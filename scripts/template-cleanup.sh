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

# .gitattributes — narrow it to what the kit is entitled to pin.
#
# attest's own copy carries a blanket `*.sh text eol=lf`, which it needs: its installer, its
# smoke suite and its hooks are all shell, and ADR-0039 exists because a CRLF hook exits 2 and
# BLOCKS every Bash call. But this file is tracked, so the template button copies it whole —
# and in YOUR repo that line normalises every `.sh` you will ever write, under a rule the kit
# put there. That is the non-goal in README §"Not a kitchen sink": nothing the kit installs
# edits your code. `install.sh` was narrowed to `.claude/hooks/*` for exactly this reason;
# the template path was not, until now (attest ADR-0043).
#
# Guarded by attest's own header comment, like README and LICENSE: once the file is yours, it
# is never touched.
#
# SURGICAL, not a rewrite. An earlier draft emitted a fresh two-line file, which was wrong
# twice: it dropped the `.attest/*.md` pin the kit also needs (the guard parses a record
# byte-exactly, ADR-0037, so a CRLF record fails closed with a reason that blames its age), and
# on a late run — which ADR-0022 keeps supported and the README promises is safe — it silently
# discarded any line the adopter had added under attest's header. Only the blanket rule goes;
# every other line in the file is left exactly where it was (attest ADR-0043).
if [ -f .gitattributes ] && grep -q '^# Shell reaches the working tree with LF, always\.' .gitattributes 2>/dev/null; then
  if grep -qE '^\*\.sh[[:space:]]' .gitattributes; then
    echo "template-cleanup: dropping the kit's blanket *.sh pin from .gitattributes"
    # A temp file beside it, then `cat >`: preserves the mode, and never writes through a
    # symlink the way `> .gitattributes` would (install.sh refuses those outright, and the two
    # paths should not disagree about that).
    if [ -L .gitattributes ]; then
      echo "template-cleanup: .gitattributes is a symlink — drop the '*.sh' line yourself"
    elif grep -vE '^\*\.sh[[:space:]]' .gitattributes > .gitattributes.tmpl$$ 2>/dev/null &&
         cat .gitattributes.tmpl$$ > .gitattributes 2>/dev/null; then
      :
    else
      echo "template-cleanup: could not rewrite .gitattributes — drop the '*.sh' line yourself"
    fi
    rm -f .gitattributes.tmpl$$ 2>/dev/null || true
  else
    echo "template-cleanup: .gitattributes carries no blanket pin — left untouched"
  fi
else
  echo "template-cleanup: .gitattributes is absent or no longer attest's — left untouched"
fi

# attest's own audit records are attest's history, not yours. Left behind, a generated repo
# starts with a dozen records of somebody else's scans — /gate hands the newest of them to its
# auditors as "the last audit", the full-history record describes 51 commits that do not exist
# here, and one of them carries the maintainer's identity into every copy. The directory itself
# stays: it is where YOUR records go (attest ADR-0041).

if [ -d .attest ]; then
  # The discriminator is the sha in the name, not the file's shape. Every record names the
  # commit it gated; a generated repo has its own history, so attest's shas do not resolve here
  # and yours do. Shape would be wrong: a record YOU wrote before the first push carries the
  # same `- kit:` line attest's do, and losing it would be exactly the kind of quiet deletion
  # this script exists not to do. Failing to resolve is the only thing that removes a file, so
  # a git that cannot answer keeps everything.
  # `git cat-file -e` fails for more reasons than "this object is not here": 128 outside a
  # repository, 127 with no git at all. Deleting on any non-zero exit inverts the invariant
  # above — a zip download or a tree before `git init` would lose the adopter's own records
  # too. So establish first that git can answer at all, and only then let a specific negative
  # answer remove anything (attest ADR-0041).
  #
  # A SHALLOW clone answers, and answers wrongly. `actions/checkout` defaults to
  # `fetch-depth: 1`, so `rev-parse --git-dir` succeeds while every commit but HEAD is simply
  # absent — and a record names the commit it gated, which by ADR-0033 is an ANCESTOR, never
  # HEAD. Every one of the adopter's own records would fail to resolve and be deleted, which
  # is the exact destruction this block exists to prevent, with a write token, unattended.
  # `--is-shallow-repository` prints `false` on a full clone and `true` on a truncated one; a
  # git too old to know the option prints nothing, which is also not `false`, so the test is
  # written to keep everything unless git says plainly that the history is complete
  # (attest ADR-0042).
  # Order matters, and cost one dead branch to learn: outside a repository
  # `--is-shallow-repository` prints NOTHING (exit 128), so testing it first swallows the
  # no-git case and tells a plain directory its history is shallow. Ask the three questions in
  # the order they actually narrow: is this a repo at all · does it have a commit to compare
  # against · is its history complete.
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "template-cleanup: not a git checkout — leaving .attest/ untouched"
  elif ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    # A repo before its first commit answers `false` to --is-shallow-repository — its history
    # is complete and empty — but resolves no sha at all, so every record would be deleted.
    echo "template-cleanup: no commits yet — leaving .attest/ untouched"
  elif [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" != "false" ]; then
    echo "template-cleanup: shallow or unverifiable history — leaving .attest/ untouched"
  else
    echo "template-cleanup: removing attest's own audit records from .attest/"
    for rec in .attest/gate-*.md .attest/ship-*.md; do
      [ -e "$rec" ] || continue
      sha="${rec##*-}"; sha="${sha%.md}"
      # The trailing segment is only a sha if it LOOKS like one. `gate-notes.md`,
      # `ship-…-<sha>-rerun.md` and `gate-2026-09-05-pre-release.md` are names the kit never
      # writes, so they are the adopter's — and feeding "notes" or "rerun" to `git cat-file`
      # just fails, which under the rule below would delete them. Anything that is not a bare
      # hex abbreviation of at least four characters is kept, unexamined (attest ADR-0041).
      case "$sha" in
        ""|*[!0-9a-f]*) continue ;;
      esac
      [ "${#sha}" -ge 4 ] || continue
      if git cat-file -e "${sha}^{commit}" 2>/dev/null; then
        continue          # this commit is here — the record is this repository's
      fi
      rm -f "$rec"
    done
  fi
  # The directory stays if anything of yours is in it; rmdir, never rm -rf.
  rmdir .attest 2>/dev/null || true
fi

# COMPLIANCE.md and .claude/skills/compliance/ are deliberately LEFT here, even though
# install.sh does not ship them without --compliance (ADR-0030). The two paths disagree on
# purpose: a generated repo has no install.sh to re-run, so removing them would be the one
# state a user cannot get out of without going back to the kit. /business closes the gap from
# the other side — it tells you to delete them when the archetype says out of scope.

echo "template-cleanup: done"
