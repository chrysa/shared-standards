#!/usr/bin/env python3
"""Idempotently add the chrysa security-gate hooks to a repo's pre-commit +
pyproject, and generate a bandit baseline when there is existing debt.

Runs inside a python container with ruamel.yaml, tomlkit and bandit installed.
Operates on the current working directory (a git worktree). Prints a JSON summary
on the last line for the orchestrator.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from ruamel.yaml import YAML
import tomlkit

PCT = "https://github.com/chrysa/pre-commit-tools"
PROMOTED = [
    "django-hardcoded-secret",
    "ts-hardcoded-secret-detection",
    "pii-hardcoded",
    "dockerfile-multi-stage-check",
    "dockerfile-non-root-user",
]  # docker-run-host-user intentionally excluded (absent at v0.2.0-253)
BASELINE = ".bandit-baseline.json"

yaml = YAML()
yaml.preserve_quotes = True
yaml.width = 4096


def load_yaml(path: Path):
    return yaml.load(path.read_text())


def dump_yaml(path: Path, data) -> None:
    with path.open("w") as fh:
        yaml.dump(data, fh)


def find_repo(repos, url):
    for item in repos:
        if item.get("repo") == url:
            return item
    return None


def ensure_pct_hooks(repos, changed):
    pct = find_repo(repos, PCT)
    if pct is None:
        return
    ids = {h.get("id") for h in pct["hooks"]}
    for hid in PROMOTED:
        if hid in ids:
            continue
        entry = {"id": hid}
        if hid == "pii-hardcoded":
            entry["exclude"] = "(^|/)tests?/"
        pct["hooks"].append(entry)
        changed.append(f"pct:{hid}")


def ensure_simple_repo(repos, url, rev, hook, changed, tag):
    if find_repo(repos, url) is not None:
        return
    repos.append({"repo": url, "rev": rev, "hooks": [hook]})
    changed.append(tag)


def set_json_sorter_exclude(repos):
    pct = find_repo(repos, PCT)
    if pct is None:
        return
    for h in pct["hooks"]:
        if h.get("id") == "json-sorter" and "exclude" not in h:
            h["exclude"] = r"(^|/)\.bandit-baseline\.json$"


def ensure_bandit_args(repos, with_baseline):
    b = find_repo(repos, "https://github.com/PyCQA/bandit")
    if b is None:
        return
    hook = b["hooks"][0]
    args = ["-c", "pyproject.toml"]
    if with_baseline:
        args += ["--baseline", BASELINE]
    hook["args"] = args


def ensure_pyproject_bandit(path: Path, changed):
    doc = tomlkit.parse(path.read_text())
    tool = doc.get("tool")
    if tool is not None and "bandit" in tool:
        return
    tbl = tomlkit.table()
    tbl["exclude_dirs"] = ["tests", "build", "dist", "alembic", ".venv", ".claude"]
    doc.setdefault("tool", tomlkit.table(is_super_table=True))
    doc["tool"]["bandit"] = tbl
    path.write_text(tomlkit.dumps(doc))
    changed.append("pyproject:[tool.bandit]")


def run_bandit_baseline() -> int:
    """Generate baseline over '.'. Returns number of findings."""
    proc = subprocess.run(
        ["bandit", "-c", "pyproject.toml", "-r", ".", "-ll",
         "-x", "./.security_gate_edit.py,./.claude,./tests,./build,./dist,./.venv",
         "-f", "json", "-o", BASELINE, "-q"],
        capture_output=True,
        text=True,
    )
    try:
        data = json.loads(Path(BASELINE).read_text())
        return len(data.get("results", []))
    except Exception:
        return -1


def main() -> None:
    changed: list[str] = []
    cfg = Path(".pre-commit-config.yaml")
    data = load_yaml(cfg)
    repos = data["repos"]

    ensure_pct_hooks(repos, changed)
    ensure_simple_repo(
        repos,
        "https://github.com/PyCQA/bandit",
        "1.8.0",
        {
            "id": "bandit",
            "args": ["-c", "pyproject.toml"],
            "additional_dependencies": ["bandit[toml]"],
            "exclude": "(^|/)tests?/",
        },
        changed,
        "bandit",
    )
    ensure_simple_repo(
        repos,
        "https://github.com/hadolint/hadolint",
        "v2.13.1-beta",
        {"id": "hadolint-docker"},
        changed,
        "hadolint",
    )
    ensure_simple_repo(
        repos,
        "https://github.com/pypa/pip-audit",
        "v2.10.1",
        {"id": "pip-audit", "stages": ["pre-push"]},
        changed,
        "pip-audit",
    )

    ensure_pyproject_bandit(Path("pyproject.toml"), changed)

    findings = run_bandit_baseline()
    if findings > 0:
        ensure_bandit_args(repos, with_baseline=True)
        set_json_sorter_exclude(repos)
    else:
        Path(BASELINE).unlink(missing_ok=True)

    dump_yaml(cfg, data)
    print(json.dumps({"changed": changed, "findings": findings}))


if __name__ == "__main__":
    main()
