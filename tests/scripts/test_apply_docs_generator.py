"""apply-repo-standard.sh must sync the docs generator and announce it in --dry-run (ADR D-0018)."""

from __future__ import annotations

import subprocess
from pathlib import Path

_ROOT = Path(__file__).resolve().parents[2]
_SCRIPT = _ROOT / "scripts" / "apply-repo-standard.sh"
_GITATTRIBUTES = _ROOT / "templates" / ".gitattributes"


def test_dry_run_announces_the_docs_generator(tmp_path: Path) -> None:
    repo = tmp_path / "consumer"
    repo.mkdir()
    subprocess.run(["git", "-C", str(repo), "init", "-q"], check=True)
    (repo / "pyproject.toml").write_text('[project]\nname = "consumer"\n', encoding="utf-8")
    result = subprocess.run(
        ["bash", str(_SCRIPT), "--dry-run", str(repo)],
        capture_output=True, text=True, cwd=_ROOT, check=False,
    )
    assert "gen_docs.py" in result.stdout + result.stderr
    assert not (repo / "scripts" / "gen_docs.py").exists()


def test_gitattributes_template_pins_generated_docs_to_lf() -> None:
    """Generated docs/reference/* are compared byte-exactly, so consumers must get LF checkouts."""
    lines = _GITATTRIBUTES.read_text(encoding="utf-8").splitlines()
    assert "docs/reference/** text eol=lf" in lines
