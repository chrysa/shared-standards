"""The single point of contact with the GitHub REST API.

No other module talks to GitHub directly. The gateway exposes exactly the
operations the console needs: read the live fleet, read/write a file, open a
PR, trigger a workflow, and list recent runs and pull requests. Every failure
is surfaced as :class:`GitHubError` — nothing is swallowed.
"""

from __future__ import annotations

import base64
from dataclasses import dataclass
from typing import Any

import httpx


class GitHubError(RuntimeError):
    """A GitHub API call failed. Carries status code and message."""

    def __init__(self, status_code: int, message: str) -> None:
        super().__init__(f"GitHub API {status_code}: {message}")
        self.status_code = status_code
        self.message = message


@dataclass(frozen=True)
class FileContent:
    """A file read from a repo: decoded text plus its blob SHA (for writes)."""

    path: str
    text: str
    sha: str


@dataclass(frozen=True)
class Repo:
    name: str
    default_branch: str
    private: bool
    archived: bool
    html_url: str
    pushed_at: str


class GitHubGateway:
    def __init__(
        self,
        token: str,
        *,
        base_url: str,
        api_version: str,
        timeout: float,
        per_page: int,
        client: httpx.Client | None = None,
    ) -> None:
        self._per_page = per_page
        self._client = client or httpx.Client(
            base_url=base_url,
            timeout=timeout,
            headers={
                "Authorization": f"Bearer {token}",
                "Accept": "application/vnd.github+json",
                "X-GitHub-Api-Version": api_version,
            },
        )

    def close(self) -> None:
        self._client.close()

    # ── low-level ────────────────────────────────────────────────────────────
    def _request(self, method: str, url: str, **kwargs: Any) -> httpx.Response:
        try:
            resp = self._client.request(method, url, **kwargs)
        except httpx.HTTPError as exc:  # network/timeout
            raise GitHubError(0, str(exc)) from exc
        if resp.status_code >= httpx.codes.BAD_REQUEST:
            detail = resp.json().get("message", resp.text) if resp.content else resp.text
            raise GitHubError(resp.status_code, detail)
        return resp

    def _paginate(self, url: str, **params: Any) -> list[dict[str, Any]]:
        items: list[dict[str, Any]] = []
        next_url: str | None = url
        query: dict[str, Any] | None = {"per_page": self._per_page, **params}
        while next_url:
            resp = self._request("GET", next_url, params=query)
            items.extend(resp.json())
            next_url = resp.links.get("next", {}).get("url")
            query = None  # the `next` link already carries the query
        return items

    # ── fleet ────────────────────────────────────────────────────────────────
    def list_fleet(self, org: str) -> list[Repo]:
        """Return every (non-fork) repo of the org, live from the API."""
        raw = self._paginate(f"/orgs/{org}/repos", type="all", sort="pushed")
        return [
            Repo(
                name=r["name"],
                default_branch=r["default_branch"],
                private=r["private"],
                archived=r["archived"],
                html_url=r["html_url"],
                pushed_at=r["pushed_at"],
            )
            for r in raw
            if not r["fork"]
        ]

    # ── files ────────────────────────────────────────────────────────────────
    def get_file(self, repo: str, path: str, *, ref: str) -> FileContent:
        resp = self._request("GET", f"/repos/{repo}/contents/{path}", params={"ref": ref})
        payload = resp.json()
        text = base64.b64decode(payload["content"]).decode("utf-8")
        return FileContent(path=path, text=text, sha=payload["sha"])

    def put_file(
        self,
        repo: str,
        path: str,
        *,
        text: str,
        message: str,
        branch: str,
        sha: str,
    ) -> str:
        """Commit ``text`` to ``path`` on ``branch``. ``sha`` must match HEAD."""
        body = {
            "message": message,
            "content": base64.b64encode(text.encode("utf-8")).decode("ascii"),
            "branch": branch,
            "sha": sha,
        }
        resp = self._request("PUT", f"/repos/{repo}/contents/{path}", json=body)
        return resp.json()["commit"]["sha"]

    # ── branches & PRs ─────────────────────────────────────────────────────────
    def get_branch_sha(self, repo: str, branch: str) -> str:
        resp = self._request("GET", f"/repos/{repo}/git/ref/heads/{branch}")
        return resp.json()["object"]["sha"]

    def create_branch(self, repo: str, *, new_branch: str, from_sha: str) -> None:
        self._request(
            "POST",
            f"/repos/{repo}/git/refs",
            json={"ref": f"refs/heads/{new_branch}", "sha": from_sha},
        )

    def open_pull_request(
        self,
        repo: str,
        *,
        head: str,
        base: str,
        title: str,
        body: str,
        labels: list[str] | None = None,
    ) -> dict[str, Any]:
        resp = self._request(
            "POST",
            f"/repos/{repo}/pulls",
            json={"head": head, "base": base, "title": title, "body": body},
        )
        pr = resp.json()
        if labels:
            self._request(
                "POST",
                f"/repos/{repo}/issues/{pr['number']}/labels",
                json={"labels": labels},
            )
        return pr

    def list_open_pulls(self, repo: str, *, head_branch: str | None = None) -> list[dict[str, Any]]:
        pulls = self._paginate(f"/repos/{repo}/pulls", state="open")
        if head_branch:
            pulls = [p for p in pulls if p["head"]["ref"] == head_branch]
        return pulls

    # ── workflows ──────────────────────────────────────────────────────────────
    def dispatch_workflow(
        self, repo: str, workflow: str, *, ref: str, inputs: dict[str, str]
    ) -> None:
        self._request(
            "POST",
            f"/repos/{repo}/actions/workflows/{workflow}/dispatches",
            json={"ref": ref, "inputs": inputs},
        )

    def list_workflow_runs(
        self, repo: str, workflow: str, *, limit: int = 10
    ) -> list[dict[str, Any]]:
        resp = self._request(
            "GET",
            f"/repos/{repo}/actions/workflows/{workflow}/runs",
            params={"per_page": limit},
        )
        return resp.json().get("workflow_runs", [])
