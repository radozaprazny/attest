#!/bin/sh
# attest record guard: PreToolUse on Write and Edit. Writing .attest/ship-*.md asks, because the
# ship guard reads that file as evidence: the human accepts the audit's verdict here, while they
# still know whether the audit ran. It asks (denies under ATTEST_GUARD=deny); anything else proceeds.

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
  *.[Aa][Tt][Tt][Ee][Ss][Tt]/[Ss][Hh][Ii][Pp]-*.[Mm][Dd]|*.[Aa][Tt][Tt][Ee][Ss][Tt]"\\\\"[Ss][Hh][Ii][Pp]-*.[Mm][Dd]) ;;
  *) exit 0 ;;
esac

B="${FP##*/}"; B="${B##*\\}"
SAFE="$(printf '.attest/%s' "$B" | tr -c 'A-Za-z0-9 ._/:=@-' ' ' | cut -c1-120)"
MODE="$(printf '%s' "$PAYLOAD" |
  sed -nE 's/.*"permission_mode"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p')"
SHA="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || true)"

{
  mkdir -p "$ROOT/.attest/tmp" &&
    printf '%s %s %s %s %s %s\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "record" "${SHA:--}" "${MODE:--}" "-" "$SAFE" \
      >> "$ROOT/.attest/tmp/ship-guard.log"
} 2>/dev/null || true

D=ask; [ "${ATTEST_GUARD:-}" != deny ] || D=deny
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$D" \
  "attest record guard: RECORD WRITE — writes a ship record ($SAFE). Approve only if /gate ran and this is its verdict: approving is the attestation."

exit 0
