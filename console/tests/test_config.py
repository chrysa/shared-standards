from pathlib import Path

import pytest

from standards_console.config import (
    ConfigError,
    Settings,
    _repo_root_from,
    constants,
    resolve_token,
)


def test_constants_load_and_validate():
    c = constants()
    assert c.github.api_base_url.startswith("https://")
    assert "dev" in c.manifest.valid_status
    assert c.distribution.sync_pr_branch


def test_settings_env_aliases(monkeypatch):
    monkeypatch.setenv("STANDARDS_ORG", "acme")
    monkeypatch.setenv("CONSOLE_PORT", "9000")
    s = Settings()
    assert s.org == "acme"
    assert s.port == 9000
    assert s.standards_full_name == "acme/shared-standards"


def test_repo_root_from_checkout_layout():
    # <repo>/console/standards_console/config.py -> <repo>
    here = Path("/home/x/repo/console/standards_console/config.py")
    assert _repo_root_from(here) == Path("/home/x/repo")


def test_repo_root_from_shallow_path_does_not_raise():
    # Installed shallow inside a container (regression: parents[2] IndexError).
    assert _repo_root_from(Path("/standards_console/config.py")) == Path("/standards_console")


def test_resolve_token_from_env(monkeypatch):
    monkeypatch.setenv("GITHUB_TOKEN", "tok-123")
    assert resolve_token() == "tok-123"


def test_resolve_token_missing(monkeypatch):
    monkeypatch.delenv("GITHUB_TOKEN", raising=False)
    monkeypatch.delenv("GH_TOKEN", raising=False)
    monkeypatch.setattr("standards_console.config.shutil.which", lambda _: None)
    with pytest.raises(ConfigError):
        resolve_token()
