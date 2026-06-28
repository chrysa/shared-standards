"""Presenter functions: turn service data into API response models.

Kept as top-level functions (no nesting) so each is independently testable and
conforms to the chrysa "no nested named functions" rule.
"""

from __future__ import annotations

from . import manifest
from .compliance import ComplianceUnavailable
from .schemas import ComplianceCell, FleetResponse, FleetRow
from .services import Services


def _compliance_map(services: Services) -> tuple[dict[str, ComplianceCell], str | None]:
    if not services.compliance.configured:
        return {}, None
    try:
        snaps = services.compliance.fetch()
    except ComplianceUnavailable as exc:
        return {}, str(exc)
    cells = {
        s.repo: ComplianceCell(errors=s.errors, warnings=s.warnings, updated_at=s.updated_at)
        for s in snaps
    }
    return cells, None


def assemble_fleet(services: Services) -> FleetResponse:
    """Merge the live fleet, the manifest and compliance into one table."""
    repos = {r.name: r for r in services.gateway.list_fleet(services.settings.org)}
    text, _ = services.read_manifest_text()
    entries = {e.name: e for e in manifest.parse(text)}
    compliance, unreachable = _compliance_map(services)

    rows: list[FleetRow] = []
    for name in sorted(set(repos) | set(entries)):
        entry = entries.get(name)
        repo = repos.get(name)
        rows.append(
            FleetRow(
                name=name,
                status=entry.status if entry else "—",
                runtime=entry.runtime if entry else None,
                archived=repo.archived if repo else None,
                in_manifest=entry is not None,
                html_url=repo.html_url if repo else "",
                compliance=compliance.get(name),
            )
        )
    return FleetResponse(rows=rows, central_unreachable=unreachable)
