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


def _hook_handlers() -> list[dict]:
    config = json.loads((PLUGIN / "hooks" / "hooks.json").read_text(encoding="utf-8"))
    return [h for groups in config["hooks"].values() for group in groups for h in group["hooks"]]


def test_plugin_hooks_run_bundled_scripts() -> None:
    prefix = "${CLAUDE_PLUGIN_ROOT}/"
    scripts = [arg for h in _hook_handlers() for arg in h.get("args", []) if arg.startswith(prefix)]
    assert sorted(Path(s).name for s in scripts) == ["pre-compact.sh", "read_guard.py", "session-context.sh"]
    for arg in scripts:
        assert (PLUGIN / arg.removeprefix(prefix)).is_file(), arg


def test_read_guard_blocks_only_large_whole_file_reads(tmp_path: Path) -> None:
    guard = PLUGIN / "hooks" / "read_guard.py"
    big = tmp_path / "big.txt"
    big.write_bytes(b"x" * (300 * 1024))
    small = tmp_path / "small.txt"
    small.write_text("ok", encoding="utf-8")

    def run(tool_input: dict) -> int:
        payload = json.dumps({"tool_input": tool_input})
        return subprocess.run(["python3", str(guard)], input=payload, capture_output=True, text=True, check=False).returncode

    assert run({"file_path": str(big)}) == 2
    assert run({"file_path": str(big), "limit": 50}) == 0
    assert run({"file_path": str(small)}) == 0
