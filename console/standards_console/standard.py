"""Edit the canonical standard and copilot instructions via a pull request.

Standard edits are content-heavy and reviewable, so they never commit to the
default branch directly: this service stages the change on a fresh branch and
opens a PR. ``repos.yml`` status flips are handled by :mod:`manifest` with a
direct commit instead.
"""

from __future__ import annotations

from dataclasses import dataclass

from .config import constants
from .github_gateway import GitHubGateway


@dataclass(frozen=True)
class StandardEdit:
    """The outcome of opening a standard-edit PR."""

    pr_number: int
    pr_url: str
    branch: str


def _slug(text: str) -> str:
    return "".join(c if c.isalnum() else "-" for c in text.lower()).strip("-")[:40]


class StandardService:
    def __init__(self, gateway: GitHubGateway, *, repo: str, base_branch: str) -> None:
        self._gw = gateway
        self._repo = repo
        self._base = base_branch

    def read(self, path: str) -> str:
        return self._gw.get_file(self._repo, path, ref=self._base).text

    def propose_edit(
        self, path: str, *, new_text: str, summary: str, branch_id: str
    ) -> StandardEdit:
        """Open a PR that sets ``path`` to ``new_text`` on a new branch.

        ``branch_id`` makes the branch name unique and deterministic (the caller
        supplies it, e.g. a timestamp) so retries don't collide silently.
        """
        branch = f"console/edit-{_slug(path)}-{branch_id}"
        base_sha = self._gw.get_branch_sha(self._repo, self._base)
        self._gw.create_branch(self._repo, new_branch=branch, from_sha=base_sha)

        current = self._gw.get_file(self._repo, path, ref=branch)
        self._gw.put_file(
            self._repo,
            path,
            text=new_text,
            message=f"docs(standards): {summary}",
            branch=branch,
            sha=current.sha,
        )
        pr = self._gw.open_pull_request(
            self._repo,
            head=branch,
            base=self._base,
            title=f"docs(standards): {summary}",
            body=(
                f"Edited `{path}` via the standards console.\n\n"
                "Review the diff before merging — distribution to the fleet "
                "happens after this lands."
            ),
            labels=list(constants().pull_request.standards_labels),
        )
        return StandardEdit(pr_number=pr["number"], pr_url=pr["html_url"], branch=branch)
