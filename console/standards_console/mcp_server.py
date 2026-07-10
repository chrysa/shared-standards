"""Read-only MCP server exposing the chrysa fleet standards over stdio.

Four tools, no enforcement and no writes: the server is a query surface over the
source files that already hold the norms (``rules_reader``) and the local compliance
snapshots (``compliance_reader``). Gating stays in hooks + CI. Each tool is a thin
delegate so the logic stays unit-testable without a running MCP transport.
"""

from __future__ import annotations

from mcp.server.fastmcp import FastMCP

from . import compliance_reader, rules_reader

_INSTRUCTIONS = (
    "Read-only view of the chrysa fleet standards. Use standards_get for the rules, "
    "standards_audit_status for the cross-repo compliance view, standards_diff for one "
    "repo, and standards_list_rules to discover what can be queried. This server never "
    "enforces or writes — enforcement lives in hooks + CI."
)

TOOL_NAMES = (
    "standards_get",
    "standards_diff",
    "standards_audit_status",
    "standards_list_rules",
)


def standards_get(section: str | None = None) -> dict[str, object]:
    """Return the fleet rules. Without ``section``, return all; otherwise that subset."""
    thresholds = rules_reader.load_thresholds()
    sections = rules_reader.load_standard_sections()
    if section is None:
        return {"thresholds": thresholds, "sections": sections}
    if section == "thresholds":
        return {"thresholds": thresholds}
    if section in sections:
        return {"section": section, "body": sections[section]}
    raise ValueError(f"unknown section {section!r}; see standards_list_rules()")


def standards_diff(repo: str) -> dict[str, object]:
    """Return one repo's compliance deviations plus its repos.yml classification."""
    return compliance_reader.repo_diff(repo)


def standards_audit_status(
    section: str | None = None, min_severity: str | None = None
) -> dict[str, object]:
    """Return the cross-repo compliance view, most-deviating repos first."""
    return {
        "generated_from": compliance_reader.source_mtimes(),
        "repos": compliance_reader.audit_status(section=section, min_severity=min_severity),
    }


def standards_list_rules() -> dict[str, object]:
    """Return an introspectable catalogue of every queryable rule and dimension."""
    return {
        "rules": rules_reader.list_rules(),
        "compliance_dimensions": sorted(compliance_reader.source_mtimes()),
    }


def create_server() -> FastMCP:
    """Build the FastMCP server with the four standards tools registered."""
    server = FastMCP("standards", instructions=_INSTRUCTIONS)
    for fn in (standards_get, standards_diff, standards_audit_status, standards_list_rules):
        server.add_tool(fn)
    return server


def main() -> None:
    """Console-script entrypoint: serve the standards tools over stdio."""
    create_server().run(transport="stdio")
