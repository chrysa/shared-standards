#!/usr/bin/env python3
"""Rewrite the opt-out comments of deprecated pre-commit-tools hooks to native syntax.

The Python/Docker hooks deprecated in chrysa/pre-commit-tools (DEPRECATIONS.md) are
replaced by Ruff codes (pyproject-ruff-merge.py LOT 2) and hadolint. Their legacy
`# <hook>: disable` comments mean nothing to those tools, so once the codes are armed
every line the comment used to allow would fail CI. This script
converts them, in git-tracked files only:

    pprint(x)  # pprint-detection: disable           ->  pprint(x)  # noqa: T203
    except:  # noqa: S110  # no-bare-except: disable  ->  except:  # noqa: S110, E722
    # dockerfile-no-latest: disable (own line)       ->  # hadolint ignore=DL3007

A trailing reason is kept (`# no-bare-except: disable — legacy API` becomes
`# noqa: E722 — legacy API`). Only real comments are rewritten — Python files are
tokenized, so a marker inside a string literal (a test fixture, a docstring) is never
touched. `no-sync-in-async` opt-outs have no single Ruff code
and are only reported. Running it twice is a no-op.

Usage: migrate-deprecated-hook-comments.py <repo> [--check]
  --check : exit 1 if any comment still needs converting (no write), listing them.
Exit: 0 ok / 1 pending conversions (with --check) / 2 usage error.
"""

from __future__ import annotations

import io
import os
import re
import subprocess
import tokenize
import sys
from dataclasses import dataclass
from pathlib import Path

# Legacy marker -> Ruff code. `(?<![\w-])` keeps a marker from matching inside a
# longer one (`print-detection` inside `pprint-detection`).
# `print-detection` / `no-print-in-migration` are absent on purpose: T201 is not armed
# yet and the print hook still gates, so its markers must stay as they are.
PYTHON_MARKERS: dict[str, str] = {
    "pprint-detection": "T203",
    "debugger-detection": "T100",
    "no-bare-except": "E722",
    "python-mutable-default": "B006",
    "logger-detection": "LOG015",
}
REPORT_ONLY_MARKERS = ("no-sync-in-async",)
DOCKER_MARKER = "dockerfile-no-latest"
DOCKER_REPLACEMENT = "# hadolint ignore=DL3007"
KNOWN_FLAGS = ("--check",)

_NOQA_RE = re.compile(r"#\s*noqa:\s*(?P<codes>[A-Z]+[0-9]+(?:\s*,\s*[A-Z]+[0-9]+)*)")
_DOCKERFILE_RE = re.compile(r"(^|/)Dockerfile[^/]*$")


def _marker_re(marker: str) -> re.Pattern[str]:
    return re.compile(rf"#\s*(?<![\w-]){re.escape(marker)}\s*:\s*disable\b")


_PYTHON_PATTERNS = {marker: _marker_re(marker) for marker in PYTHON_MARKERS}
_REPORT_PATTERNS = {marker: _marker_re(marker) for marker in REPORT_ONLY_MARKERS}
_DOCKER_PATTERN = _marker_re(DOCKER_MARKER)


@dataclass(frozen=True)
class Finding:
    """One legacy comment that was (or must be) converted, or must be fixed by hand."""

    path: str
    line: int
    detail: str


def comment_columns(source: str) -> dict[int, int] | None:
    """Map each line number to the column where its real comment starts.

    Built from the tokenizer, so `#` inside strings and docstrings is not a comment.
    Returns None when the source cannot be tokenized (the file is then left alone).
    """
    columns: dict[int, int] = {}
    try:
        for token in tokenize.generate_tokens(io.StringIO(source).readline):
            if token.type == tokenize.COMMENT:
                columns[token.start[0]] = token.start[1]
    except (tokenize.TokenError, SyntaxError):
        return None
    return columns


def _convert_comment(comment: str) -> str:
    """Rewrite the legacy markers of one comment (text from its first `#` to EOL)."""
    for marker, pattern in _PYTHON_PATTERNS.items():
        match = pattern.search(comment)
        if match is None:
            continue
        code = PYTHON_MARKERS[marker]
        prefix, tail = comment[: match.start()], comment[match.end() :]
        noqa = _NOQA_RE.search(prefix)
        if noqa is not None:
            # A noqa already precedes the marker: merge the code into it and drop the
            # marker comment, keeping any trailing reason as text of that comment.
            codes = [c.strip() for c in noqa.group("codes").split(",")]
            merged = noqa.group(0) if code in codes else f"{noqa.group(0)}, {code}"
            prefix = prefix[: noqa.start()] + merged + prefix[noqa.end() :]
            reason = tail.strip()
            comment = prefix.rstrip() + (f" {reason}" if reason else "") + _eol(comment)
        else:
            comment = prefix + f"# noqa: {code}" + tail
    return comment


def convert_python_line(line: str, comment_col: int | None = None) -> str:
    """Return the line with every legacy marker of its comment turned into a noqa code.

    `comment_col` is the comment's start column from :func:`comment_columns`; when
    omitted the line is tokenized on its own. A line without a real comment is
    returned unchanged.
    """
    if comment_col is None:
        comment_col = (comment_columns(line) or {}).get(1)
        if comment_col is None:
            return line
    return line[:comment_col] + _convert_comment(line[comment_col:])


def _eol(line: str) -> str:
    return line[len(line.rstrip("\r\n")) :]


def tracked_files(repo: Path) -> list[Path]:
    """Git-tracked files of the repo (vendored and ignored files are never rewritten)."""
    result = subprocess.run(
        ["git", "-C", str(repo), "ls-files", "-z"],
        capture_output=True,
        check=True,
    )
    return [repo / os.fsdecode(name) for name in result.stdout.split(b"\0") if name]


def _lines(text: str) -> list[str]:
    """Split like the tokenizer does (on `\\n` only), so line numbers always agree."""
    return io.StringIO(text).readlines()


def _is_rewritable(path: Path, repo: Path) -> bool:
    """A regular file inside the repo: symlinks are never followed out of the tree."""
    if path.is_symlink() or not path.is_file():
        return False
    return path.resolve().is_relative_to(repo.resolve())


def _scan_python(
    path: Path, rel: str, text: str
) -> tuple[str, list[Finding], list[Finding]]:
    converted: list[Finding] = []
    manual: list[Finding] = []
    columns = comment_columns(text)
    if columns is None:
        return text, [], [Finding(rel, 0, "not tokenizable, legacy comments left as is")]
    out: list[str] = []
    for number, line in enumerate(_lines(text), start=1):
        col = columns.get(number)
        new = line if col is None else convert_python_line(line, col)
        if new != line:
            converted.append(Finding(rel, number, new.strip()))
        manual.extend(
            Finding(
                rel, number, f"{marker}: no single Ruff code, fix by hand (ASYNC2xx)"
            )
            for marker, pattern in _REPORT_PATTERNS.items()
            if col is not None and pattern.search(new[col:])
        )
        out.append(new)
    return "".join(out), converted, manual


def _scan_dockerfile(rel: str, text: str) -> tuple[str, list[Finding], list[Finding]]:
    converted: list[Finding] = []
    manual: list[Finding] = []
    out: list[str] = []
    for number, line in enumerate(_lines(text), start=1):
        if _DOCKER_PATTERN.search(line):
            if line.lstrip().startswith("#"):
                indent = line[: len(line) - len(line.lstrip())]
                line = f"{indent}{DOCKER_REPLACEMENT}{_eol(line)}"
                converted.append(Finding(rel, number, DOCKER_REPLACEMENT))
            else:
                manual.append(
                    Finding(
                        rel,
                        number,
                        "inline Dockerfile comment: move `# hadolint ignore=DL3007` above",
                    )
                )
        out.append(line)
    return "".join(out), converted, manual


def migrate(repo: Path, *, write: bool) -> tuple[list[Finding], list[Finding]]:
    """Convert (or, when not writing, only detect) the legacy comments of one repo."""
    converted: list[Finding] = []
    manual: list[Finding] = []
    for path in tracked_files(repo):
        rel = path.relative_to(repo).as_posix()
        is_python = path.suffix == ".py"
        if not (is_python or _DOCKERFILE_RE.search(rel)):
            continue
        if not _is_rewritable(path, repo):
            continue
        try:
            # Bytes I/O: no newline translation, so CRLF / CR endings survive the round-trip.
            text = path.read_bytes().decode("utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        if is_python:
            new, done, todo = _scan_python(path, rel, text)
        else:
            new, done, todo = _scan_dockerfile(rel, text)
        converted.extend(done)
        manual.extend(todo)
        if write and new != text:
            path.write_bytes(new.encode("utf-8"))
    return converted, manual


def main(argv: list[str]) -> int:
    flags = [a for a in argv if a.startswith("--")]
    args = [a for a in argv if not a.startswith("--")]
    unknown = [f for f in flags if f not in KNOWN_FLAGS]
    if unknown or len(args) != 1 or not Path(args[0]).is_dir():
        if unknown:
            sys.stderr.write(f"unknown option(s): {' '.join(unknown)}\n")
        sys.stderr.write(__doc__ or "")
        return 2
    check = "--check" in flags
    try:
        converted, manual = migrate(Path(args[0]), write=not check)
    except subprocess.CalledProcessError as exc:
        sys.stderr.write(f"git ls-files failed in {args[0]}: {exc}\n")
        return 2
    for finding in manual:
        sys.stderr.write(f"{finding.path}:{finding.line}: {finding.detail}\n")
    if check:
        for finding in converted:
            sys.stderr.write(
                f"{finding.path}:{finding.line}: legacy opt-out comment to convert\n"
            )
        return 1 if converted else 0
    if converted:
        sys.stdout.write(f"converted {len(converted)} legacy opt-out comment(s)\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
