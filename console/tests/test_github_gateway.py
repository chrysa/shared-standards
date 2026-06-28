import base64

import httpx
import pytest

from standards_console.github_gateway import GitHubError, GitHubGateway


def _client(handler) -> GitHubGateway:
    transport = httpx.MockTransport(handler)
    client = httpx.Client(base_url="https://api.github.com", transport=transport)
    return GitHubGateway(
        "tok",
        base_url="https://api.github.com",
        api_version="2022-11-28",
        timeout=5.0,
        per_page=100,
        client=client,
    )


def test_get_file_decodes_content():
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path == "/repos/o/r/contents/f.md"
        body = {"content": base64.b64encode(b"hello").decode(), "sha": "abc"}
        return httpx.Response(200, json=body)

    gw = _client(handler)
    f = gw.get_file("o/r", "f.md", ref="main")
    assert f.text == "hello"
    assert f.sha == "abc"


def test_put_file_sends_encoded_content():
    seen = {}

    def handler(request: httpx.Request) -> httpx.Response:
        seen["body"] = request.read()
        return httpx.Response(200, json={"commit": {"sha": "new"}})

    gw = _client(handler)
    sha = gw.put_file("o/r", "f.md", text="hi", message="m", branch="b", sha="s")
    assert sha == "new"
    assert base64.b64encode(b"hi").decode() in seen["body"].decode()


def test_dispatch_workflow_posts_inputs():
    seen = {}

    def handler(request: httpx.Request) -> httpx.Response:
        seen["path"] = request.url.path
        seen["body"] = request.read().decode()
        return httpx.Response(204)

    gw = _client(handler)
    gw.dispatch_workflow("o/r", "w.yml", ref="main", inputs={"dry_run": "true"})
    assert seen["path"].endswith("/actions/workflows/w.yml/dispatches")
    assert "dry_run" in seen["body"]


def test_error_is_raised_with_status_and_message():
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(404, json={"message": "Not Found"})

    gw = _client(handler)
    with pytest.raises(GitHubError) as exc:
        gw.get_file("o/r", "missing", ref="main")
    assert exc.value.status_code == 404
    assert "Not Found" in exc.value.message


def test_list_fleet_excludes_forks():
    def handler(request: httpx.Request) -> httpx.Response:
        repos = [
            {"name": "a", "default_branch": "main", "private": False, "archived": False,
             "html_url": "u", "pushed_at": "t", "fork": False},
            {"name": "f", "default_branch": "main", "private": False, "archived": False,
             "html_url": "u", "pushed_at": "t", "fork": True},
        ]
        return httpx.Response(200, json=repos)

    gw = _client(handler)
    names = [r.name for r in gw.list_fleet("org")]
    assert names == ["a"]
