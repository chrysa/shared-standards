import httpx
import pytest

from standards_console import compliance as compliance_mod
from standards_console.compliance import ComplianceClient, ComplianceUnavailable


def test_unconfigured_returns_empty():
    assert ComplianceClient(None, None).configured is False
    assert ComplianceClient(None, None).fetch() == []


def test_fetch_maps_snapshots(monkeypatch):
    def fake_get(url, headers, timeout):
        assert url.endswith("/api/repos")
        assert headers == {"X-Api-Key": "k"}
        return httpx.Response(
            200,
            json=[{"repo": "alpha", "errors": 2, "warnings": 1, "updated_at": "t"}],
            request=httpx.Request("GET", url),
        )

    monkeypatch.setattr(compliance_mod.httpx, "get", fake_get)
    snaps = ComplianceClient("https://c.example/", "k").fetch()
    assert snaps[0].repo == "alpha"
    assert snaps[0].errors == 2


def test_fetch_raises_on_http_error(monkeypatch):
    def fake_get(url, headers, timeout):
        raise httpx.ConnectError("down")

    monkeypatch.setattr(compliance_mod.httpx, "get", fake_get)
    with pytest.raises(ComplianceUnavailable):
        ComplianceClient("https://c.example", None).fetch()
