"""The generated chrysa-standards plugin matches the canon it is built from."""

from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PLUGIN = ROOT / "plugins" / "chrysa-standards"


def test_plugin_is_up_to_date_with_the_canon() -> None:
    result = subprocess.run(
        ["bash", str(ROOT / "scripts" / "build-claude-plugin.sh"), "--check"],
        capture_output=True, text=True, check=False,
    )
    assert result.returncode == 0, result.stdout + result.stderr


def test_marketplace_points_at_the_plugin() -> None:
    market = json.loads((ROOT / ".claude-plugin" / "marketplace.json").read_text(encoding="utf-8"))
    entry = next(p for p in market["plugins"] if p["name"] == "chrysa-standards")
    manifest = json.loads((PLUGIN / ".claude-plugin" / "plugin.json").read_text(encoding="utf-8"))
    assert (ROOT / entry["source"]).resolve() == PLUGIN.resolve()
    assert manifest["name"] == entry["name"]


def test_no_command_shadows_a_skill() -> None:
    commands = {p.stem for p in (PLUGIN / "commands").glob("*.md")}
    skills = {p.name for p in (PLUGIN / "skills").iterdir() if p.is_dir()}
    assert not commands & skills
