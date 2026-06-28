"""Pydantic request/response models for the JSON API consumed by the React SPA."""

from __future__ import annotations

from pydantic import BaseModel


class Meta(BaseModel):
    standards_full_name: str
    branch: str
    valid_status: list[str]
    valid_runtime: list[str]
    central_configured: bool


class ComplianceCell(BaseModel):
    errors: int
    warnings: int
    updated_at: str


class FleetRow(BaseModel):
    name: str
    status: str
    runtime: str | None
    archived: bool | None
    in_manifest: bool
    html_url: str
    compliance: ComplianceCell | None


class FleetResponse(BaseModel):
    rows: list[FleetRow]
    central_unreachable: str | None = None


class StatusUpdate(BaseModel):
    status: str


class RunInfo(BaseModel):
    status: str
    conclusion: str | None
    created_at: str
    html_url: str
    event: str


class PullInfo(BaseModel):
    number: int
    title: str
    html_url: str


class DistributionResponse(BaseModel):
    runs: list[RunInfo]
    pulls: list[PullInfo]


class DistributionRun(BaseModel):
    mode: str  # "check" | "apply"
    only: str = ""


class StandardDoc(BaseModel):
    path: str
    text: str


class StandardEditRequest(BaseModel):
    content: str
    summary: str


class StandardEditResponse(BaseModel):
    pr_number: int
    pr_url: str
    branch: str


class Ok(BaseModel):
    ok: bool = True
    message: str
