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


# The per-repo Claude copies (layers 3-4) that --core-only leaves to the chrysa-standards plugin.
_CLAUDE_COPIES = {
    ".claude/skills": _ROOT / ".claude" / "skills",
    ".claude/agents": _ROOT / "templates" / "claude" / "agents",
    ".claude/commands": _ROOT / "templates" / "claude" / "commands",
    ".claude/workflows": _ROOT / "templates" / "claude" / "workflows",
}


def test_core_only_skips_the_claude_copies(consumer: Path) -> None:
    # --no-apply keeps the test off apply-repo-standard.sh (layer 5), as in the other tests.
    result = _run("--core-only", "--no-apply", str(consumer))
    assert result.returncode == 0, result.stderr
    assert "skipped (--core-only)" in result.stdout
    for rel in _CLAUDE_COPIES:
        assert not (consumer / rel).exists(), f"{rel} copied despite --core-only"

    # The rules system and the other layers are still delivered.
    claude = (consumer / "CLAUDE.md").read_text(encoding="utf-8")
    assert _block_body(claude, "claude") == gav.emit("claude")
    agents = (consumer / "AGENTS.md").read_text(encoding="utf-8")
    assert _block_body(agents, "agents") == gav.emit("agents")
    assert sorted(p.name for p in (consumer / "standards" / "rules").glob("*.md")) == sorted(
        p.name for p in _RULES_SRC.glob("*.md")
    )
    assert (consumer / "opencode.json").read_bytes() == (
        _ROOT / "templates" / "opencode.json"
    ).read_bytes()
    assert "chrysa:opencode-env:start" in (consumer / ".env.example").read_text(encoding="utf-8")

    # The skipped copies are not drift for a core-only repo.
    check = _run("--check", "--core-only", "--no-apply", str(consumer))
    assert check.returncode == 0, check.stdout + check.stderr


def test_default_run_still_copies_the_claude_assets(consumer: Path) -> None:
    # Without --core-only nothing changes: every shared agent, command and workflow template
    # lands as a byte-identical copy, and the shared skills are copied.
    result = _run("--no-apply", str(consumer))
    assert result.returncode == 0, result.stderr
    assert "--core-only" not in result.stdout
    for rel, src_dir in _CLAUDE_COPIES.items():
        dest_dir = consumer / rel
        assert dest_dir.is_dir(), f"{rel} missing from the default run"
        if rel == ".claude/skills":
            continue  # profile-scoped: only the skills tagged for this repo travel
        for src in sorted(p for p in src_dir.rglob("*") if p.is_file()):
            dest = dest_dir / src.relative_to(src_dir)
            assert dest.read_bytes() == src.read_bytes(), f"{dest} diverged"
    assert _run("--check", "--no-apply", str(consumer)).returncode == 0
