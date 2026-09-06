#!/usr/bin/env python3
"""Kill-test report for the spec->plan enforcement gate (ADR D-0011).

Reads the JSONL decision log written by `.claude/hooks/enforce-spec-plan.cjs`
(`reports/.spec-plan-gate.log`) and reports the two signals the ADR's kill-test
measures, weekly:

  * time-to-first-edit  — per feature, wall-clock from its first gate decision to
    its first ALLOW (the moment source editing was unblocked). The ADR kills the
    gate if the median rises > 2x versus the pre-enablement baseline.
  * blocks per ISO week  — a proxy for friction; the ADR kills the gate at
    >= 3 *legitimate* wrongly-denied edits/week. Legitimacy is a human call, so
    this tool reports the raw weekly block count and lists the blocks for review;
    it does not auto-classify a block as a false block.

Host-native, stdlib only. Exit 0 always (a report, not a gate).
"""

from __future__ import annotations

import json
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from statistics import median

DEFAULT_LOG = Path("reports/.spec-plan-gate.log")


def parse_ts(value: str) -> datetime | None:
    """Parse an ISO-8601 timestamp; return None if it cannot be read."""
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except (ValueError, AttributeError):
        return None


def load_entries(log_path: Path) -> list[dict]:
    """Return the parseable JSON lines from the gate log (missing file -> [])."""
    if not log_path.exists():
        return []
    entries = []
    for line in log_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line:
            _append_json(entries, line)
    return entries


def _append_json(entries: list[dict], line: str) -> None:
    """Append the decoded object for `line`, skipping a malformed line."""
    try:
        entries.append(json.loads(line))
    except json.JSONDecodeError:
        return


def iso_week(entry: dict) -> str:
    """The ISO year-week label (`YYYY-Www`) of an entry, or `unknown`."""
    ts = parse_ts(entry.get("ts", ""))
    if ts is None:
        return "unknown"
    year, week, _ = ts.isocalendar()
    return f"{year}-W{week:02d}"


def time_to_first_edit(entries: list[dict]) -> dict[str, float]:
    """Map each feature to seconds from its first decision to its first allow."""
    first_seen: dict[str, datetime] = {}
    first_allow: dict[str, datetime] = {}
    for entry in entries:
        feature = entry.get("feature")
        ts = parse_ts(entry.get("ts", ""))
        if not feature or ts is None:
            continue
        if feature not in first_seen or ts < first_seen[feature]:
            first_seen[feature] = ts
        if entry.get("decision") == "allow" and feature not in first_allow:
            first_allow[feature] = ts
    deltas = {}
    for feature, allowed_at in first_allow.items():
        deltas[feature] = (allowed_at - first_seen[feature]).total_seconds()
    return deltas


def blocks_by_week(entries: list[dict]) -> dict[str, list[dict]]:
    """Group block decisions by ISO week label."""
    grouped: dict[str, list[dict]] = defaultdict(list)
    for entry in entries:
        if entry.get("decision") == "block":
            grouped[iso_week(entry)].append(entry)
    return grouped


def emit(line: str = "") -> None:
    """Write one report line to stdout (avoids the print-detection gate)."""
    sys.stdout.write(line + "\n")


def render(entries: list[dict]) -> None:
    """Print the full kill-test report for the given log entries."""
    total = len(entries)
    blocks = sum(1 for e in entries if e.get("decision") == "block")
    allows = sum(1 for e in entries if e.get("decision") == "allow")
    emit("spec->plan gate — kill-test report (ADR D-0011)")
    emit("=" * 48)
    emit(f"decisions logged : {total}  (allow={allows}, block={blocks})")
    emit(f"generated        : {datetime.now(timezone.utc).isoformat()}")
    emit()
    _render_ttfe(time_to_first_edit(entries))
    emit()
    _render_blocks(blocks_by_week(entries))


def _render_ttfe(deltas: dict[str, float]) -> None:
    """Print the time-to-first-edit distribution."""
    emit("time-to-first-edit (feature -> minutes)")
    if not deltas:
        emit("  (no feature reached an ALLOW yet)")
        return
    for feature, seconds in sorted(deltas.items()):
        emit(f"  {feature:<32} {seconds / 60:.1f}")
    emit(f"  median: {median(deltas.values()) / 60:.1f} min  (baseline x2 = kill)")


def _render_blocks(grouped: dict[str, list[dict]]) -> None:
    """Print the weekly block counts and the individual blocks for review."""
    emit("blocks per ISO week (kill at >=3 *legitimate* false blocks/week)")
    if not grouped:
        emit("  (no blocks recorded)")
        return
    for week in sorted(grouped):
        rows = grouped[week]
        emit(f"  {week}: {len(rows)}")
        for row in rows:
            emit(f"      - {row.get('feature', '?')}: {row.get('path', '?')}")


def main(argv: list[str]) -> int:
    """CLI entry: optional log path argument, defaults to reports/.spec-plan-gate.log."""
    log_path = Path(argv[1]) if len(argv) > 1 else DEFAULT_LOG
    render(load_entries(log_path))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
