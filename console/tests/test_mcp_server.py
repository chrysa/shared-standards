"""Tool-level tests for the standards MCP server (handlers called directly)."""

from __future__ import annotations

import asyncio

import pytest

from standards_console import mcp_server
from standards_console.config import Settings


@pytest.fixture(autouse=True)
def _point_at_fixture(monkeypatch: pytest.MonkeyPatch, std_settings: Settings) -> None:
    """Make the tools' default ``Settings()`` resolve to the fixture repo."""
    monkeypatch.setenv("STANDARDS_REPO_ROOT", str(std_settings.repo_root))


def test_server_registers_exactly_four_tools() -> None:
    server = mcp_server.create_server()
    names = {t.name for t in asyncio.run(server.list_tools())}
    assert names == set(mcp_server.TOOL_NAMES)


def test_standards_get_all_then_subset() -> None:
    full = mcp_server.standards_get()
    assert set(full) == {"thresholds", "sections"}
    subset = mcp_server.standards_get("thresholds")
    assert subset == {"thresholds": full["thresholds"]}
    section = mcp_server.standards_get("commits")
    assert section["section"] == "commits"


def test_standards_get_unknown_section_raises() -> None:
    with pytest.raises(ValueError, match="unknown section"):
        mcp_server.standards_get("does-not-exist")


def test_audit_status_shape() -> None:
    result = mcp_server.standards_audit_status()
    assert set(result) == {"generated_from", "repos"}
    assert {r["repo"] for r in result["repos"]} == {"beta", "gamma"}
    assert "makefile" in result["generated_from"]


def test_diff_delegates() -> None:
    diff = mcp_server.standards_diff("gamma")
    assert diff["compliant"] is False
    assert diff["classification"]["status"] == "dev"


def test_list_rules_has_rules_and_dimensions() -> None:
    catalogue = mcp_server.standards_list_rules()
    assert any(r["id"] == "max_file_lines" for r in catalogue["rules"])
    assert set(catalogue["compliance_dimensions"]) == {"makefile", "cliff"}
