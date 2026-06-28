"""Wire settings + gateway + the four service objects together.

A single container so the web layer depends on one thing it can build (live) or
inject (tests). Keeping construction here keeps :mod:`app` free of plumbing.
"""

from __future__ import annotations

from dataclasses import dataclass

from .compliance import ComplianceClient
from .config import Settings, constants, resolve_token
from .distribution import DistributionController
from .github_gateway import GitHubGateway
from .standard import StandardService


@dataclass
class Services:
    settings: Settings
    gateway: GitHubGateway
    distribution: DistributionController
    standard: StandardService
    compliance: ComplianceClient

    @classmethod
    def build(cls, settings: Settings | None = None) -> Services:
        settings = settings or Settings()
        gh = constants().github
        gateway = GitHubGateway(
            resolve_token(),
            base_url=gh.api_base_url,
            api_version=gh.api_version,
            timeout=gh.request_timeout_seconds,
            per_page=gh.per_page,
        )
        return cls.from_gateway(settings, gateway)

    @classmethod
    def from_gateway(cls, settings: Settings, gateway: GitHubGateway) -> Services:
        repo = settings.standards_full_name
        return cls(
            settings=settings,
            gateway=gateway,
            distribution=DistributionController(
                gateway,
                repo=repo,
                workflow=settings.distribute_workflow,
                ref=settings.standards_branch,
            ),
            standard=StandardService(gateway, repo=repo, base_branch=settings.standards_branch),
            compliance=ComplianceClient(settings.central_base_url, settings.central_api_key),
        )

    # ── manifest helpers (read live, commit direct) ─────────────────────────────
    def read_manifest_text(self) -> tuple[str, str]:
        """Return (text, sha) of the live manifest on the default branch."""
        f = self.gateway.get_file(
            self.settings.standards_full_name,
            self.settings.manifest_path,
            ref=self.settings.standards_branch,
        )
        return f.text, f.sha

    def commit_manifest(self, *, text: str, sha: str, message: str) -> str:
        return self.gateway.put_file(
            self.settings.standards_full_name,
            self.settings.manifest_path,
            text=text,
            message=message,
            branch=self.settings.standards_branch,
            sha=sha,
        )
