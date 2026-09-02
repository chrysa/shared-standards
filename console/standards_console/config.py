"""Typed configuration: env-driven settings + a YAML constants referential.

Per the chrysa standard, no constant is inlined in code. Tunable referential
values live in ``constants.yaml`` and are read through the typed :class:`Constants`
model; deployment settings come from the environment via :class:`Settings`
(Pydantic Settings). The GitHub token is resolved from the env or ``gh`` — never
stored.
"""

from __future__ import annotations

import shutil
import subprocess
from functools import lru_cache
from pathlib import Path

from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings, SettingsConfigDict
from ruamel.yaml import YAML

_CONSTANTS_PATH = Path(__file__).parent / "constants.yaml"


class ConfigError(RuntimeError):
    """Raised when required configuration cannot be resolved."""


_REPO_ROOT_DEPTH = 2  # <repo>/console/standards_console/<file> — the repo is 2 parents up


def _repo_root_from(here: Path) -> Path:
    """Repo root ``_REPO_ROOT_DEPTH`` levels above ``here``.

    Layout: ``<repo>/console/standards_console/<file>``. Falls back to the immediate
    parent when the package sits too shallow to have enough ancestors — e.g. installed
    at ``/standards_console`` inside a container — so importing this module never raises.
    Such callers set ``STANDARDS_REPO_ROOT`` explicitly.
    """
    return here.parents[_REPO_ROOT_DEPTH] if len(here.parents) > _REPO_ROOT_DEPTH else here.parent


def _default_repo_root() -> Path:
    return _repo_root_from(Path(__file__).resolve())


# ── YAML constants referential ─────────────────────────────────────────────────
class GitHubConstants(BaseModel):
    api_base_url: str
    api_version: str
    request_timeout_seconds: float
    per_page: int


class ManifestConstants(BaseModel):
    valid_status: tuple[str, ...]
    valid_runtime: tuple[str, ...]


class DistributionConstants(BaseModel):
    sync_pr_branch: str
    default_run_limit: int


class PullRequestConstants(BaseModel):
    standards_labels: list[str]


class ComplianceConstants(BaseModel):
    request_timeout_seconds: float
    repos_endpoint: str


class StandardsConstants(BaseModel):
    """Referential for the read-only standards MCP surface (paths relative to repo root)."""

    thresholds_file: str
    standard_files: tuple[str, ...]
    compliance_dir: str
    compliance_glob: str
    ok_signals: tuple[str, ...]
    signal_fields: tuple[str, ...]


class Constants(BaseModel):
    github: GitHubConstants
    manifest: ManifestConstants
    distribution: DistributionConstants
    pull_request: PullRequestConstants
    compliance: ComplianceConstants
    standards: StandardsConstants


@lru_cache(maxsize=1)
def constants() -> Constants:
    """Load and validate the YAML referential once."""
    data = YAML(typ="safe").load(_CONSTANTS_PATH.read_text(encoding="utf-8"))
    return Constants.model_validate(data)


# ── env-driven deployment settings ──────────────────────────────────────────────
class Settings(BaseSettings):
    """Runtime settings. Defaults point at the chrysa standards fleet."""

    model_config = SettingsConfigDict(populate_by_name=True, extra="ignore")

    org: str = Field(default="chrysa", validation_alias="STANDARDS_ORG")
    standards_repo: str = Field(default="shared-standards", validation_alias="STANDARDS_REPO")
    standards_branch: str = Field(default="main", validation_alias="STANDARDS_BRANCH")
    standard_path: str = Field(
        default="standards/STANDARDS.chrysa.md", validation_alias="STANDARDS_FILE"
    )
    manifest_path: str = Field(default="repos.yml", validation_alias="STANDARDS_MANIFEST")
    distribute_workflow: str = Field(
        default="distribute-standards.yml", validation_alias="STANDARDS_DISTRIBUTE_WORKFLOW"
    )
    central_base_url: str | None = Field(default=None, validation_alias="GUIDELINE_CENTRAL_URL")
    central_api_key: str | None = Field(default=None, validation_alias="GUIDELINE_CENTRAL_API_KEY")
    host: str = Field(default="127.0.0.1", validation_alias="CONSOLE_HOST")
    port: int = Field(default=8765, validation_alias="CONSOLE_PORT")
    repo_root: Path = Field(
        default_factory=_default_repo_root, validation_alias="STANDARDS_REPO_ROOT"
    )

    @property
    def compliance_dir_path(self) -> Path:
        return self.repo_root / constants().standards.compliance_dir

    @property
    def standard_file_paths(self) -> tuple[Path, ...]:
        return tuple(self.repo_root / f for f in constants().standards.standard_files)

    @property
    def standards_full_name(self) -> str:
        return f"{self.org}/{self.standards_repo}"

    @property
    def thresholds_path(self) -> Path:
        return self.repo_root / constants().standards.thresholds_file


def resolve_token() -> str:
    """Return a GitHub token from the env, falling back to ``gh auth token``."""
    import os

    for var in ("GITHUB_TOKEN", "GH_TOKEN"):
        token = os.environ.get(var)
        if token:
            return token.strip()
    gh = shutil.which("gh")
    if not gh:
        raise ConfigError(
            "No GitHub token found. Set GITHUB_TOKEN/GH_TOKEN or run `gh auth login`."
        )
    try:
        out = subprocess.run(  # fixed argv, no shell
            [gh, "auth", "token"],
            capture_output=True,
            text=True,
            check=True,
            timeout=10,
        )
    except (subprocess.SubprocessError, OSError) as exc:
        raise ConfigError(f"`gh auth token` failed: {exc}") from exc
    token = out.stdout.strip()
    if not token:
        raise ConfigError("`gh auth token` returned empty output.")
    return token
