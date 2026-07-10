"""Shared fixtures: a fake gateway and a wired Services for app-level tests."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import pytest

from standards_console.config import Settings
from standards_console.github_gateway import FileContent, Repo
from standards_console.services import Services

STD_MANIFEST = """\
# repos.yml — fleet classification.
repos:
  - name: alpha
    status: dev
    public: true
    runtime: container
  - name: gamma
    status: dev
    public: false
    runtime: exempt:native
"""

STD_STANDARD = (
    "# Transverse standards\n\n"
    "## Quality gates\n\nCoverage >= 85%.\n\n"
    "### Not a section\n\nSub-heading text.\n\n"
    "## Commits\n\nConventional Commits.\n"
)


def _write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


@pytest.fixture
def std_settings(tmp_path: Path) -> Settings:
    """A Settings pointing at a minimal on-disk standards repo (offline fixtures)."""
    _write(
        tmp_path / ".claude/thresholds.json",
        json.dumps({"_notes": {"x": "doc"}, "max_file_lines": 500, "max_function_lines": 50}),
    )
    _write(tmp_path / "standards/STANDARDS.chrysa.md", STD_STANDARD)
    _write(tmp_path / ".chrysa/STANDARDS.md", "## Stack\n\nPython 3.14 target.\n")
    _write(
        tmp_path / "compliance/makefile-conformance.json",
        json.dumps(
            {
                "rows": [
                    {"repo": "alpha", "gate": "ok"},
                    {"repo": "beta", "gate": "warn"},
                    {"repo": "gamma", "gate": "FAIL"},
                ]
            }
        ),
    )
    _write(
        tmp_path / "compliance/cliff-conformance.json",
        json.dumps(
            {"rows": [{"repo": "alpha", "status": "ok"}, {"repo": "gamma", "status": "ok"}]}
        ),
    )
    _write(tmp_path / "repos.yml", STD_MANIFEST)
    return Settings(repo_root=tmp_path)


MANIFEST = """\
# repos.yml — fleet classification. Header comment that MUST survive edits.
repos:
  - name: alpha
    status: dev
    public: true
    runtime: container
  - name: beta
    status: non-dev
    public: false
    runtime: exempt:config
"""

STANDARD = "# Standard\n\n- coverage >= 85%\n"


class FakeGateway:
    """In-memory stand-in for GitHubGateway, recording write calls."""

    def __init__(self) -> None:
        self.files: dict[tuple[str, str], FileContent] = {}
        self.dispatched: list[dict[str, Any]] = []
        self.branches: list[dict[str, Any]] = []
        self.pulls_opened: list[dict[str, Any]] = []
        self.runs: list[dict[str, Any]] = []
        self._fleet: list[Repo] = []

    # seeding helpers
    def seed_file(self, repo: str, path: str, text: str, sha: str = "sha0") -> None:
        self.files[(repo, path)] = FileContent(path=path, text=text, sha=sha)

    def seed_fleet(self, *repos: Repo) -> None:
        self._fleet = list(repos)

    # gateway interface
    def list_fleet(self, org: str) -> list[Repo]:
        return self._fleet

    def get_file(self, repo: str, path: str, *, ref: str) -> FileContent:
        return self.files[(repo, path)]

    def put_file(
        self, repo: str, path: str, *, text: str, message: str, branch: str, sha: str
    ) -> str:
        self.files[(repo, path)] = FileContent(path=path, text=text, sha="sha-new")
        return "commit-sha"

    def get_branch_sha(self, repo: str, branch: str) -> str:
        return "base-sha"

    def create_branch(self, repo: str, *, new_branch: str, from_sha: str) -> None:
        self.branches.append({"repo": repo, "branch": new_branch, "from": from_sha})

    def open_pull_request(
        self, repo: str, *, head: str, base: str, title: str, body: str, labels=None
    ):
        pr = {"number": 42, "html_url": "https://gh/pr/42", "head": head, "title": title}
        self.pulls_opened.append(pr)
        return pr

    def list_open_pulls(self, repo: str, *, head_branch: str | None = None):
        return []

    def dispatch_workflow(self, repo: str, workflow: str, *, ref: str, inputs):
        self.dispatched.append({"repo": repo, "workflow": workflow, "ref": ref, "inputs": inputs})

    def list_workflow_runs(self, repo: str, workflow: str, *, limit: int = 10):
        return self.runs


@pytest.fixture
def settings() -> Settings:
    return Settings(
        org="chrysa",
        standards_repo="shared-standards",
        standards_branch="main",
        standard_path="standards/STANDARDS.chrysa.md",
        manifest_path="repos.yml",
        distribute_workflow="distribute-standards.yml",
        central_base_url=None,
        central_api_key=None,
        host="127.0.0.1",
        port=8765,
    )


@pytest.fixture
def gateway() -> FakeGateway:
    gw = FakeGateway()
    gw.seed_file("chrysa/shared-standards", "repos.yml", MANIFEST)
    gw.seed_file("chrysa/shared-standards", "standards/STANDARDS.chrysa.md", STANDARD)
    gw.seed_fleet(
        Repo("alpha", "main", True, False, "https://gh/alpha", "2026-06-28T00:00:00Z"),
        Repo("beta", "main", False, False, "https://gh/beta", "2026-06-27T00:00:00Z"),
    )
    return gw


@pytest.fixture
def services(settings: Settings, gateway: FakeGateway) -> Services:
    return Services.from_gateway(settings, gateway)  # type: ignore[arg-type]
