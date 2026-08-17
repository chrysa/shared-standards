"""Drift gate: the GV-015 prose table and standards/domains.yaml are one source.

GV-015 (``standards/annexes/GOVERNANCE.md``) is the human-readable domain⇄home⇄prefix
table; ``standards/domains.yaml`` is its machine-readable form. They must not diverge.
This gate parses both and fails if the domain→prefix mapping disagrees, so an edit to one
without the other is caught at commit time (GV-030 single-source discipline).

Run: ``python -m scripts.check_domains_drift`` (pre-commit ``domains-drift`` hook).
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

import yaml

_ROOT = Path(__file__).resolve().parent.parent
_GOVERNANCE = _ROOT / "standards" / "annexes" / "GOVERNANCE.md"
_DOMAINS = _ROOT / "standards" / "domains.yaml"

# A GV-015 table row: | `STD-DATA-001` | `DATA-MIGRATIONS.md` | `DA-` |
_ROW = re.compile(
    r"^\|\s*`(STD-[A-Z][A-Z-]*-\d+)`\s*\|[^|]*\|\s*(.+?)\s*\|\s*$",
    re.MULTILINE,
)


class DomainsDriftError(Exception):
    """The GV-015 table and domains.yaml disagree on a domain's prefix."""


def _normalise_prefix(raw: str) -> str:
    """Strip backticks/spaces; keep only the prefix token(s) for comparison."""
    return raw.replace("`", "").strip()


def _prose_mapping() -> dict[str, str]:
    text = _GOVERNANCE.read_text(encoding="utf-8")
    return {domain: _normalise_prefix(prefix) for domain, prefix in _ROW.findall(text)}


def _yaml_mapping() -> dict[str, str]:
    data = yaml.safe_load(_DOMAINS.read_text(encoding="utf-8"))
    return {entry["id"]: _normalise_prefix(entry["prefix"]) for entry in data["domains"]}


def check() -> list[str]:
    """Return a list of human-readable drift lines (empty when in sync)."""
    prose = _prose_mapping()
    registry = _yaml_mapping()
    problems: list[str] = []
    for domain in sorted(set(prose) - set(registry)):
        problems.append(f"{domain}: in GV-015 table but missing from domains.yaml")
    for domain in sorted(set(registry) - set(prose)):
        problems.append(f"{domain}: in domains.yaml but missing from GV-015 table")
    for domain in sorted(set(prose) & set(registry)):
        if prose[domain] != registry[domain]:
            problems.append(
                f"{domain}: prefix mismatch — GV-015={prose[domain]!r} "
                f"vs domains.yaml={registry[domain]!r}"
            )
    return problems


def main() -> int:
    problems = check()
    if not problems:
        return 0
    sys.stderr.write(
        "GV-015 table (GOVERNANCE.md) and standards/domains.yaml have drifted:\n"
    )
    for line in problems:
        sys.stderr.write(f"  - {line}\n")
    sys.stderr.write("Edit both together — they are one source in two forms (GV-015).\n")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
