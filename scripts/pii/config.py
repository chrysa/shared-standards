"""Load PII scan configuration and false-positive allowlist."""

import json
import tomllib
from dataclasses import dataclass, field
from pathlib import Path

DEFAULT_THRESHOLD = 0.5
DEFAULT_LANGUAGES = ["fr", "en"]
# PERSON and FR_CNI are intentionally excluded from the defaults: PERSON (spaCy
# NER) flags ordinary code/config tokens at ~0.85, and FR_CNI is a bare 12-digit
# pattern (score 0.3) too imprecise to gate on. Both recognizers stay available —
# opt back in via the `entities` list in .pii-scan.toml. See DECISIONS.md D-0006.
DEFAULT_ENTITIES = [
    "EMAIL_ADDRESS", "IBAN_CODE", "PHONE_NUMBER", "CREDIT_CARD",
    "IP_ADDRESS", "FR_NIR",
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
