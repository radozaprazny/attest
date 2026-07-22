#!/usr/bin/env python3
"""Stop hook: once per session, warn when the transcript grows long — nudge /clear
between logical blocks (or /compact mid-task). Throttled by a per-session sentinel."""

import json
import os
import re
import sys
import tempfile

THRESHOLD_LINES = 500  # tune here


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return
    tp = data.get("transcript_path", "")
    # The id becomes a filename below — never trust it to be path-safe.
    sid = re.sub(r"[^A-Za-z0-9._-]", "_", str(data.get("session_id", "unknown")))
    try:
        with open(tp, encoding="utf-8") as f:
            lines = sum(1 for _ in f)
    except Exception:
        return
    if lines < THRESHOLD_LINES:
        return
    sentinel = os.path.join(tempfile.gettempdir(), f"claude-longsession-{sid}")
    if os.path.exists(sentinel):
        return
    try:
        open(sentinel, "w").close()
    except Exception:
        # No sentinel means no throttle — warning every Stop. Keep the
        # once-per-session contract by staying silent instead.
        return
    msg = (
        f"[context-hygiene] Long session (~{lines} transcript records). "
        "Between blocks: /checkpoint + /clear. Mid-task: /compact."
    )
    print(json.dumps({"systemMessage": msg}))


main()
