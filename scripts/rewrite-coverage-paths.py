#!/usr/bin/env python3
"""Rewrite a Cobertura ``coverage.xml`` so SonarCloud can map it from the repo root.

The console test suite runs with its package (``standards_console``) as the coverage
source, so the report's ``<source>`` is an absolute path and every ``filename`` is bare
(e.g. ``app.py``). SonarCloud analyses from the repo root, where those files live under
``console/standards_console/`` — the absolute source never matches the Sonar runner's
checkout, yielding 0% coverage on new code.

This normalises the report to repo-root-relative paths:
    <source>ABS/console/standards_console</source>  -> <source>.</source>
    filename="app.py"                               -> filename="console/standards_console/app.py"

Usage: ``rewrite-coverage-paths.py <coverage.xml> <repo-relative-package-dir>``
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


def rewrite(text: str, prefix: str) -> str:
    prefix = prefix.strip("/")
    text = re.sub(r"<source>.*?</source>", "<source>.</source>", text, flags=re.DOTALL)
    return re.sub(r'filename="(?!' + re.escape(prefix) + r"/)", f'filename="{prefix}/', text)


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    report = Path(sys.argv[1])
    report.write_text(rewrite(report.read_text(encoding="utf-8"), sys.argv[2]), encoding="utf-8")
    print(f"rewrote {report} for repo-root Sonar mapping (prefix: {sys.argv[2]})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
