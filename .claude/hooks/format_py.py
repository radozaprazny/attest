#!/usr/bin/env python3
"""PostToolUse hook: enforce ruff.toml on a just-edited .py file — lint-fix, then format.
No-op when the file is not Python or ruff is not on PATH — see GUIDE.md PART 2."""

import json
import os
import shutil
import subprocess
import sys


def ruff(*args):
    subprocess.run(
        # --no-cache: a per-edit run of one file gains nothing from the cache, and writing
        # .ruff_cache/ into a repo whose .gitignore has no line for it (any target that had
        # no Python when the kit was installed) is how cache junk gets committed. Manual
        # `ruff check .` still caches normally.
        ["ruff", *args, "--no-cache"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
        # A wedged formatter must not wedge the edit that triggered it.
        timeout=30,
    )


def in_project(path):
    """True unless the file provably sits outside this project.

    Claude edits files outside the repo too (another checkout, a script in $HOME). Ruff
    resolves its config by walking up from the target, so formatting those would apply
    ruff's defaults or a foreign project's rules — silently, since all output is dropped.
    Unset CLAUDE_PROJECT_DIR means we cannot tell: fail open, as everywhere else here.
    """
    root = os.environ.get("CLAUDE_PROJECT_DIR")
    if not root:
        return True
    root = os.path.realpath(root)
    return os.path.realpath(path).startswith(root + os.sep)


def main():
    # Fail-open: any malformed payload must leave the session untouched (GUIDE PART 2).
    try:
        path = json.load(sys.stdin)["tool_input"]["file_path"]
        if not isinstance(path, str) or not path.endswith(".py"):
            return
        if not in_project(path):
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
