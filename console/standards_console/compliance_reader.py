"""Read fleet compliance from the local ``compliance/*-conformance.json`` snapshots.

This is the offline, stdio-local source (as opposed to the hosted guideline-checker
behind :mod:`compliance`). The snapshots are heterogeneous — some rows carry a
``gate`` (ok/warn/FAIL), others a ``status`` (ok) — so signals are normalised through
the referential in ``constants.yaml``. Missing files raise loudly; a stale-but-present
file is reported with its modification time so a caller never mistakes it for live truth.
"""

from __future__ import annotations

import datetime as dt
import json
from pathlib import Path
from typing import cast

from .config import Settings, constants
from .manifest import parse as parse_manifest

_SEVERITY = {"warn": 1, "fail": 2}


class ComplianceSnapshotUnavailable(RuntimeError):
    """The local compliance directory or a snapshot file is missing/unreadable."""


def _dimension(path: Path) -> str:
    return path.name.replace("-conformance.json", "")


def _signal(row: dict[str, object]) -> str | None:
    """Return the normalised conformance signal of a row, or ``None`` if absent."""
    for field in constants().standards.signal_fields:
        if field in row:
            return str(row[field]).lower()
    return None


def _severity(signal: str | None) -> int:
    if signal is None or signal in constants().standards.ok_signals:
        return 0
    return _SEVERITY.get(signal, 1)


def _snapshot_files(settings: Settings) -> list[Path]:
    directory = settings.compliance_dir_path
    files = sorted(directory.glob(constants().standards.compliance_glob))
    if not directory.is_dir() or not files:
        raise ComplianceSnapshotUnavailable(f"no compliance snapshots under {directory}")
    return files


def source_mtimes(settings: Settings | None = None) -> dict[str, str]:
    """Return ``{dimension: ISO-8601 mtime}`` so callers can surface snapshot staleness."""
    settings = settings or Settings()
    return {
        _dimension(path): dt.datetime.fromtimestamp(path.stat().st_mtime, tz=dt.UTC).isoformat()
        for path in _snapshot_files(settings)
    }


def _deviations_by_repo(settings: Settings, min_severity: int) -> dict[str, list[dict[str, str]]]:
    result: dict[str, list[dict[str, str]]] = {}
    for path in _snapshot_files(settings):
        dimension = _dimension(path)
        for row in json.loads(path.read_text(encoding="utf-8")).get("rows", []):
            signal = _signal(row)
            if _severity(signal) < max(min_severity, 1):
                continue
            entry = {"dimension": dimension, "signal": signal or "unknown"}
            result.setdefault(str(row["repo"]), []).append(entry)
    return result


def audit_status(
    section: str | None = None, min_severity: str | None = None, settings: Settings | None = None
) -> list[dict[str, object]]:
    """Return per-repo deviations across snapshots, most-deviating first.

    ``section`` filters to a single dimension; ``min_severity`` (``warn``/``fail``)
    keeps only deviations at least that severe.
    """
    settings = settings or Settings()
    floor = _SEVERITY.get((min_severity or "warn").lower(), 1)
    by_repo = _deviations_by_repo(settings, floor)
    rows = [
        {
            "repo": repo,
            "score": len(devs),
            "deviations": [d for d in devs if section is None or d["dimension"] == section],
        }
        for repo, devs in by_repo.items()
    ]
    rows = [r for r in rows if r["deviations"]]
    return sorted(rows, key=lambda r: cast(int, r["score"]), reverse=True)


def repo_diff(repo: str, settings: Settings | None = None) -> dict[str, object]:
    """Return one repo's deviations plus its ``repos.yml`` classification."""
    settings = settings or Settings()
    deviations = _deviations_by_repo(settings, 1).get(repo, [])
    manifest_text = (settings.repo_root / settings.manifest_path).read_text(encoding="utf-8")
    entry = next((e for e in parse_manifest(manifest_text) if e.name == repo), None)
    return {
        "repo": repo,
        "compliant": not deviations,
        "deviations": deviations,
        "classification": ({"status": entry.status, "runtime": entry.runtime} if entry else None),
    }
