# Public API Contract — Python library packages

> Scope: every distributable Python library in the chrysa portfolio
> (`django-*`, `fastapi-*`, `chrysa-lib`, `ai-aggregator`, `doc-gen`,
> `discord-bot-back`, `guideline-checker`, `pre-commit-tools`,
> `quality-gatekeeper`, `chrysa-portfolio-viz`).
>
> This document fills the gap **between** `EXECUTION_STANDARD.md` §11
> (which mandates the `src/` layout and build backend) **and** the
> code: it specifies what the package's top-level `__init__.py` is
> allowed to expose and how. It does **not** restate API/REST rules —
> those live in `CODE_MANIFEST.md` §3 — nor UI rules
> (`docs/UX-UI-GUIDELINES.md`, `.claude/skills/ui-ux/SKILL.md`).

The top-level `__init__.py` **is** the package's public contract. A
consumer should never have to reach into a submodule. Everything below
is enforced uniformly across mirror families so that
`import django_x` and `import fastapi_x` feel like the same product.

---

## C1 — Layout (already mandated, restated for compliance)

- `src/<pkg>/__init__.py` layout — per `EXECUTION_STANDARD.md` §11.
- **Flat-layout packages are non-conformant** and must be migrated.

## C2 — `__all__` is mandatory and sorted

- Every public `__init__.py` declares `__all__`.
- `__all__` is **alphabetically sorted** and contains **only** the
  stable public surface (no private helpers, no re-exported stdlib).
- Anything not in `__all__` is private and may change without a major bump.

## C3 — Single import style inside `__init__.py`

- Use **relative imports** in `__init__.py`: `from .module import X`.
- Absolute self-imports (`from pkg.module import X`) are forbidden in
  `__init__.py` — they duplicate the package name and break on rename.

## C4 — `__version__` exposed, single source of truth

- `__init__.py` **must** expose `__version__`.
- The value is read at runtime from installed metadata — **never**
  hardcoded:

  ```python
  from importlib.metadata import PackageNotFoundError, version

  try:
      __version__ = version("<dist-name>")
  except PackageNotFoundError:  # editable / not installed
      __version__ = "0.0.0+unknown"
  ```

- `pyproject.toml [project].version` is the **only** declared version.
  No hardcoded copy anywhere (delete any `__about__.py` or
  `_internal/version.py` that holds a literal string).
- When other modules also need the version (SARIF/report headers, user
  agents), **centralize** the `importlib.metadata` read in a single
  internal accessor (e.g. `_internal/version.py` that itself reads
  metadata) and import `__version__` from there — both in `__init__` and
  in those modules. This avoids importing the package root from a
  submodule and creating an import cycle. The rule is *no hardcoded
  second value*, not *no internal module*.

## C5 — Installation / wiring entrypoint, uniform name

- A library that wires into a framework (middleware, plugin, app
  registry) exposes **one** entrypoint, named identically across the
  family:
  - `install(...)` — idempotent, wires the library into the host.
  - Django libs: zero-arg `install()` (settings-driven).
  - FastAPI libs: `install(app_or_engine)` — takes the host object.
- Libraries that are pure toolkits (no host wiring) **do not** invent a
  fake `install()`; they expose their primary callable instead.

## C6 — No lazy `__getattr__` unless justified

- Module-level `__getattr__` for lazy export is allowed **only** to break
  a heavy/optional import cycle, and must be documented inline with the
  reason. Default: eager imports. Do not add it for symmetry alone.

## C7 — Shared types live in `chrysa-lib`

- Cross-package enums/types (e.g. `Severity`) are defined **once** in
  `chrysa-lib` and imported, not redefined per repo.
- A package re-exports the shared type through its `__all__` if it is
  part of that package's public surface.

## C8 — README "Public API" section

- The README carries a `## Public API` section listing every name in
  `__all__` with a one-line purpose, and a minimal usage example.
- Mirror families (`django-x` / `fastapi-x`) use the **same example
  shape** so the docs read consistently.

---

## Conformance snapshot (2026-06-10)

Evidence from `__init__.py` + `pyproject.toml` inspection of the mirror
families. **All repos hardcode `__version__ = "0.1.0"`** (C4 violated
everywhere). Build backend is `setuptools` everywhere except
`django-autoload` (`hatchling` — migrate to setuptools per
`EXECUTION_STANDARD.md` §11).

| Repo | C1 layout | C4 version | C3 imports | Backend | Action |
|---|---|---|---|---|---|
| django-traceid | ❌ flat | ⚠️ hardcoded | relative ok | setuptools | migrate to `src/`, importlib.metadata |
| django-pytest | ❌ flat | ⚠️ hardcoded | — | setuptools | migrate to `src/`, importlib.metadata |
| django-app-forge | ❌ flat | ⚠️ hardcoded | — | setuptools | migrate to `src/`, importlib.metadata (PR #4 open) |
| django-autoload | ✅ src | ⚠️ hardcoded | relative ok | ⚠️ hatchling | importlib.metadata; backend → setuptools |
| django-query-optimizer | ✅ src | ⚠️ `_internal.version` | ❌ absolute | setuptools | importlib.metadata, relative imports, export `Severity` |
| fastapi-traceid | ✅ src | ⚠️ hardcoded | ✅ | setuptools | importlib.metadata |
| fastapi-pytest | ✅ src | ⚠️ hardcoded | ✅ | setuptools | importlib.metadata, verify `__all__` sorted |
| fastapi-autoload | ✅ src | ⚠️ hardcoded | ✅ | setuptools | importlib.metadata |
| fastapi-query-optimizer | ✅ src | ⚠️ `_internal.version` | ❌ absolute | setuptools | importlib.metadata; review `__getattr__` (C6) |
| fastapi-app-forge | ✅ src | ⚠️ hardcoded | ✅ | setuptools | importlib.metadata |

Cross-family: `Severity` is exported by `fastapi-query-optimizer` and
`fastapi-pytest` but not `django-query-optimizer` → extract to
`chrysa-lib` (C7).

---

## Verification (per repo, Docker only)

```bash
make install
python -c "import <pkg> as m; assert m.__all__ == sorted(m.__all__); print(m.__version__, m.__all__)"
make lint && make test
```

> Host invocation of `python`/`ruff`/`pytest` is forbidden
> (`EXECUTION_STANDARD.md` §12). Run inside the project's `make` targets.
