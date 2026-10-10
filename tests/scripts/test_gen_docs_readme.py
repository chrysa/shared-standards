"""Tests for the new-folder README gate and the code-without-doc warning (ADR D-0018)."""

from __future__ import annotations

import os
import subprocess
from pathlib import Path

import pytest

from scripts import gen_docs as g
from scripts.gen_docs_extractors import Extractor


@pytest.fixture(autouse=True)
def _hermetic_git(monkeypatch: pytest.MonkeyPatch) -> None:
    """Ignore the host's global/system git config (hooks, templates, signing)."""
    monkeypatch.setenv("GIT_CONFIG_GLOBAL", os.devnull)
    monkeypatch.setenv("GIT_CONFIG_NOSYSTEM", "1")


def _git(repo: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(repo), "-c", "user.name=t", "-c", "user.email=tests-only",
         "-c", "commit.gpgsign=false", "-c", "init.defaultBranch=main", *args],
        capture_output=True, text=True, check=True,
    )
    return result.stdout.strip()


def _write(repo: Path, rel: str, text: str = "x = 1\n") -> None:
    path = repo / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


@pytest.fixture
def repo(tmp_path: Path) -> Path:
    root = tmp_path / "r"
    root.mkdir()
    _git(root, "init", "-q")
    _write(root, "src/old/a.py")
    _write(root, "README.md", "# r\n")
    _git(root, "add", "-A")
    _git(root, "commit", "-q", "-m", "base")
    return root


def test_new_source_folder_without_readme_is_reported(repo: Path) -> None:
    _write(repo, "src/new/b.py")
    _git(repo, "add", "-A")
    assert g.new_dirs_missing_readme(repo) == ["src/new"]


def test_new_folder_with_readme_passes(repo: Path) -> None:
    _write(repo, "src/new/b.py")
    _write(repo, "src/new/README.md", "# new\n")
    _git(repo, "add", "-A")
    assert g.new_dirs_missing_readme(repo) == []


def test_existing_folder_is_never_flagged(repo: Path) -> None:
    _write(repo, "src/old/c.py")
    _git(repo, "add", "-A")
    assert g.new_dirs_missing_readme(repo) == []


def test_new_non_source_folder_is_ignored(repo: Path) -> None:
    _write(repo, "assets/logo.txt", "x\n")
    _git(repo, "add", "-A")
    assert g.new_dirs_missing_readme(repo) == []


def test_vendored_new_folder_is_ignored(repo: Path) -> None:
    _write(repo, "node_modules/pkg/index.js", "x\n")
    _write(repo, ".hidden/tool.py")
    _git(repo, "add", "-A", "-f")
    assert g.new_dirs_missing_readme(repo) == []


def test_ancestor_directories_count_as_existing(repo: Path) -> None:
    """`src/` had only `src/old/a.py` before: adding `src/top.py` must not flag `src`."""
    _write(repo, "src/top.py")
    _git(repo, "add", "-A")
    assert g.new_dirs_missing_readme(repo) == []


def test_base_mode_compares_against_a_ref(repo: Path) -> None:
    base = _git(repo, "rev-parse", "HEAD")
    _write(repo, "src/new/b.py")
    _git(repo, "add", "-A")
    _git(repo, "commit", "-q", "-m", "feature")
    assert g.new_dirs_missing_readme(repo, base) == ["src/new"]
    assert g.new_dirs_missing_readme(repo) == []


def test_repo_with_no_commit_does_not_crash(tmp_path: Path) -> None:
    """Review focus 4: the very first commit."""
    root = tmp_path / "fresh"
    root.mkdir()
    _git(root, "init", "-q")
    _write(root, "pkg/mod.py")
    _git(root, "add", "-A")
    assert g.new_dirs_missing_readme(root) == ["pkg"]


def test_non_git_directory_reports_nothing(tmp_path: Path) -> None:
    root = tmp_path / "plain"
    _write(root, "pkg/mod.py")
    assert g.new_dirs_missing_readme(root) == []
    assert g.changed_files(root) == []


def test_check_fails_and_names_the_folder(repo: Path, capsys: pytest.CaptureFixture[str]) -> None:
    _write(repo, "src/new/b.py")
    _git(repo, "add", "-A")
    assert g.main(["--check"], root=repo) == 1
    assert "new folder without README.md: src/new/" in capsys.readouterr().err


def _fake(name: str, suffix: str) -> Extractor:
    return Extractor(
        name=name,
        detect=lambda root, files: True,
        render=lambda root, files: "",
        covers=lambda path: path.endswith(suffix),
    )


def test_warning_when_covered_source_changes_without_docs() -> None:
    message = g.docs_warning(["api/routes.py", "api/util.txt"], [_fake("routes", ".py")])
    assert message is not None
    assert message.startswith("warning:")
    assert "api/routes.py" in message


def test_no_warning_when_docs_are_touched_or_nothing_is_covered() -> None:
    active = [_fake("routes", ".py")]
    assert g.docs_warning(["api/routes.py", "README.md"], active) is None
    assert g.docs_warning(["api/routes.py", "docs/guide.txt"], active) is None
    assert g.docs_warning(["api/readme.txt"], active) is None


def test_warning_never_changes_the_exit_code(repo: Path) -> None:
    _write(repo, "src/old/d.py")
    _git(repo, "add", "-A")
    assert g.main(["--check"], root=repo) == 0


def test_non_ascii_directory_is_not_bypassed(repo: Path) -> None:
    _write(repo, "src/né w/mod.py")
    _git(repo, "add", "-A")
    assert g.new_dirs_missing_readme(repo) == ["src/né w"]


def test_unknown_base_ref_raises_and_check_fails(repo: Path, capsys: pytest.CaptureFixture[str]) -> None:
    with pytest.raises(g.BaseRefError):
        g.new_dirs_missing_readme(repo, "no-such-ref")
    assert g.main(["--check", "--base", "no-such-ref"], root=repo) == 1
    assert "cannot resolve base ref: no-such-ref" in capsys.readouterr().err


def test_moved_file_counts_as_added(repo: Path) -> None:
    (repo / "src/new").mkdir()
    _git(repo, "mv", "src/old/a.py", "src/new/a.py")
    assert g.new_dirs_missing_readme(repo) == ["src/new"]
    _git(repo, "commit", "-q", "-m", "move")
    assert g.new_dirs_missing_readme(repo, "HEAD~1") == ["src/new"]


def test_untracked_readme_does_not_satisfy_the_gate(repo: Path) -> None:
    _write(repo, "n/a.py")
    _write(repo, "n/README.md", "# n\n")
    _git(repo, "add", "n/a.py")
    assert g.new_dirs_missing_readme(repo) == ["n"]
    _git(repo, "add", "n/README.md")
    assert g.new_dirs_missing_readme(repo) == []
