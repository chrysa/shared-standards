# GitHub Copilot Instructions — Python Library

<!-- @[claude-sonnet-4] -->

Extends [base.md](base.md). Read base rules first; rules here take precedence where they conflict.

## Layout

```
src/
  <package_name>/
    __init__.py       # public API surface — explicit re-exports only
    _internal/        # private implementation (not part of public API)
    py.typed          # marker file for PEP 561
    constants.py      # library-wide constants (Final)
tests/
  unit/
  integration/        # optional — only if the lib has external dependencies
  conftest.py
pyproject.toml        # single source of truth for metadata, deps, tooling
```

## Package design

- Expose the public API in `__init__.py` using explicit `__all__`.
- Prefix internal modules with `_` to signal they are not part of the public API.
- Do not import private modules in `__init__.py` — only public symbols.
- Follow semantic versioning. Maintain a `CHANGELOG.md` (auto-generated via git-cliff).
- Support the Python versions declared in `python_requires` — test with tox or GitHub Actions matrix.

## Typing

- Full type annotations on all public functions and methods.
- `py.typed` marker must be present for PEP 561 compliance.
- `mypy --strict` must pass with zero errors.
- Use `typing.Protocol` for structural typing rather than inheritance where it makes sense.
- Avoid `Any` — use `TypeVar`, `Generic`, or `Protocol` instead.

## API stability

- Public API changes that break backward compatibility require a major version bump.
- Mark unstable APIs with `@typing.experimental` or a clear deprecation warning.
- Use `warnings.warn(DeprecationWarning)` when removing a deprecated function.

## Dependencies

- Keep `[project.dependencies]` minimal — prefer stdlib.
- All heavy deps belong in optional extras (`[project.optional-dependencies]`).
- Never pin transitive deps in the library itself — only in lock files for apps.

## Testing

- Use `pytest` with `pytest-cov`.
- Test every public function with: happy path, edge cases, type boundary, error cases.
- Use `pytest.mark.parametrize` for data-driven tests.
- Coverage target: 90%+ on public API.
- Mutation testing recommended (`mutmut`) for critical logic.

## Distribution

- Build with `flit` or `hatchling` (configured in `pyproject.toml`).
- Publish to PyPI via CI on git tag matching `v*.*.*`.
- Include `CHANGELOG.md`, `LICENSE`, and `README.md` in sdist (`[tool.hatch.build]`).
- Generate CHANGELOG with `git-cliff` (`generate-changelog` pre-commit hook, stage: manual).

## Documentation

- Docstrings on all public symbols (Google style).
- Public API docs auto-generated with `mkdocs` + `mkdocstrings-python`.
- Code examples in docstrings must be runnable as doctests.
