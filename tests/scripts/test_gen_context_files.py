"""Tests for the per-repo context-files generator (scripts/gen_context_files.py, ADR D-0012).

The generator reads a repo's own content and emits four vendor-neutral context files. The
properties asserted here are the ones the ADR makes load-bearing:

  * **Real logic** — each of the four file builders (handover, context-map, llms-full,
    ai-instructions) renders the repo's actual README / pyproject / ADRs / changelog.
  * **Graceful degradation** — a repo missing a README, pyproject, changelog or ADR
    directory still generates, degrading to the ``(not available)`` sentinel, never a crash.
  * **Determinism** — generating twice yields byte-identical output (the drift gate depends
    on it), including the git-tracked path and the no-git filesystem-walk fallback.
  * **Drift mode** — ``--check`` exits 0 when the committed files are current and non-zero
    when a file is missing or stale.

Fixtures are hermetic: a small tmp repo built on disk, a throwaway ``git init`` for the
tracked-file path (staged, never committed — no author config needed), no network, no
Docker.
"""

from __future__ import annotations

import json
import subprocess
import sys
import textwrap
from pathlib import Path

from scripts import gen_context_files as g

PYPROJECT = textwrap.dedent("""\
    [project]
    name = "sample-repo"
    description = "A sample chrysa repo used by the context-files generator tests."
    dependencies = ["httpx>=0.27", "pydantic>=2"]

    [project.optional-dependencies]
    dev = ["pytest>=8"]

    [project.scripts]
    sample-cli = "sample.cli:main"

    [tool.chrysa]
    ddd = "L1"
""")

PACKAGE_JSON = textwrap.dedent("""\
    {
      "name": "sample-node",
      "main": "index.js",
      "bin": {"sample-bin": "bin.js"},
      "dependencies": {"left-pad": "^1.0.0"},
      "devDependencies": {"vitest": "^1.0.0"}
    }
""")

README = textwrap.dedent("""\
    # Sample Repo

    A human-readable sample repository for exercising the context generator.
    Tracking lives at https://www.notion.so/sample-page-abc123 for details.
""")

CLAUDE = textwrap.dedent("""\
    # CLAUDE

    <!-- chrysa:standards:start -->
    managed standards block
    <!-- chrysa:standards:end -->
""")

AGENTS = "# AGENTS\n\nAgent view for the sample repo.\n"

CHANGELOG = textwrap.dedent("""\
    # Changelog

    ## 1.2.0 - Unreleased

    - Added the context-files generator.
    - Fixed a determinism bug.

    ## 1.1.0

    - An older entry that must not leak into the latest section.
""")

ADR = textwrap.dedent("""\
    # D-0012: Ship per-repo context files

    - **Status:** Accepted
    - **Date:** 2026-09-01

    ## Context

    A fresh agent needs to know the repo without reading the code.
""")

MODULE = '"""Core sample module for the generator digest."""\n\n\ndef run() -> int:\n    return 0\n'


def _write(root: Path, rel: str, content: str) -> None:
    """Write ``content`` to ``root/rel``, creating parent directories as needed."""
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def _populate(root: Path) -> None:
    """Fill ``root`` with a realistic chrysa repo that exercises every 'present' branch."""
    _write(root, "pyproject.toml", PYPROJECT)
    _write(root, "package.json", PACKAGE_JSON)
    _write(root, "README.md", README)
    _write(root, "CLAUDE.md", CLAUDE)
    _write(root, "AGENTS.md", AGENTS)
    _write(root, "CHANGELOG.md", CHANGELOG)
    _write(root, "docs/adr/D-0012-context-files.md", ADR)
    _write(root, "docs/notes.md", "See https://www.notion.so/another-page-def456\n")
    _write(root, "sample/__init__.py", "")
    _write(root, "sample/core.py", MODULE)
    _write(root, "schemas/thing.json", "{}\n")
    _write(root, "standards/rules/quality.md", "# Quality rules\n")


def _git_track(root: Path) -> None:
    """Init a throwaway git repo and stage everything (ls-files needs staged, not committed)."""
    subprocess.run(["git", "init", "-q"], cwd=root, check=True)
    subprocess.run(["git", "add", "-A"], cwd=root, check=True)


def _full_repo(tmp_path: Path, *, with_git: bool = True) -> Path:
    """A populated repo, git-tracked by default (pass with_git=False for the walk fallback)."""
    root = tmp_path / "repo"
    root.mkdir()
    _populate(root)
    if with_git:
        _git_track(root)
    return root


class TestFileBuilders:
    def test_handover_renders_repo_facts(self, tmp_path):
        root = _full_repo(tmp_path)
        text = g.build_handover(root, g._load_pyproject(root), g._load_package_json(root))
        assert "# Handover" in text
        assert "sample-repo" in text
        assert "L1" in text
        assert "**Depends on `shared-standards`:** yes" in text
        assert "D-0012-context-files.md" in text
        assert "Accepted" in text
        assert "1.2.0" in text
        assert "An older entry" not in text  # only the latest changelog section
        assert "https://www.notion.so/sample-page-abc123" in text

    def test_context_map_is_valid_json_with_stable_keys(self, tmp_path):
        root = _full_repo(tmp_path)
        pyproject, pkg = g._load_pyproject(root), g._load_package_json(root)
        raw = g.build_context_map(root, pyproject, pkg, g.repo_files(root))
        data = json.loads(raw)
        assert data["schema"] == "chrysa.context-map/1"
        assert data["name"] == "sample-repo"
        assert data["ddd_level"] == "L1"
        assert data["depends_on_shared_standards"] is True
        assert "D-0012-context-files.md" in data["adrs"]
        assert "standards" in data["contracts"]
        assert "httpx" in json.dumps(data["dependencies"])
        assert "sample-cli" in data["entry_points"]
        assert raw == json.dumps(data, indent=2, ensure_ascii=False, sort_keys=True) + "\n"

    def test_llms_full_has_tree_config_and_modules(self, tmp_path):
        root = _full_repo(tmp_path)
        pyproject, pkg = g._load_pyproject(root), g._load_package_json(root)
        text = g.build_llms_full(root, pyproject, pkg, g.repo_files(root))
        assert "## Key configuration" in text
        assert "## Modules" in text
        assert "Core sample module for the generator digest." in text
        assert "GENERATED by scripts/gen_context_files.py" in text

    def test_ai_instructions_is_a_french_pointer(self, tmp_path):
        root = _full_repo(tmp_path)
        text = g.build_ai_instructions(root)
        assert "GENERATED by scripts/gen_context_files.py" in text
        assert "AGENTS.md" in text
        assert "CLAUDE.md" in text
        assert "canon" in text  # references the standards canon


class TestGenerateAndDrift:
    def test_generate_returns_the_four_files(self, tmp_path):
        root = _full_repo(tmp_path)
        assert set(g.generate(root)) == set(g.GENERATED_FILES)

    def test_generation_is_byte_deterministic(self, tmp_path):
        root = _full_repo(tmp_path)
        assert g.generate(root) == g.generate(root)

    def test_write_all_then_drift_is_clean(self, tmp_path):
        root = _full_repo(tmp_path)
        g.write_all(root)
        assert g.drift(root) == []
        for name in g.GENERATED_FILES:
            assert (root / name).exists()

    def test_drift_reports_a_missing_file(self, tmp_path):
        root = _full_repo(tmp_path)
        g.write_all(root)
        (root / g.HANDOVER).unlink()
        assert f"missing: {g.HANDOVER}" in g.drift(root)

    def test_drift_reports_a_stale_file(self, tmp_path):
        root = _full_repo(tmp_path)
        g.write_all(root)
        (root / g.CONTEXT_MAP).write_text("tampered\n", encoding="utf-8")
        assert f"stale: {g.CONTEXT_MAP}" in g.drift(root)


class TestGracefulDegradation:
    def test_empty_repo_degrades_to_sentinel_without_crashing(self, tmp_path):
        root = tmp_path / "bare"
        root.mkdir()
        _git_track(root)  # a git repo with no tracked files at all
        files = g.generate(root)
        assert set(files) == set(g.GENERATED_FILES)
        assert g.NA in files[g.HANDOVER]
        data = json.loads(files[g.CONTEXT_MAP])
        assert data["name"] == "bare"  # falls back to the directory basename
        assert data["depends_on_shared_standards"] is False
        assert data["adrs"] == []

    def test_no_git_falls_back_to_filesystem_walk(self, tmp_path):
        root = _full_repo(tmp_path, with_git=False)
        assert not (root / ".git").exists()
        assert g.repo_files(root)  # walk fallback still finds files
        text = g.build_llms_full(
            root, g._load_pyproject(root), g._load_package_json(root), g.repo_files(root)
        )
        assert "sample" in text  # a tracked source dir shows up in the tree/modules


class TestCli:
    def test_check_returns_zero_when_current(self, tmp_path, monkeypatch):
        root = _full_repo(tmp_path)
        g.write_all(root)
        monkeypatch.setattr(g, "_ROOT", root)
        monkeypatch.setattr(sys, "argv", ["gen_context_files", "--check"])
        assert g.main() == 0

    def test_check_returns_one_and_warns_on_drift(self, tmp_path, monkeypatch, capsys):
        root = _full_repo(tmp_path)
        g.write_all(root)
        (root / g.LLMS_FULL).write_text("drifted\n", encoding="utf-8")
        monkeypatch.setattr(g, "_ROOT", root)
        monkeypatch.setattr(sys, "argv", ["gen_context_files", "--check"])
        assert g.main() == 1
        assert "drifted" in capsys.readouterr().err

    def test_bare_invocation_writes_the_files(self, tmp_path, monkeypatch):
        root = _full_repo(tmp_path)
        monkeypatch.setattr(g, "_ROOT", root)
        monkeypatch.setattr(sys, "argv", ["gen_context_files"])
        assert g.main() == 0
        expected = g.generate(root)
        for name, content in expected.items():
            assert (root / name).read_text(encoding="utf-8") == content
