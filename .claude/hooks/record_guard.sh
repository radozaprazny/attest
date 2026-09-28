#!/bin/sh
# attest record guard: PreToolUse on Write and Edit. Writing .attest/ship-*.md asks, because the
# ship guard reads that file as evidence: the human accepts the audit's verdict here, while they
# still know whether the audit ran. It asks, never denies; anything else proceeds.

set -u
export LC_ALL=C

ROOT="${CLAUDE_PROJECT_DIR:-.}"
PAYLOAD="$(cat 2>/dev/null || true)"
[ -n "$PAYLOAD" ] || exit 0

# sed, not a JSON parser: the path is only matched and echoed sanitised, never executed.
FP="$(printf '%s' "$PAYLOAD" |
  sed -nE 's/.*"file_path"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p')"
[ -n "$FP" ] || exit 0

case "$FP" in
  *".attest/ship-"*".md") ;;
  *) exit 0 ;;
esac

SAFE="$(printf '%s' "$FP" | tr -c 'A-Za-z0-9 ._/:=@-' ' ' | cut -c1-120)"
MODE="$(printf '%s' "$PAYLOAD" |
  sed -nE 's/.*"permission_mode"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p')"
SHA="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || true)"

{
  mkdir -p "$ROOT/.attest/tmp" &&
    printf '%s %s %s %s %s %s\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "record" "${SHA:--}" "${MODE:--}" "-" "$SAFE" \
      >> "$ROOT/.attest/tmp/ship-guard.log"
} 2>/dev/null || true

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' \
  "attest ship gate: this writes a ship record ($SAFE) — the file the ship guard reads as evidence that /audit-history ran. Approve only if the audit actually ran and this is its verdict: nothing in the tooling can tell a written record from an earned one, so this prompt is the step that makes it an attestation rather than a claim."

exit 0
