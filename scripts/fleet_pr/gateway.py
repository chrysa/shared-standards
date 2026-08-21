"""Thin, mockable wrapper over the ``gh`` CLI — the only impure edge.

Every method shells out to ``gh`` and returns plain data, so the orchestrator
and classifier stay pure and unit-testable against a fake gateway.
"""

from __future__ import annotations

import json
import subprocess
from typing import Any


class GhError(RuntimeError):
    """A ``gh`` invocation failed."""


class GhGateway:
    """Reads and (only on demand) mutates GitHub via the ``gh`` CLI."""

    def __init__(self, *, owner: str = "chrysa") -> None:
        self._owner = owner

    def _json(self, *args: str) -> Any:
        proc = subprocess.run(
            ["gh", *args],
            capture_output=True,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            raise GhError(proc.stderr.strip() or f"gh {' '.join(args)} failed")
        return json.loads(proc.stdout or "null")

    def discover_repos(self) -> list[str]:
        query = (
            "query($login:String!){user(login:$login){repositories("
            "first:100, ownerAffiliations:OWNER, isFork:false){"
            "nodes{name isArchived}}}}"
        )
        data = self._json("api", "graphql", "-f", f"login={self._owner}", "-f", f"query={query}")
        nodes = data["data"]["user"]["repositories"]["nodes"]
        return [n["name"] for n in nodes if not n["isArchived"]]

    def visibility(self, repo: str) -> str:
        data = self._json("repo", "view", f"{self._owner}/{repo}", "--json", "visibility")
        return str(data["visibility"])

    def open_prs(self, repo: str) -> list[dict]:
        data = self._json(
            "pr", "list", "--repo", f"{self._owner}/{repo}", "--state", "open",
            "--json", "number,title,headRefName,headRefOid,mergeStateStatus",
        )
        return list(data)

    def open_issues(self, repo: str) -> list[dict]:
        data = self._json(
            "issue", "list", "--repo", f"{self._owner}/{repo}", "--state", "open",
            "--json", "number,title,labels",
        )
        return list(data)

    def failing_job_steps(self, repo: str, head_sha: str) -> tuple[int, ...]:
        """Step counts of every *failing* job across the PR head's runs.

        ``0`` = the job never started (startup_failure) = billing signature.
        """
        runs = self._json(
            "run", "list", "--repo", f"{self._owner}/{repo}", "--limit", "40",
            "--json", "databaseId,headSha,conclusion",
        )
        ids = [
            r["databaseId"]
            for r in runs
            if r.get("headSha") == head_sha and r.get("conclusion") == "failure"
        ]
        steps: list[int] = []
        for run_id in ids:
            detail = self._json(
                "run", "view", str(run_id), "--repo", f"{self._owner}/{repo}", "--json", "jobs",
            )
            for job in detail["jobs"]:
                if job.get("conclusion") == "failure":
                    steps.append(len(job.get("steps") or []))
        return tuple(steps)

    def merge_squash(self, repo: str, number: int) -> None:
        proc = subprocess.run(
            ["gh", "pr", "merge", str(number), "--repo", f"{self._owner}/{repo}", "--squash"],
            capture_output=True,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            raise GhError(proc.stderr.strip() or f"merge {repo}#{number} failed")
