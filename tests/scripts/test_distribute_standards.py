"""Distribution parity + idempotency for ``scripts/distribute-standards.sh``.

A freshly-distributed consumer must receive the *slim-core standards system* exactly as
the generator produces it from the canon:

  * ``CLAUDE.md``                         — the slim CORE in a managed block,
  * ``standards/rules/<domain>.md``       — the on-demand detail behind the CORE's pointers,
  * ``AGENTS.md`` + copilot instructions  — the same rule index in their managed blocks,

with repo-specific content preserved and a second run reporting no drift. These assertions
pin the block bodies to ``gen_agent_views.emit(...)`` (the single source of rendering), so a
canon change that is not regenerated, or a bash edit that re-implements rendering, fails here.
"""

from __future__ import annotations

import subprocess
from pathlib import Path

import pytest

from scripts import gen_agent_views as gav

_ROOT = gav._ROOT
_SCRIPT = _ROOT / "scripts" / "distribute-standards.sh"
_RULES_SRC = _ROOT / "standards" / "rules"

_MARKERS = {
    "claude": (gav.CLAUDE_MARK_START, gav.CLAUDE_MARK_END),
    "agents": (gav.AGENTS_MARK_START, gav.AGENTS_MARK_END),
    "copilot": (gav.COPILOT_MARK_START, gav.COPILOT_MARK_END),
}


def _block_body(text: str, view: str) -> str:
    """Return the managed-block body (markers excluded) for ``view`` inside ``text``."""
    start, end = _MARKERS[view]
    assert start in text and end in text, f"{view} block markers missing"
    inner = text.split(start, 1)[1].split(end, 1)[0]
    return inner.strip("\n") + "\n"


def _run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", str(_SCRIPT), *args],
        capture_output=True,
        text=True,
        cwd=_ROOT,
        check=False,
    )


@pytest.fixture
def consumer(tmp_path: Path) -> Path:
    """A minimal consumer repo with pre-existing, repo-specific CLAUDE.md + AGENTS.md."""
    repo = tmp_path / "consumer"
    repo.mkdir()
    (repo / "CLAUDE.md").write_text(
        "# CLAUDE.md — consumer\n\nRepo-specific rule: keep this line.\n",
        encoding="utf-8",
    )
    (repo / "AGENTS.md").write_text(
        "# AGENTS.md\n\nLocal agent note: keep this line.\n",
        encoding="utf-8",
    )
    return repo


def test_distribution_delivers_core_rules_and_views(consumer: Path) -> None:
    result = _run("--standards-only", str(consumer))
    assert result.returncode == 0, result.stderr

    # 1a. CLAUDE.md carries the slim CORE, repo-specific content preserved.
    claude = (consumer / "CLAUDE.md").read_text(encoding="utf-8")
    assert "Repo-specific rule: keep this line." in claude
    assert _block_body(claude, "claude") == gav.emit("claude")

    # 1b. The on-demand rule detail is fanned out verbatim, at the mirrored path.
    dest_rules = consumer / "standards" / "rules"
    assert dest_rules.is_dir()
    for src in sorted(_RULES_SRC.glob("*.md")):
        dest = dest_rules / src.name
        assert dest.read_bytes() == src.read_bytes(), f"rules/{src.name} diverged"

    # 1c. AGENTS.md + Copilot carry the same core; AGENTS keeps its repo-specific line.
    agents = (consumer / "AGENTS.md").read_text(encoding="utf-8")
    assert "Local agent note: keep this line." in agents
    assert _block_body(agents, "agents") == gav.emit("agents")

    copilot = (consumer / ".github" / "copilot-instructions.md").read_text(encoding="utf-8")
    assert _block_body(copilot, "copilot") == gav.emit("copilot")


def test_distribution_is_idempotent(consumer: Path) -> None:
    assert _run("--standards-only", str(consumer)).returncode == 0
    # A second apply changes nothing …
    second = _run("--standards-only", str(consumer))
    assert second.returncode == 0
    # … and --check confirms zero drift.
    check = _run("--check", "--standards-only", str(consumer))
    assert check.returncode == 0, check.stdout + check.stderr


def test_check_reports_drift_on_a_fresh_consumer(consumer: Path) -> None:
    # Nothing distributed yet → --check must flag drift (exit 1), never a false green.
    check = _run("--check", "--standards-only", str(consumer))
    assert check.returncode == 1
