#!/bin/sh
# PreToolUse(Write|Edit) hook: a ship record is written by a human decision (attest ADR-0051).
#
# `ship_guard.sh` decides whether a push may proceed by reading a record under `.attest/`. That
# record is an ordinary untracked file — nothing signs it, nothing proves an audit produced it,
# and the same agent whose work it attests can write one. `disable-model-invocation: true` keeps
# the model from *invoking* /audit-history; it says nothing about writing a file, and the ship
# guard judges commands and publish tools, never a Write. So the kit's most load-bearing
# artefact had exactly the property the kit tells you not to accept anywhere else: a promise
# instead of a boundary.
#
# What this hook buys, stated honestly: it does not make forgery impossible — it makes the write
# a prompt, at the moment the human still knows whether an audit ran. That is strictly earlier
# and better-informed than the push prompt, which is the same click after the context is gone.
# The capability fix (a writer that cannot audit, an auditor that cannot write) needs a
# primitive no host here provides.
#
# It ASKS, it does not forbid — same rule as the ship guard: a guard that cannot be overridden
# gets deleted. Fail-open everywhere: no payload, no path, no match => the write proceeds.

set -u

ROOT="${CLAUDE_PROJECT_DIR:-.}"
PAYLOAD="$(cat 2>/dev/null || true)"
[ -n "$PAYLOAD" ] || exit 0

# The target path out of the JSON payload. sed, not a JSON parser: the value is only ever
# matched against the fixed pattern below and echoed back sanitised, never executed.
FP="$(printf '%s' "$PAYLOAD" |
  sed -nE 's/.*"file_path"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p')"
[ -n "$FP" ] || exit 0

# Only a ship record. A gate record attests a commit-time run that no machine reads, so a prompt
# on it would be friction without a decision behind it; the line this hook defends is the one
# where a file becomes a machine's answer (attest ADR-0051).
case "$FP" in
  *".attest/ship-"*".md") ;;
  *) exit 0 ;;
esac

SAFE="$(printf '%s' "$FP" | tr -c 'A-Za-z0-9 ._/:=@-' ' ' | cut -c1-120)"
MODE="$(printf '%s' "$PAYLOAD" |
  sed -nE 's/.*"permission_mode"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p')"
SHA="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || true)"

# The same log the ship guard writes, in the same shape — one file answers "what did the guards
# decide, and under which mode" for both halves (attest ADR-0034, ADR-0026).
{
  mkdir -p "$ROOT/.attest/tmp" &&
    printf '%s %s %s %s %s\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "record" "${SHA:--}" "${MODE:--}" "$SAFE" \
      >> "$ROOT/.attest/tmp/ship-guard.log"
} 2>/dev/null || true

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' \
  "attest ship gate: this writes a ship record ($SAFE) — the file the ship guard reads as evidence that /audit-history ran. Approve only if the audit actually ran and this is its verdict: nothing in the tooling can tell a written record from an earned one, so this prompt is the step that makes it an attestation rather than a claim."

exit 0
