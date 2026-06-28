"""Custom Presidio recognizers for French personal identifiers."""

from presidio_analyzer import Pattern, PatternRecognizer  # type: ignore[import-not-found]

NIR_LENGTH = 15
NIR_KEY_MODULO = 97
_CORSICA = {"2A": "19", "2B": "18"}


def is_valid_nir(digits: str) -> bool:
    """Return True if a 15-char French NIR has a valid 2-digit control key."""
    raw = digits.strip().replace(" ", "")
    if len(raw) != NIR_LENGTH:
        return False
    body, key = raw[:13], raw[13:]
    normalized = _normalize_corsica(body)
    if not normalized.isdigit() or not key.isdigit():
        return False
    expected = NIR_KEY_MODULO - (int(normalized) % NIR_KEY_MODULO)
    return expected == int(key)


def _normalize_corsica(body: str) -> str:
    """Replace a Corsica department code (2A/2B) with its numeric equivalent."""
    dept = body[5:7].upper()
    if dept in _CORSICA:
        return body[:5] + _CORSICA[dept] + body[7:]
    return body


NIR_PATTERN = r"\b[12]\d{2}\d{2}(?:\d{2}|2[AB])\d{3}\d{3}\d{2}\b"
CNI_PATTERN = r"\b\d{12}\b"


class FrNirRecognizer(PatternRecognizer):
    """French social-security number recognizer with control-key validation."""

    def __init__(self) -> None:
        super().__init__(
            supported_entity="FR_NIR",
            patterns=[Pattern("FR_NIR", NIR_PATTERN, 0.6)],
            supported_language="fr",
        )

    def validate_result(self, pattern_text: str) -> bool:
        return is_valid_nir(pattern_text)


def build_custom_recognizers() -> list[PatternRecognizer]:
    """Return the custom French PII recognizers (NIR, CNI)."""
    cni = PatternRecognizer(
        supported_entity="FR_CNI",
        patterns=[Pattern("FR_CNI", CNI_PATTERN, 0.3)],
        supported_language="fr",
    )
    return [FrNirRecognizer(), cni]
