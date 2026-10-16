"""audit-changelog.sh classifies repos by the presence of CHANGELOG.md (gh stubbed)."""

import os
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SHA = "a" * 40
FLEET = "- name: has\n  status: dev\n- name: lacks\n  status: dev\n- name: old\n  status: archived\n"


def _run(tmp_path: Path, *args: str) -> subprocess.CompletedProcess:
    # Copy the script next to its own lib and a fake fleet: it resolves repos.yml from its location.
    (tmp_path / "scripts" / "lib").mkdir(parents=True)
    shutil.copy(ROOT / "scripts" / "audit-changelog.sh", tmp_path / "scripts")
    shutil.copy(ROOT / "scripts" / "lib" / "canonical.sh", tmp_path / "scripts" / "lib")
    (tmp_path / "repos.yml").write_text(FLEET)
    stub = tmp_path / "bin" / "gh"
    stub.parent.mkdir()
    stub.write_text(f'#!/usr/bin/env bash\n[[ "$2" == *"/has/"* ]] && echo {SHA} || exit 1\n')
    stub.chmod(0o755)
    env = {**os.environ, "PATH": f"{stub.parent}:{os.environ['PATH']}"}
    return subprocess.run(
        ["bash", str(tmp_path / "scripts" / "audit-changelog.sh"), *args],
        capture_output=True, text=True, env=env, check=False,
    )


def test_classifies_present_and_missing_and_skips_non_dev(tmp_path):
    out = _run(tmp_path)
    assert out.returncode == 0
    rows = {line.split()[0]: line.split()[1] for line in out.stdout.splitlines()[1:]}
    assert rows == {"has": "ok", "lacks": "missing"}
    assert "1 repo(s) without CHANGELOG.md" in out.stderr


def test_strict_fails_when_a_repo_is_missing(tmp_path):
    assert _run(tmp_path, "--strict").returncode == 1


def test_unknown_argument_is_rejected(tmp_path):
    assert _run(tmp_path, "--nope").returncode == 2
