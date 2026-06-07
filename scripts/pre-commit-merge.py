#!/usr/bin/env python3
"""Idempotently merge the canonical .pre-commit-config.yaml baseline into a repo's.

Union by repo URL, then by hook id. Existing repo entries win (rev, args, excludes
are preserved); only missing repos / hook ids from the baseline are added. This keeps
repo-specific tuning while guaranteeing the §8 mandatory hooks are present.

The baseline carries stack-conditional hooks (fastapi/docker/js-ts/react). Pass
--stacks to enforce only the relevant subset; chrysa/pre-commit-tools hooks outside
the selected groups (and ALWAYS) are ignored for both --check and merge. Hooks from
repos not governed by HOOK_GROUPS (pre-commit-hooks, gitleaks, conventional,
markdownlint) are always enforced.

Usage: pre-commit-merge.py <baseline.yaml> <target.yaml> [--check] [--stacks python,docker]
  --check  : exit 1 if the target is missing any enforced baseline repo/hook (no write).
  --stacks : comma list of python,docker,jsts,react,fastapi (default: all).
Exit: 0 ok / 1 drift (with --check) or error.
"""

from __future__ import annotations

import io
import re
import sys
from pathlib import Path

# Prefer ruamel round-trip: keeps existing lines byte-identical (so a file that
# already passes the repo's yamllint still does) and indents only appended nodes.
try:
    from ruamel.yaml import YAML

    _RUAMEL = YAML()
    _RUAMEL.preserve_quotes = True
    _RUAMEL.width = 4096  # never wrap long flow scalars (e.g. conventional-commit args)
    _RUAMEL.indent(mapping=2, sequence=4, offset=2)  # yamllint-default friendly
    _BACKEND = "ruamel"
except ImportError:
    _RUAMEL = None
    try:
        import yaml
    except ImportError:
        sys.stderr.write("neither ruamel.yaml nor pyyaml available — manual merge required\n")
        sys.exit(2)
    _BACKEND = "pyyaml"


def _load_text(text: str) -> dict:
    if _BACKEND == "ruamel":
        return _RUAMEL.load(text) or {"repos": []}
    return yaml.safe_load(text) or {"repos": []}


_TOP_SEQ_RE = re.compile(r"^(\s*)-\s", re.MULTILINE)


def detect_offset(text: str) -> int:
    """Detect the repo's top-level sequence offset (dash indent) under `repos:`.

    Repos may indent their pre-commit list at 2 (default) or 4 spaces. Re-dumping
    with the wrong offset reindents the whole file and breaks a repo's own yamllint
    (e.g. `wrong indentation: expected N`). We mirror the target's style instead.
    Returns 2 when the file has no list yet (new/empty config).
    """
    in_repos = False
    for line in text.splitlines():
        if re.match(r"^repos:\s*$", line):
            in_repos = True
            continue
        if in_repos:
            m = re.match(r"^(\s*)-\s", line)
            if m:
                return len(m.group(1))
            if line.strip() and not line.lstrip().startswith("#"):
                # a non-list, non-comment line at column 0 ends the repos block
                if not line.startswith(" "):
                    break
    return 2


def decide_offset(text: str) -> int:
    """Pick the dump offset that keeps the repo's yamllint green.

    Mirror an explicit indent (>= 2) so a repo using offset 4 (e.g. paperclip) is
    not reindented. But offset 0 (root-level sequences) only passes yamllint when
    `indent-sequences` is disabled; the default rule is `true` and requires
    sequences indented >= 1. Many repos carry an offset-0 config that predates
    their yamllint hook (never linted until we touch the file), so bump 0 -> 2
    unless the repo explicitly disabled the rule.
    """
    off = detect_offset(text)
    if off >= 2:
        return off
    if re.search(r"indent-sequences:\s*(false|disable)", text):
        return 0
    return 2


def configure_indent(offset: int) -> None:
    if _BACKEND == "ruamel":
        # ruamel: content column = sequence; dash column = offset (offset < sequence).
        _RUAMEL.indent(mapping=2, sequence=offset + 2, offset=offset)


def _dump(data: dict) -> str:
    if _BACKEND == "ruamel":
        buf = io.StringIO()
        _RUAMEL.dump(data, buf)
        return buf.getvalue()
    return yaml.safe_dump(data, sort_keys=False, default_flow_style=False)

# chrysa/pre-commit-tools hook ids grouped by stack. Ids not listed here belong to
# other repos (pre-commit-hooks, gitleaks, conventional, markdownlint) and are always
# enforced. "always" applies to every repo.
HOOK_GROUPS = {
    "always": {
        "yaml-sorter", "json-sorter", "env-file-check", "env-example-sync", "adr-gate",
    },
    "python": {
        "debugger-detection", "python-print-detection", "python-pprint-detection",
        "no-bare-except", "python-logger-detection", "python-unreachable-code",
        "no-hardcoded-localhost", "regression-gate",
    },
    "docker": {"dockerfile-no-latest"},
    "jsts": {
        "console-log-detection", "console-debug-detection",
        "react-console-error-detection", "no-console-warn", "ts-unreachable-code",
        "import-no-relative-parent",
    },
    "react": {"react-no-async-in-useeffect", "react-direct-dom"},
    "fastapi": {
        "fastapi-missing-response-model", "fastapi-missing-links", "no-sync-in-async",
    },
}
GOVERNED = set().union(*HOOK_GROUPS.values())

# Repos whose pinned rev must track the canonical baseline (not "existing wins"):
# the hook *implementation* carries fixes the campaign depends on. Example: the
# adr-gate index-fallback (#177) lands only at chrysa/pre-commit-tools >= v0.1.1-93;
# older pins false-positive when an earlier auto-fixing hook reorders staged files.
REV_ALIGNED_REPOS = {"https://github.com/chrysa/pre-commit-tools"}


def enforced_ids(stacks: set[str]) -> set[str]:
    selected = set(HOOK_GROUPS["always"])
    for stack in stacks:
        selected |= HOOK_GROUPS.get(stack, set())
    return selected


def hook_enforced(hook_id: str, allowed: set[str]) -> bool:
    # Hooks from non-stack repos aren't in GOVERNED -> always enforce.
    return hook_id not in GOVERNED or hook_id in allowed


def load(path: Path) -> dict:
    if not path.exists():
        return {"repos": []}
    return _load_text(path.read_text())


def index_hooks(repo: dict) -> dict:
    return {h.get("id"): h for h in repo.get("hooks", []) if h.get("id")}


def enforced_hooks(brepo: dict, allowed: set[str]) -> dict:
    return {hid: h for hid, h in index_hooks(brepo).items() if hook_enforced(hid, allowed)}


def missing_items(baseline: dict, target: dict, allowed: set[str]) -> list[str]:
    target_by_url = {r.get("repo"): r for r in target.get("repos", [])}
    gaps: list[str] = []
    for brepo in baseline.get("repos", []):
        url = brepo.get("repo")
        wanted = enforced_hooks(brepo, allowed)
        if not wanted:
            continue
        if url not in target_by_url:
            gaps.append(url)
            continue
        existing = target_by_url[url]
        have = index_hooks(existing)
        gaps.extend(f"{url}#{hid}" for hid in wanted if hid not in have)
        if url in REV_ALIGNED_REPOS and existing.get("rev") != brepo.get("rev"):
            gaps.append(f"{url}@{brepo.get('rev')}")
    return gaps


def merge(baseline: dict, target: dict, allowed: set[str]) -> dict:
    target_by_url = {r.get("repo"): r for r in target.get("repos", [])}
    for brepo in baseline.get("repos", []):
        url = brepo.get("repo")
        wanted = enforced_hooks(brepo, allowed)
        if not wanted:
            continue
        if url not in target_by_url:
            new_repo = {k: v for k, v in brepo.items() if k != "hooks"}
            new_repo["hooks"] = list(wanted.values())
            target.setdefault("repos", []).append(new_repo)
            target_by_url[url] = new_repo
            continue
        existing = target_by_url[url]
        have = index_hooks(existing)
        for hid, hook in wanted.items():
            if hid not in have:
                existing.setdefault("hooks", []).append(hook)
        if url in REV_ALIGNED_REPOS and brepo.get("rev") is not None:
            existing["rev"] = brepo["rev"]
    return target


def parse_stacks(argv: list[str]) -> set[str]:
    for i, a in enumerate(argv):
        if a == "--stacks" and i + 1 < len(argv):
            return {s.strip() for s in argv[i + 1].split(",") if s.strip()}
        if a.startswith("--stacks="):
            return {s.strip() for s in a.split("=", 1)[1].split(",") if s.strip()}
    return set(HOOK_GROUPS)  # default: enforce everything (back-compat)


def main() -> int:
    flag_vals = {"--stacks"}
    positional: list[str] = []
    skip = False
    for i, a in enumerate(sys.argv[1:]):
        if skip:
            skip = False
            continue
        if a in flag_vals:
            skip = True
            continue
        if a.startswith("--"):
            continue
        positional.append(a)
    check = "--check" in sys.argv
    if len(positional) != 2:
        sys.stderr.write(__doc__ or "")
        return 2
    allowed = enforced_ids(parse_stacks(sys.argv[1:]))
    baseline_path, target_path = Path(positional[0]), Path(positional[1])
    # Mirror the target's own sequence indentation before any round-trip dump so a
    # repo with a non-default offset keeps passing its own yamllint.
    if target_path.exists():
        configure_indent(decide_offset(target_path.read_text()))
    baseline, target = load(baseline_path), load(target_path)

    gaps = missing_items(baseline, target, allowed)
    if check:
        if gaps:
            sys.stderr.write("missing: " + ", ".join(gaps) + "\n")
            return 1
        return 0

    if not gaps:
        return 0
    merged = merge(baseline, target, allowed)
    target_path.write_text(_dump(merged))
    sys.stderr.write(f"added {len(gaps)} baseline item(s)\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
