#!/usr/bin/env python3
"""PostToolUse hook: enforce ruff.toml on a just-edited .py file — lint-fix, then format.
No-op when the file is not Python or ruff is not on PATH — see GUIDE.md PART 2."""

import json
import shutil
import subprocess
import sys


def ruff(*args):
    subprocess.run(
        ["ruff", *args],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )


def main():
    # Fail-open: any malformed payload must leave the session untouched (GUIDE PART 2).
    try:
        path = json.load(sys.stdin)["tool_input"]["file_path"]
        if not isinstance(path, str) or not path.endswith(".py"):
            return
        if not shutil.which("ruff"):
            return
        # Import hygiene only — never F401, which would delete an import written a moment
        # before the code that uses it. Full rules stay manual: `ruff check .`.
        ruff("check", "--fix", "--quiet", "--select", "I001,E401", path)
        ruff("format", path)
    except Exception:
        return


main()
