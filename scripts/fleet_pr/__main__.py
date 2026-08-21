"""CLI entrypoint: ``python -m scripts.fleet_pr``.

Default is read-only triage + report. ``--merge`` acts on the BILLING bucket
only, and stays a dry-run until ``--yes`` is given.
"""

from __future__ import annotations

import argparse
import sys

from scripts.fleet_pr.bucket import Bucket
from scripts.fleet_pr.fleet_pr import FleetPr
from scripts.fleet_pr.gateway import GhGateway
from scripts.fleet_pr.report import render


def _emit(text: str) -> None:
    sys.stdout.write(text + "\n")


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="fleet-pr", description="Triage & safely merge fleet PRs.")
    parser.add_argument("--owner", default="chrysa", help="GitHub owner (default: chrysa).")
    parser.add_argument("--repos", default="", help="Comma-separated repos; default: auto-discover.")
    parser.add_argument("--merge", action="store_true", help="Act on the BILLING bucket.")
    parser.add_argument("--yes", action="store_true", help="With --merge, actually execute (else dry-run).")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv if argv is not None else sys.argv[1:])
    gateway = GhGateway(owner=args.owner)
    fleet = FleetPr(gateway)

    repos = [r for r in (s.strip() for s in args.repos.split(",")) if r] or gateway.discover_repos()
    buckets = fleet.triage(repos)
    _emit(render(buckets))
    if fleet.errors:
        _emit("\n# UNREACHABLE (transient gh/API errors — re-run)")
        for repo, msg in fleet.errors:
            _emit(f"  {repo}: {msg}")

    if args.merge:
        billing = buckets.get(Bucket.BILLING, [])
        results = fleet.merge_billing(billing, execute=args.yes)
        _emit("\n# MERGE" if args.yes else "\n# MERGE (dry-run — pass --yes to execute)")
        for pr, outcome in results:
            _emit(f"  {pr.repo}#{pr.number}: {outcome}")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
