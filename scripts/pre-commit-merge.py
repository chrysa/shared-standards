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
        sys.stderr.write(
            "neither ruamel.yaml nor pyyaml available — manual merge required\n"
        )
        sys.exit(2)
    _BACKEND = "pyyaml"


def _load_text(text: str) -> dict:
    if _BACKEND == "ruamel":
        return _RUAMEL.load(text) or {"repos": []}
    return yaml.safe_load(text) or {"repos": []}


_TOP_SEQ_RE = re.compile(r"^(\s*)-\s", re.MULTILINE)


def _repos_block_offset(lines: list[str]) -> int | None:
    """Scan lines after `repos:` and return the dash-indent, or None if not found."""
    in_repos = False
    for line in lines:
        if re.match(r"^repos:\s*$", line):
            in_repos = True
            continue
        if not in_repos:
            continue
        m = re.match(r"^(\s*)-\s", line)
        if m:
            return len(m.group(1))
        if (
            line.strip()
            and not line.lstrip().startswith("#")
            and not line.startswith(" ")
        ):
            break
    return None


def detect_offset(text: str) -> int:
    """Detect the repo's top-level sequence offset (dash indent) under `repos:`.

    Repos may indent their pre-commit list at 2 (default) or 4 spaces. Re-dumping
    with the wrong offset reindents the whole file and breaks a repo's own yamllint
    (e.g. `wrong indentation: expected N`). We mirror the target's style instead.
    Returns 2 when the file has no list yet (new/empty config).
    """
    result = _repos_block_offset(text.splitlines())
    return result if result is not None else 2


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


def configure_document_start(text: str) -> None:
    # Preserve a leading `---`: ruamel drops it on re-dump, which fails yamllint's
    # document-start rule (error-level in strict repos like diy-stream-deck).
    if _BACKEND == "ruamel":
        _RUAMEL.explicit_start = (
            bool(re.match(r"^---\s*$", text.splitlines()[0])) if text.strip() else False
        )


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
        "yaml-sorter",
        "json-sorter",
        "env-file-check",
        "env-example-sync",
        "adr-gate",
        # Claude Code assets: every repo carries .claude/ and most carry .mcp.json.
        "claude-skill-frontmatter",
        "claude-agent-frontmatter",
        "claude-mcp-config",
    },
    "python": {
        "debugger-detection",
        "python-print-detection",
        "python-pprint-detection",
        "no-bare-except",
        "python-logger-detection",
        "python-unreachable-code",
        "no-hardcoded-localhost",
        "regression-gate",
        # Detectors for the code-quality rules of the standards block. Measured dry
        # on 2026-08-03 across the status:dev fleet (63 repos then, 59 today after the
        # archived-flag reconciliations in #305 and #376): 47 untyped raises (13 of them
        # in tests, hence the baseline exclude), 5 dispatch ladders, 0 mutable defaults.
        # Remediated to 0 in product code on 2026-08-05, re-verified on fresh clones.
        "python-untyped-raise",
        "python-mutable-default",
        "python-dispatch-ladder",
    },
    "docker": {"dockerfile-no-latest"},
    "jsts": {
        "console-log-detection",
        "console-debug-detection",
        "react-console-error-detection",
        "no-console-warn",
        "ts-unreachable-code",
        "import-no-relative-parent",
    },
    "react": {"react-no-async-in-useeffect", "react-direct-dom"},
    "fastapi": {
        "fastapi-missing-response-model",
        "fastapi-missing-links",
        "no-sync-in-async",
    },
}
GOVERNED = set().union(*HOOK_GROUPS.values())

# Repos whose pinned rev must track the canonical baseline (not "existing wins"):
# the hook *implementation* carries fixes the campaign depends on. Example: the
# adr-gate index-fallback (#177) lands only at chrysa/pre-commit-tools >= v0.1.1-93;
# older pins false-positive when an earlier auto-fixing hook reorders staged files.
#
# The alignment is a FLOOR, not an equality: it moves a consumer forward to the
# baseline, never backward. Written as plain equality it downgraded every repo that
# was ahead of the baseline — the release-triggered run of 2026-08-07 rolled
# lifeos/discordium/D-D from v0.2.0-253 back to the baseline's v0.2.0-247, undoing
# six releases of hook fixes in the name of "aligning".
REV_ALIGNED_REPOS = {"https://github.com/chrysa/pre-commit-tools"}

# `vX.Y.Z-N` (the GitVersion tag shape used across the fleet). Anything else is
# unorderable — an unrecognised rev aligns unconditionally, as before.
_REV_PATTERN = re.compile(r"^v?(\d+)\.(\d+)\.(\d+)(?:-(\d+))?$")


def rev_order(rev: object) -> tuple[int, int, int, int] | None:
    """Sortable tuple for a `vX.Y.Z-N` tag, or ``None`` when the shape is unknown."""
    match = _REV_PATTERN.match(str(rev or ""))
    if match is None:
        return None
    major, minor, patch, build = match.groups()
    return (int(major), int(minor), int(patch), int(build or 0))


def rev_regresses(baseline_rev: object, existing_rev: object) -> bool:
    """True when aligning to the baseline would move the consumer *backwards*.

    Both revs must be orderable to conclude that: two tags this cannot parse are
    treated as alignable, which is the pre-existing behaviour.
    """
    baseline_order, existing_order = rev_order(baseline_rev), rev_order(existing_rev)
    if baseline_order is None or existing_order is None:
        return False
    return baseline_order < existing_order


# Hook ids whose `exclude` is a POLICY, not per-repo tuning: the baseline value wins over
# whatever a consumer already has. Without this, a corrected exclude never reaches the fleet
# — merge() is a union where "existing wins", so a hook a repo already has is never touched
# again. That is right for a repo's own tuning and wrong for a pattern the standard defines:
# `^tests?/` (anchored at the repo root) silently missed `backend/tests/`, and the fix could
# not propagate to the 57 repos that already carried the hook. Keep this set small — every id
# here gives up the right to tune its own exclude.
EXCLUDE_ALIGNED_IDS = {
    "debugger-detection",
    "python-print-detection",
    "python-pprint-detection",
    "python-logger-detection",
    "python-untyped-raise",
    "fastapi-missing-response-model",
    "fastapi-missing-links",
    # yaml-sorter's exclude is policy: it must always skip workflows, lock files
    # and `.pre-commit-config.yaml`. A repo that carries an older, narrower exclude
    # (missing the config, so the sorter rewrites it on every run) is corrected by
    # the baseline instead of drifting forever.
    "yaml-sorter",
}

# `repo: local` hooks reference repo-relative scripts/files (e.g. the canonical-drift
# gate runs scripts/check-canonical-drift.sh against templates/ copies that only exist
# in shared-standards itself). They are self-only and must never be fanned out to the
# fleet, or every consumer's pre-commit fails with "executable not found".
NON_DISTRIBUTED_REPOS = {"local"}


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
    return {
        hid: h for hid, h in index_hooks(brepo).items() if hook_enforced(hid, allowed)
    }


def describe_actions(gaps: list[str]) -> str:
    """Summarise what the merge did, keeping the two actions distinct.

    "added" is a hook the repo did not have; "aligned" is a policy exclude that was
    overwritten. Reporting an overwrite as an addition hides what actually changed.
    """
    aligned = sum(1 for gap in gaps if gap.endswith("!exclude"))
    added = len(gaps) - aligned
    parts = []
    if added:
        parts.append(f"added {added} baseline item(s)")
    if aligned:
        parts.append(f"aligned {aligned} policy exclude(s)")
    return ", ".join(parts)


def exclude_drifts(target_hook: dict, baseline_hook: dict) -> bool:
    """True when a policy hook's exclude differs from the baseline's."""
    return target_hook.get("exclude") != baseline_hook.get("exclude")


def align_exclude(target_hook: dict, baseline_hook: dict) -> None:
    """Force the baseline exclude onto a policy hook (mutates target_hook)."""
    if "exclude" in baseline_hook:
        target_hook["exclude"] = baseline_hook["exclude"]
    else:
        target_hook.pop("exclude", None)


def missing_items(baseline: dict, target: dict, allowed: set[str]) -> list[str]:
    target_by_url = {r.get("repo"): r for r in target.get("repos", [])}
    gaps: list[str] = []
    for brepo in baseline.get("repos", []):
        url = brepo.get("repo")
        if url in NON_DISTRIBUTED_REPOS:
            continue
        wanted = enforced_hooks(brepo, allowed)
        if not wanted:
            continue
        if url not in target_by_url:
            gaps.append(url)
            continue
        existing = target_by_url[url]
        have = index_hooks(existing)
        gaps.extend(f"{url}#{hid}" for hid in wanted if hid not in have)
        gaps.extend(
            f"{url}#{hid}!exclude"
            for hid, hook in wanted.items()
            if hid in have
            and hid in EXCLUDE_ALIGNED_IDS
            and exclude_drifts(have[hid], hook)
        )
        if (
            url in REV_ALIGNED_REPOS
            and existing.get("rev") != brepo.get("rev")
            and not rev_regresses(brepo.get("rev"), existing.get("rev"))
        ):
            gaps.append(f"{url}@{brepo.get('rev')}")
    canon_py = canonical_python(baseline)
    if canon_py and target_python(target) not in (None, canon_py):
        gaps.append(f"default_language_version.python={canon_py}")
    return gaps


def canonical_python(baseline: dict) -> str | None:
    return (baseline.get("default_language_version") or {}).get("python")


def target_python(target: dict) -> str | None:
    return (target.get("default_language_version") or {}).get("python")


def _merge_single_repo(
    brepo: dict, target: dict, target_by_url: dict, wanted: dict
) -> None:
    """Merge one baseline repo entry into target (mutates target and target_by_url)."""
    url = brepo.get("repo")
    if url not in target_by_url:
        new_repo = {k: v for k, v in brepo.items() if k != "hooks"}
        new_repo["hooks"] = list(wanted.values())
        target.setdefault("repos", []).append(new_repo)
        target_by_url[url] = new_repo
        return
    existing = target_by_url[url]
    have = index_hooks(existing)
    for hid, hook in wanted.items():
        if hid not in have:
            existing.setdefault("hooks", []).append(hook)
        elif hid in EXCLUDE_ALIGNED_IDS:
            align_exclude(have[hid], hook)
    if (
        url in REV_ALIGNED_REPOS
        and brepo.get("rev") is not None
        and not rev_regresses(brepo["rev"], existing.get("rev"))
    ):
        existing["rev"] = brepo["rev"]


def merge(baseline: dict, target: dict, allowed: set[str]) -> dict:
    target_by_url = {r.get("repo"): r for r in target.get("repos", [])}
    for brepo in baseline.get("repos", []):
        url = brepo.get("repo")
        if url in NON_DISTRIBUTED_REPOS:
            continue
        wanted = enforced_hooks(brepo, allowed)
        if not wanted:
            continue
        _merge_single_repo(brepo, target, target_by_url, wanted)
    # Align the python pin to canonical: chrysa/pre-commit-tools requires >=3.14,
    # so a repo pinned to an older interpreter (e.g. python3.13) fails to build the
    # hook env. Only adjust when the target already declares a python version.
    canon_py = canonical_python(baseline)
    if canon_py and target_python(target) not in (None, canon_py):
        target["default_language_version"]["python"] = canon_py
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
        target_text = target_path.read_text()
        configure_indent(decide_offset(target_text))
        configure_document_start(target_text)
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
    sys.stderr.write(describe_actions(gaps) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
