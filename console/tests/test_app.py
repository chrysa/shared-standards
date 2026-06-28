from fastapi.testclient import TestClient

from standards_console.app import create_app

from .conftest import FakeGateway


def _client(services) -> TestClient:
    return TestClient(create_app(services))


def test_health(services):
    assert _client(services).get("/api/health").json() == {"status": "ok"}


def test_meta_exposes_referential(services):
    body = _client(services).get("/api/meta").json()
    assert body["standards_full_name"] == "chrysa/shared-standards"
    assert "dev" in body["valid_status"]
    assert body["central_configured"] is False


def test_fleet_lists_repos(services):
    rows = _client(services).get("/api/fleet").json()["rows"]
    names = {r["name"] for r in rows}
    assert {"alpha", "beta"} <= names


def test_update_status_commits_manifest(services, gateway: FakeGateway):
    resp = _client(services).post("/api/repos/beta/status", json={"status": "dev"})
    assert resp.status_code == 200
    assert resp.json()["message"] == "beta → dev"
    new = gateway.files[("chrysa/shared-standards", "repos.yml")].text
    assert "Header comment that MUST survive edits" in new


def test_update_status_invalid_returns_400(services):
    resp = _client(services).post("/api/repos/beta/status", json={"status": "bogus"})
    assert resp.status_code == 400
    assert "invalid status" in resp.json()["detail"]


def test_distribution_check_dispatches_dry_run(services, gateway: FakeGateway):
    resp = _client(services).post("/api/distribution/run", json={"mode": "check"})
    assert resp.status_code == 200
    assert gateway.dispatched[-1]["inputs"]["dry_run"] == "true"


def test_distribution_apply_dispatches_real(services, gateway: FakeGateway):
    _client(services).post("/api/distribution/run", json={"mode": "apply", "only": "alpha"})
    last = gateway.dispatched[-1]
    assert last["inputs"]["dry_run"] == "false"
    assert last["inputs"]["only"] == "alpha"


def test_distribution_listing(services, gateway: FakeGateway):
    gateway.runs = [
        {
            "status": "completed",
            "conclusion": "success",
            "created_at": "2026-06-28T10:00:00Z",
            "html_url": "https://gh/run/1",
            "event": "workflow_dispatch",
        }
    ]
    body = _client(services).get("/api/distribution").json()
    assert body["runs"][0]["conclusion"] == "success"
    assert body["pulls"] == []


def test_standard_read(services):
    body = _client(services).get("/api/standard").json()
    assert body["path"].endswith("STANDARDS.chrysa.md")
    assert "coverage" in body["text"]


def test_standard_edit_opens_pr(services, gateway: FakeGateway):
    resp = _client(services).post(
        "/api/standard", json={"content": "# new\n", "summary": "tighten"}
    )
    assert resp.status_code == 200
    assert resp.json()["pr_number"] == 42
    assert gateway.pulls_opened and gateway.branches


def test_github_error_maps_to_502(services, gateway: FakeGateway):
    def boom(*_a, **_k):
        from standards_console.github_gateway import GitHubError

        raise GitHubError(403, "Forbidden")

    gateway.list_fleet = boom  # type: ignore[assignment]
    resp = _client(services).get("/api/fleet")
    assert resp.status_code == 502
    assert "Forbidden" in resp.json()["detail"]
