"""Read and edit ``repos.yml`` while preserving comments and layout.

The manifest is the fleet classification (``status`` / ``runtime`` /
``distribution`` opt-outs). Edits are round-tripped with ruamel.yaml so the
explanatory header and per-entry formatting survive. Parsing and serialising
are pure functions over text — no I/O here, so they are trivially testable.
"""

from __future__ import annotations

import io
from dataclasses import dataclass

from ruamel.yaml import YAML

from .config import constants


def valid_status() -> tuple[str, ...]:
    return constants().manifest.valid_status


def valid_runtime() -> tuple[str, ...]:
    return constants().manifest.valid_runtime


def _yaml() -> YAML:
    y = YAML()
    y.preserve_quotes = True
    y.indent(mapping=2, sequence=2, offset=0)
    return y


@dataclass(frozen=True)
class RepoEntry:
    name: str
    status: str
    public: bool | None
    runtime: str | None


class ManifestError(ValueError):
    """Raised on invalid manifest content or edits."""


def parse(text: str) -> list[RepoEntry]:
    """Return the repo entries described by ``text`` (read-only view)."""
    data = _yaml().load(text)
    if not data or "repos" not in data:
        raise ManifestError("manifest has no `repos:` key")
    entries: list[RepoEntry] = [
        RepoEntry(
            name=str(item["name"]),
            status=str(item.get("status", "")),
            public=item.get("public"),
            runtime=item.get("runtime"),
        )
        for item in data["repos"]
    ]
    return entries


def set_fields(
    text: str,
    name: str,
    *,
    status: str | None = None,
    runtime: str | None = None,
) -> str:
    """Return ``text`` with ``status``/``runtime`` updated for repo ``name``.

    Raises on unknown repo or invalid value; comments and layout are preserved.
    """
    if status is not None and status not in valid_status():
        raise ManifestError(f"invalid status {status!r}; expected one of {valid_status()}")
    if runtime is not None and runtime not in valid_runtime():
        raise ManifestError(f"invalid runtime {runtime!r}; expected one of {valid_runtime()}")

    yaml = _yaml()
    data = yaml.load(text)
    target = next((r for r in data["repos"] if str(r["name"]) == name), None)
    if target is None:
        raise ManifestError(f"repo {name!r} not found in manifest")
    if status is not None:
        target["status"] = status
    if runtime is not None:
        target["runtime"] = runtime

    buf = io.StringIO()
    yaml.dump(data, buf)
    return buf.getvalue()
