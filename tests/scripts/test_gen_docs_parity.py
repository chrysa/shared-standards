"""templates/ is the source of truth for the distributed generators; scripts/ is the dogfood copy."""

from __future__ import annotations

from pathlib import Path

import pytest

_ROOT = Path(__file__).resolve().parents[2]


@pytest.mark.parametrize("name", ["gen_docs.py", "gen_docs_extractors.py"])
def test_scripts_copy_matches_template(name: str) -> None:
    assert (_ROOT / "scripts" / name).read_bytes() == (_ROOT / "templates" / name).read_bytes()
