---
name: gate
description: >-
  The one gate before a push: betterleaks and one read-only auditor over what the next push
  sends, then a committed ship record the ship guard reads. `full` adds all history.
argument-hint: "[full]"
disable-model-invocation: true
---

# /gate [full] — one gate before anything leaves

Scope is what the next push sends: `HEAD --not --remotes`, plus uncommitted and untracked
files. `full` adds all history (`--all`). Code review is left to `/code-review`.
No commit yet: say so and stop.

## 1. Material and key layer — one Bash call

Run as **one** call, `bash <<'EOF'` … `EOF` (`FULL=1 bash` for `full`). It writes the
material to `.attest/tmp/gate/` and prints a summary; never read the patches here.

```bash
cd "$(git rev-parse --show-toplevel)" || exit 1
D=.attest/tmp/gate; mkdir -p "$D"; rm -f "$D"/*
g() { git -c core.quotepath=off "$@"; }
K=(.claude/hooks/{ship_guard,record_guard,session_declaration}.sh .claude/agents/auditor.md
  .claude/skills/{gate,business,decision,compliance,checkpoint}/SKILL.md)
X=("${K[@]/#/:!}" ':!.attest/tmp'); F=(-p --no-ext-diff --date=short --format='commit %h %ad %s')
R=(HEAD --not --remotes); L='HEAD --branches --tags --not --remotes'
[ -z "${FULL:-}" ] || { R=(--all); L=--all; }
{ g log "${F[@]}" "${R[@]}" -- . "${X[@]}"; g log "${F[@]}" --diff-filter=M "${R[@]}" -- "${K[@]}"; } > "$D/range.patch"
g log --date=short --format='%h %ad %s' "${R[@]}" > "$D/log.txt"
g diff --no-ext-diff HEAD > "$D/worktree.patch"
U=(); while IFS= read -r -d '' e; do case $e in '?? '*) U+=("${e#?? }");; esac
done < <(g status --porcelain -z -uall -- . "${X[@]}")
printf '%s\n' "${U[@]}" | sed '/^$/d' > "$D/untracked.txt"
ls -d BUSINESS.md DECISIONS.md COMPLIANCE.md 2>/dev/null > "$D/docs.txt"
b() { n=$1; shift; betterleaks "$@" --redact=100 --no-banner --exit-code 42 --report-format json \
  --report-path - < /dev/null > "$D/leaks-$n.json" 2>/dev/null; echo "$n $?"; }
if command -v betterleaks >/dev/null; then echo "betterleaks $(betterleaks version)"
  b unpushed git . --log-opts="$L"; b unstaged git . --pre-commit; b staged git . --pre-commit --staged
  [ ${#U[@]} -eq 0 ] || b untracked dir "${U[@]}"; else echo 'betterleaks absent'; fi | tee "$D/leaks.txt"
echo "HEAD $(git rev-parse --short HEAD) ($(git branch --show-current | grep . || echo detached))" \
  "· tree $([ -n "$(git status --porcelain)" ] && echo dirty || echo clean) · ts $(date +%Y%m%d-%H%M%S)"
echo "kit $(sed -n 's/^Kit version: \([^ ]*\).*/\1/p' .claude/skills/_shared/audit-ladder.md)"
wc -l "$D"/*.patch "$D"/*.txt
```

- `-z` status is never quoted; `quotepath=off` keeps non-ASCII paths readable.
- The kit's own 9 files are left out where added or untracked, so a first `/gate` audits your
  change, not the install, even uncommitted or with no remote; an edit to one stays in.
  `.claude/settings.json` never is left out: its `env` can hold secrets.
- betterleaks takes the guard's range. `dir` is skipped with no untracked file: a bare `dir`
  reads ignored files. `0` is clean, `42` a finding, anything else did not finish: `degraded`,
  never clean. Never add `--validation`: it sends the secret to its provider.

## 2. One auditor

Launch the `auditor` subagent once with the absolute path of `.attest/tmp/gate/` and the mode.

## 3. Verdict — derived, not judged

Every `leaks-*.json` finding (redacted) must appear in the auditor's list; add any it dropped
as `blocker · secret · <File>`. A hit judged a false positive still makes the guard ask `LEAK`
until its `Fingerprint` is in a committed `.betterleaksignore`: commit that before the record.
Any blocker → **⚠️ fix before push**; none → **✅ clean to push**.
Show each finding with its evidence; end with one imperative.

Remediation: rotate a leaked secret; purging history and force-pushing is the person's call.
If it was ever public, GDPR Art 33/34 may apply: consult, do not decide.

## 4. The record — always, whatever the verdict

Write `.attest/ship-<ts>-<short sha>.md` with the Write tool, from the summary's values. The
record guard asks here: that approval is the one human prompt, the attestation.

```markdown
- HEAD: <short sha> (<branch>)
- tree: clean|dirty
- scope: HEAD --not --remotes + worktree (<n> commits, <n> untracked) | --all + worktree
- findings: <n> blocker · <n> note
- verdict: ✅ clean to push | ⚠️ fix before push
- kit: <version>
- key layer: betterleaks <version> — unpushed <rc> · unstaged <rc> · staged <rc> · untracked <rc|skipped> | degraded — <why>
- blocker · <class> · <path>
```

One `blocker ·` line per blocker; notes are counted, not listed. The ship guard parses
`- HEAD:` (the sha prefix) and `- findings:` (it clears only on `0 blocker`): write both
exactly. **Attestation altitude:** class and path only, never a value, line number or excerpt —
it is committed and published. Name a degraded auditor in `scope:`.
Never edit an earlier record.

Then, as its own Bash step, never chained with a push:

```bash
git add <record> && git commit -m "chore(attest): ship record for <sha>" -- <record>
```

A clean record lets the next push pass as its carrier; after a ⚠️, fix and re-run `/gate`.
