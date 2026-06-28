"""Cover the branch/PR/run helpers of the gateway."""

import httpx

from standards_console.github_gateway import GitHubGateway


def _gw(handler) -> GitHubGateway:
    client = httpx.Client(
        base_url="https://api.github.com", transport=httpx.MockTransport(handler)
    )
    return GitHubGateway(
        "t",
        base_url="https://api.github.com",
        api_version="v",
        timeout=5.0,
        per_page=50,
        client=client,
    )


def test_get_branch_sha():
    gw = _gw(lambda r: httpx.Response(200, json={"object": {"sha": "deadbeef"}}))
    assert gw.get_branch_sha("o/r", "main") == "deadbeef"


def test_create_branch_posts_ref():
    seen = {}

    def handler(request: httpx.Request) -> httpx.Response:
        seen["body"] = request.read().decode()
        return httpx.Response(201, json={})

    _gw(handler).create_branch("o/r", new_branch="b", from_sha="s")
    assert "refs/heads/b" in seen["body"]


def test_open_pull_request_adds_labels():
    calls = []

    def handler(request: httpx.Request) -> httpx.Response:
        calls.append(request.url.path)
        if request.url.path.endswith("/pulls"):
            return httpx.Response(201, json={"number": 7, "html_url": "u"})
        return httpx.Response(200, json=[])

    pr = _gw(handler).open_pull_request(
        "o/r", head="h", base="b", title="t", body="x", labels=["a"]
    )
    assert pr["number"] == 7
    assert any(p.endswith("/issues/7/labels") for p in calls)


def test_list_open_pulls_filters_by_branch():
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            json=[
                {"number": 1, "head": {"ref": "wanted"}},
                {"number": 2, "head": {"ref": "other"}},
            ],
        )

    pulls = _gw(handler).list_open_pulls("o/r", head_branch="wanted")
    assert [p["number"] for p in pulls] == [1]


def test_list_workflow_runs():
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json={"workflow_runs": [{"status": "completed"}]})

    runs = _gw(handler).list_workflow_runs("o/r", "w.yml", limit=5)
    assert runs[0]["status"] == "completed"
