#!/usr/bin/env python3
"""Fail when repos.yml disagrees with GitHub about which repos are archived.

`status:` in repos.yml is hand-tuned, so it goes stale silently: a repo archived
on GitHub keeps its `status: dev` and every audit and rollout driven off the file
keeps targeting it. Measured case — game-solver-platform and paperclip were
archived while still listed as dev, so the LOT 1 Ruff rollout tried to push to
them and got `This repository was archived so it is read-only`.

Usage:  check-repos-archived-drift.py [repos.yml]
Exit:   0 no drift · 1 drift (listed, with the direction) · 2 cannot check.
"""

from __future__ import annotations

import json
import subprocess  # nosec B404
import sys
from pathlib import Path

import yaml


def _archived_on_github() -> set[str] | None:
    """Repository names GitHub reports as archived, or None when gh cannot answer."""
    try:
        out = subprocess.run(  # nosec B603 B607 — fixed argv, no shell, no user input
            ["gh", "repo", "list", "chrysa", "--limit", "300", "--json", "name,isArchived"],
            capture_output=True,
            text=True,
            timeout=120,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if out.returncode != 0:
        return None
    try:
        return {r["name"] for r in json.loads(out.stdout) if r.get("isArchived")}
    except (json.JSONDecodeError, KeyError, TypeError):
        return None


def main(argv: list[str]) -> int:
    target = Path(argv[0]) if argv else Path("repos.yml")
    if not target.is_file():
        sys.stderr.write(f"{target}: not found\n")
        return 2

    archived = _archived_on_github()
    if archived is None:
        sys.stderr.write("cannot reach gh · archived drift not checked\n")
        return 2

    entries = yaml.safe_load(target.read_text(encoding="utf-8"))["repos"]
    drift: list[str] = []
    for entry in entries:
        name, status = entry.get("name"), entry.get("status")
        if name in archived and status != "archived":
            drift.append(f"  {name}: archived on GitHub, repos.yml says '{status}'")
        elif name not in archived and status == "archived":
            drift.append(f"  {name}: live on GitHub, repos.yml says 'archived'")

    if drift:
        sys.stderr.write("repos.yml disagrees with GitHub on archived state:\n")
        sys.stderr.write("\n".join(drift) + "\n")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
