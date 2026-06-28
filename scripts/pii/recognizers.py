"""Custom Presidio recognizers for French personal identifiers."""
# Pattern and PatternRecognizer will be used in later tasks (recognizer classes).

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
