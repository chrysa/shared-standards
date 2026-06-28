import pytest

from standards_console import manifest

from .conftest import MANIFEST


def test_parse_entries():
    entries = {e.name: e for e in manifest.parse(MANIFEST)}
    assert entries["alpha"].status == "dev"
    assert entries["alpha"].runtime == "container"
    assert entries["beta"].public is False


def test_set_status_preserves_header_comment():
    out = manifest.set_fields(MANIFEST, "beta", status="dev")
    assert "Header comment that MUST survive edits" in out
    assert manifest.parse(out)[1].status == "dev"
    # untouched entry is unchanged
    assert manifest.parse(out)[0].status == "dev"


def test_set_runtime():
    out = manifest.set_fields(MANIFEST, "alpha", runtime="exempt:lib")
    assert {e.name: e.runtime for e in manifest.parse(out)}["alpha"] == "exempt:lib"


def test_invalid_status_rejected():
    with pytest.raises(manifest.ManifestError):
        manifest.set_fields(MANIFEST, "alpha", status="bogus")


def test_invalid_runtime_rejected():
    with pytest.raises(manifest.ManifestError):
        manifest.set_fields(MANIFEST, "alpha", runtime="nope")


def test_unknown_repo_rejected():
    with pytest.raises(manifest.ManifestError):
        manifest.set_fields(MANIFEST, "ghost", status="dev")


def test_manifest_without_repos_key():
    with pytest.raises(manifest.ManifestError):
        manifest.parse("other: 1\n")
