#!/usr/bin/env python3
"""PreCompact hook: nudge to flush state into the thread-carrier before context is compacted.
Deterministic safety-net only — the intelligent flush is the /checkpoint skill.

The thread-carrier defaults to PROGRESS.md; set ATTEST_THREAD_CARRIER if your project names
it something else (e.g. TIMESHEET.md). If the file does not exist, this hook stays silent —
a project that does not keep one should not be nagged about it."""

import json
import os
import sys
import time

CARRIER = os.environ.get("ATTEST_THREAD_CARRIER", "PROGRESS.md")  # tune here
STALE_AFTER_MIN = 10


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return
    root = os.environ.get("CLAUDE_PROJECT_DIR", ".")
    carrier = os.path.join(root, CARRIER)
    if not os.path.exists(carrier):
        return  # this project keeps no thread-carrier by that name -> say nothing
    try:
        age_min = int((time.time() - os.path.getmtime(carrier)) / 60)
    except OSError:
        return
    if age_min < STALE_AFTER_MIN:  # just updated (e.g. by /checkpoint) -> stay silent
        return
    trigger = data.get("trigger", "auto")
    msg = (
        f"[context-hygiene] Compaction ({trigger}) is running. {CARRIER} has not changed in "
        f"{age_min} min. If you have worked since then, run /checkpoint so the thread-carrier "
        "keeps up."
    )
    print(json.dumps({"systemMessage": msg}))


main()
