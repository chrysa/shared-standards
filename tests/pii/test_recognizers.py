from scripts.pii.recognizers import is_valid_nir

VALID_NIR = "180127505200108"      # control key 08, valid
INVALID_KEY_NIR = "180127505200199"  # wrong control key
CORSICA_NIR = "182022A00123437"    # Corsica 2A (→19), control key 37, valid


def test_is_valid_nir_accepts_correct_key() -> None:
    assert is_valid_nir(VALID_NIR) is True


def test_is_valid_nir_accepts_corsica() -> None:
    assert is_valid_nir(CORSICA_NIR) is True


def test_is_valid_nir_rejects_wrong_key() -> None:
    assert is_valid_nir(INVALID_KEY_NIR) is False


def test_is_valid_nir_rejects_wrong_length() -> None:
    assert is_valid_nir("12345") is False
