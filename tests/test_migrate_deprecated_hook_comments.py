"""Tests for scripts/migrate-deprecated-hook-comments.py."""

from __future__ import annotations

import importlib.util
import subprocess
import sys
from pathlib import Path

import pytest

_SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "migrate-deprecated-hook-comments.py"


def _load():
    spec = importlib.util.spec_from_file_location("migrate_comments", _SCRIPT)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module  # dataclasses resolve their module through sys.modules
    spec.loader.exec_module(module)
    return module


M = _load()


def _repo(tmp_path: Path, files: dict[str, str]) -> Path:
    subprocess.run(["git", "init", "-q", str(tmp_path)], check=True)
    for name, content in files.items():
        path = tmp_path / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    subprocess.run(["git", "-C", str(tmp_path), "add", "."], check=True)
    return tmp_path


@pytest.mark.parametrize(
    ("line", "expected"),
    [
        ("pprint(x)  # pprint-detection: disable\n", "pprint(x)  # noqa: T203\n"),
        ("breakpoint()  # debugger-detection: disable\n", "breakpoint()  # noqa: T100\n"),
        ("except:  # no-bare-except: disable\n", "except:  # noqa: E722\n"),
        ("def f(a=[]):  # python-mutable-default: disable\n", "def f(a=[]):  # noqa: B006\n"),
        ("logging.info(x)  # logger-detection: disable\n", "logging.info(x)  # noqa: LOG015\n"),
        ("except:  # no-bare-except: disable — legacy API\n", "except:  # noqa: E722 — legacy API\n"),
        ("except:  # noqa: S110  # no-bare-except: disable\n", "except:  # noqa: S110, E722\n"),
        ("except:  # noqa: E722  # no-bare-except: disable\n", "except:  # noqa: E722\n"),
        # T201 is not armed yet: print markers are left for the still-active print hook.
        ("print(x)  # print-detection: disable\n", "print(x)  # print-detection: disable\n"),
        # A marker inside a string literal is data, not a comment.
        ('s = "x  # no-bare-except: disable"\n', 's = "x  # no-bare-except: disable"\n'),
        ("x = 1  # avoids the print-detection gate\n", "x = 1  # avoids the print-detection gate\n"),
    ],
)
def test_convert_python_line(line: str, expected: str) -> None:
    assert M.convert_python_line(line) == expected


def test_pprint_marker_is_not_read_as_print() -> None:
    assert M.convert_python_line("pprint(x)  # pprint-detection: disable\n") == "pprint(x)  # noqa: T203\n"


def test_migrate_writes_and_is_idempotent(tmp_path: Path) -> None:
    repo = _repo(tmp_path, {"app/cli.py": "pprint(1)  # pprint-detection: disable\n"})
    converted, manual = M.migrate(repo, write=True)
    assert len(converted) == 1 and manual == []
    assert (repo / "app/cli.py").read_text(encoding="utf-8") == "pprint(1)  # noqa: T203\n"
    assert M.migrate(repo, write=True) == ([], [])


def test_check_mode_writes_nothing(tmp_path: Path) -> None:
    repo = _repo(tmp_path, {"a.py": "breakpoint()  # debugger-detection: disable\n"})
    assert M.main([str(repo), "--check"]) == 1
    assert (repo / "a.py").read_text(encoding="utf-8") == "breakpoint()  # debugger-detection: disable\n"


def test_untracked_files_are_left_alone(tmp_path: Path) -> None:
    repo = _repo(tmp_path, {})
    (repo / "loose.py").write_text("breakpoint()  # debugger-detection: disable\n", encoding="utf-8")
    assert M.migrate(repo, write=True) == ([], [])


def test_sync_in_async_is_reported_not_rewritten(tmp_path: Path) -> None:
    repo = _repo(tmp_path, {"a.py": "time.sleep(1)  # no-sync-in-async: disable\n"})
    converted, manual = M.migrate(repo, write=True)
    assert converted == [] and len(manual) == 1


def test_dockerfile_own_line_marker_becomes_hadolint_ignore(tmp_path: Path) -> None:
    repo = _repo(tmp_path, {"Dockerfile": "# dockerfile-no-latest: disable\nFROM python:latest\n"})
    M.migrate(repo, write=True)
    assert (repo / "Dockerfile").read_text(encoding="utf-8") == "# hadolint ignore=DL3007\nFROM python:latest\n"


def test_markers_in_strings_and_docstrings_are_never_rewritten(tmp_path: Path) -> None:
    source = (
        '"""Doc: except:  # no-bare-except: disable"""\n'
        'FIXTURE = "breakpoint()  # debugger-detection: disable"\n'
        "breakpoint()  # debugger-detection: disable\n"
    )
    repo = _repo(tmp_path, {"m.py": source})
    converted, _ = M.migrate(repo, write=True)
    assert len(converted) == 1
    lines = (repo / "m.py").read_text(encoding="utf-8").splitlines()
    assert lines[0] == '"""Doc: except:  # no-bare-except: disable"""'
    assert lines[1] == 'FIXTURE = "breakpoint()  # debugger-detection: disable"'
    assert lines[2] == "breakpoint()  # noqa: T100"


def test_untokenizable_file_is_left_alone_and_reported(tmp_path: Path) -> None:
    repo = _repo(tmp_path, {"bad.py": 'x = """unterminated  # debugger-detection: disable\n'})
    converted, manual = M.migrate(repo, write=True)
    assert converted == [] and len(manual) == 1
