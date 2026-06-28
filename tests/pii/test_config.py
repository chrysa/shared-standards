from pathlib import Path

from scripts.pii.config import load_allowlist, load_config

DEFAULT_THRESHOLD = 0.5


def test_load_config_defaults_when_missing(tmp_path: Path) -> None:
    cfg = load_config(tmp_path / "nope.toml")
    assert cfg.score_threshold == DEFAULT_THRESHOLD
    assert "fr" in cfg.languages


def test_load_config_reads_threshold(tmp_path: Path) -> None:
    toml = tmp_path / ".pii-scan.toml"
    toml.write_text('score_threshold = 0.8\nlanguages = ["fr"]\nentities = ["EMAIL_ADDRESS"]\nexclude_paths = []\n', encoding="utf-8")
    cfg = load_config(toml)
    assert cfg.score_threshold == 0.8
    assert cfg.entities == ["EMAIL_ADDRESS"]


def test_load_allowlist_missing_is_empty(tmp_path: Path) -> None:
    assert load_allowlist(tmp_path / "nope.json") == set()
