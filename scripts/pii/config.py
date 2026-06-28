"""Load PII scan configuration and false-positive allowlist."""

import json
import tomllib
from dataclasses import dataclass, field
from pathlib import Path

DEFAULT_THRESHOLD = 0.5
DEFAULT_LANGUAGES = ["fr", "en"]
# PERSON is intentionally excluded: spaCy NER flags ordinary code/config tokens
# as PERSON (~0.85), which is unusable as a blocking gate. Opt back in via config.
DEFAULT_ENTITIES = [
    "EMAIL_ADDRESS", "IBAN_CODE", "PHONE_NUMBER", "CREDIT_CARD",
    "IP_ADDRESS", "FR_NIR", "FR_CNI",
]


@dataclass(frozen=True)
class ScanConfig:
    score_threshold: float = DEFAULT_THRESHOLD
    languages: list[str] = field(default_factory=lambda: list(DEFAULT_LANGUAGES))
    entities: list[str] = field(default_factory=lambda: list(DEFAULT_ENTITIES))
    exclude_paths: list[str] = field(default_factory=list)


def load_config(path: Path) -> ScanConfig:
    """Read scan config from TOML, falling back to defaults if absent."""
    if not path.exists():
        return ScanConfig()
    data = tomllib.loads(path.read_text(encoding="utf-8"))
    return ScanConfig(
        score_threshold=float(data.get("score_threshold", DEFAULT_THRESHOLD)),
        languages=list(data.get("languages", DEFAULT_LANGUAGES)),
        entities=list(data.get("entities", DEFAULT_ENTITIES)),
        exclude_paths=list(data.get("exclude_paths", [])),
    )


def load_allowlist(path: Path) -> set[str]:
    """Read the allowlist of finding fingerprints; missing file → empty set."""
    if not path.exists():
        return set()
    data = json.loads(path.read_text(encoding="utf-8"))
    return set(data.get("allow", []))
