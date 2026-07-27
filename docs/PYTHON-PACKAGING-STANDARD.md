# Python Packaging Standard — chrysa

> **Scope.** Procedural detail behind the canonical `standards/STANDARDS.chrysa.md`
> (no-virtualenv, tool-cache, and quality-gate rules). The canonical wins on any conflict;
> this file fixes the **build backend, `pyproject.toml` layout, and distribution path** for
> every Python project.

---

## Single source of truth

**`pyproject.toml` is the single source of truth** for all Python projects.
`setup.cfg` and `setup.py` are **forbidden** — do not create or commit them
(`setup.cfg` is permitted only for non-Python tooling, e.g. uwsgi; never for packaging).

---

## Build backend

| Project type | Backend | `requires` |
|---|---|---|
| Library / package | `setuptools` | `["setuptools>=70", "wheel"]` |
| Application (no distribution) | `setuptools` | `["setuptools>=72", "wheel"]` |

> Backend rationale (2026-06-10): the portfolio standardised on `setuptools` (7/8 libs
> already use it). `hatchling` is **not** used; migrate any stray `hatchling` lib to
> setuptools.

---

## Mandatory sections

```toml
[build-system]
requires = ["setuptools>=70", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "..."
version = "..."
requires-python = ">=3.14"        # minimum 3.12 for legacy packages
dependencies = [...]

[project.optional-dependencies]
dev = ["pytest>=8.3", "pytest-cov>=6", "ruff>=0.11", "mypy>=1.15"]

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --tb=short --cov=src --cov-report=xml --cov-report=term-missing"

[tool.ruff]
line-length = 120
target-version = "py314"          # match requires-python

[tool.ruff.lint]
select = ["E", "F", "W", "I", "B", "UP", "N", "S", "RUF"]
ignore = ["S101"]                  # assert OK in tests

[tool.mypy]
python_version = "3.14"
strict = true
ignore_missing_imports = true
```

---

## Rules

- All tool config (`ruff`, `mypy`, `pytest`, `coverage`) lives in `[tool.*]` sections of
  `pyproject.toml`. External config files (`ruff.toml`, `mypy.ini`, `pytest.ini`,
  `.mypy.ini`) are **forbidden**.
- Library packages use `src/` layout with `[tool.setuptools.packages.find] where = ["src"]`.
- Library packages follow the **Public API Contract** (`docs/PUBLIC-API-CONTRACT.md`):
  sorted `__all__`, relative imports in `__init__`, `__version__` via `importlib.metadata`,
  uniform `install()` entrypoint, shared types in `chrysa-lib`.
- Applications without distribution do not need `[build-system]`; only `[tool.*]` sections
  are required.

---

## Distribution

Distribution is driven by the project type declared in the **Build backend** table above:

- **Library / package (distributable)** → published to **public PyPI**, triggered by CI on a
  git tag matching `v*.*.*`. Build with `setuptools`, upload via Trusted Publishing
  (PyPI OIDC) — **no PyPI API token in plaintext**. Include `CHANGELOG.md`, `LICENSE`, and
  `README.md` in the sdist.
- **Application (no distribution)** → **not** published to PyPI; shipped as a **private GHCR
  image** (see the container-runtime policy in `standards/STANDARDS.chrysa.md`).
- Publication is carried by the reusable `release.yml` workflow (tag → publish; see
  `chrysa/github-actions`).
