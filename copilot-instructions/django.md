# GitHub Copilot Instructions — Django

<!-- @[claude-sonnet-4] -->

Extends [base.md](base.md). Read base rules first; rules here take precedence where they conflict.
For reusable Django *libraries* (pluggable apps published to PyPI), [python-library.md](python-library.md)
also applies — use `src/` layout and the library packaging rules from there.

## Project layout (Django application)

```
src/
  <project_name>/
    __init__.py
    settings/
      __init__.py
      base.py        # shared settings, read from env — no secrets inline
      dev.py         # local overrides
      test.py        # test overrides (fast password hasher, in-memory cache)
      prod.py        # production overrides
    urls.py          # root URLConf; includes per-app urls under /api/v1/
    asgi.py
    wsgi.py
  <app_name>/        # one Django app per bounded context
    __init__.py
    apps.py
    admin.py
    models.py        # ORM models only
    serializers.py   # DRF serializers — separate classes from models
    views.py         # DRF ViewSets / APIViews — HTTP concerns only
    services.py      # business logic (no HTTP, no request/response objects)
    permissions.py   # custom DRF permission classes
    filters.py       # django-filter FilterSets
    urls.py          # app router registration
    migrations/      # always committed, never hand-edited
    selectors.py     # read queries (optional, keeps views thin)
manage.py
tests/
  unit/              # models, serializers, services, permissions in isolation
  integration/       # views + DB through the API
  conftest.py
pyproject.toml       # single source of truth for metadata, deps, tooling
```

- **Application** → `src/<project_name>/` layout above, with `manage.py` at repo root.
- **Reusable Django library** (e.g. `django-traceid`, `django-autoload`) → `src/<package_name>/`
  layout per [python-library.md](python-library.md); no `manage.py`, ship a `tests/` Django project.
- One Django app = one bounded context. Do not create a single god-app.

## Architecture rules

- **Views own HTTP concerns only** — request parsing, status codes, response serialisation.
  No business logic, no multi-step orchestration in a view.
- **Business logic lives in `services.py`** (write) and `selectors.py` (read). Services must not
  import `rest_framework`, `HttpRequest`, or `Response`.
- **Models and serializers are separate classes** — never expose a model directly as the wire format.
- **Fat models, thin views**: model methods may hold row-level invariants; cross-row / cross-model
  workflows belong in services.
- Settings come from environment via `django-environ` (or `os.environ` wrapped in `settings/base.py`).
  Never read `os.environ` outside the settings module.
- `DJANGO_SETTINGS_MODULE` defaults to `<project_name>.settings.dev`; CI uses `.settings.test`,
  prod uses `.settings.prod`.

## Models & choices

- **One model per file** under `models/`, named after the model; re-export from `models/__init__.py`. No god-model.
- Enumerated fields use `models.TextChoices` / `models.IntegerChoices` — never a free-form `CharField` for a closed set.
- Every `ForeignKey` / `OneToOneField` sets an explicit `on_delete` and a `related_name`.
- Every field carries `help_text`; add `verbose_name` when the attribute name is not self-explanatory.
- `db_index=True` (or `Meta.indexes`) on every field used in filters, ordering, or FK lookups.
- Query logic lives in custom **managers / QuerySets** (`objects = FooQuerySet.as_manager()`), never in views or serializers.

## DRF API design

- Use **Django REST Framework** for all JSON APIs. Server-rendered templates only for Django Admin.
- All paths use kebab-case and a version prefix: `/api/v1/user-profiles/{id}`.
- HTTP semantics: `POST` creates, `PUT` replaces, `PATCH` updates partial, `DELETE` removes.
- `ModelViewSet` for standard CRUD; `APIView` / `@action` for custom operations.
- **One serializer per representation** — split read vs write serializers when they diverge; never
  reuse a model instance as the response body.
- Register routes with DRF `DefaultRouter`; mount under `/api/v1/` in the root URLConf.
- Use `status.HTTP_*` constants, never magic integers.
- Validate input in serializer `validate_*` / `validate` methods — never trust raw `request.data`.

## Pagination, filtering, sorting

- Pagination is **mandatory** on every list endpoint. Set a global
  `DEFAULT_PAGINATION_CLASS` + `PAGE_SIZE`; cap `size` at **100**.
- Filtering via `django-filter` `FilterSet` classes, exposed through `filterset_class`.
- Ordering via DRF `OrderingFilter`; `-` prefix = DESC (`?ordering=-created_at`).
- Never return an unbounded queryset.

## Permissions & auth

- Set a restrictive global `DEFAULT_PERMISSION_CLASSES` (e.g. `IsAuthenticated`); relax per-view, never the reverse.
- Authn via JWT (`djangorestframework-simplejwt`) or session auth for the admin only.
- Authorization through DRF permission classes (`permissions.py`), not inline `if request.user...` in views.
- Object-level checks via `has_object_permission`; enforce tenant/owner scoping in `get_queryset()`.

## ORM & queries

- **Prevent N+1**: use `select_related` (FK/O2O) and `prefetch_related` (M2M/reverse FK) on every
  list endpoint. N+1 in a hot path is a blocking review failure.
- Keep queries in `selectors.py` / `services.py`, not in serializers or views.
- Index every field used in filters, ordering, or FK lookups (`db_index=True` / `Meta.indexes`).
- Use `QuerySet.only()` / `defer()` for wide models on list endpoints.
- Wrap multi-write operations in `transaction.atomic()`.

## Migrations

- Always run `makemigrations` and **commit the generated migration files**.
- Never hand-author schema migrations; for data migrations use `RunPython` with a reverse function.
- Never call `create_all` / raw `CREATE TABLE`. Migrations are the only schema source of truth.
- **Zero-downtime / backward-compatible** (rolling deploys): old and new code must coexist during the rollout, every migration is reversible and idempotent, and it completes in **< 10 s** on the largest production table.
- Add a non-nullable column in **two steps** — add it nullable (+ backfill), then set the constraint in a later migration. Never a single blocking `ALTER` on a hot table.
- `python manage.py lintmigrations` (django-migration-linter) **must pass before merge**.
- **Max 2–3 migration files per PR** — squash aggressively; no bloat from iterative development.
- Squash long migration chains on a `chore/` branch when they slow tests.

## Error handling

- Register a custom DRF `EXCEPTION_HANDLER` that returns a consistent error body
  (`{"type", "title", "status", "detail"}`); align with RFC 7807 where practical.
- Use `rest_framework.exceptions` (`ValidationError`, `PermissionDenied`, `NotFound`) — not bare `Http404`/asserts.
- Never expose stack traces, SQL, or internal paths in API responses. `DEBUG=False` in prod.

## Structured logging & observability

- Configure `LOGGING` for structured JSON in prod; emit `request_id`, `method`, `path`, `status`, `duration_ms`, `user_id`.
- Propagate `X-Request-ID` via middleware (pairs with `django-traceid`); return it on every response.
- **Never log PII** — mask email, tokens, passwords.
- Wire Sentry (`sentry-sdk[django]`) for 5xx capture.

## Health endpoints

| Path | Purpose | Auth |
|---|---|---|
| `GET /health` | General health | None |
| `GET /health/ready` | Readiness — runs `SELECT 1` against the DB | None |

- Exclude health endpoints from auth, throttling, and CORS restrictions.

## Settings & security

- `SECRET_KEY`, DB creds, and all environment-varying config come from env vars — never committed.
- `ALLOWED_HOSTS`, `CSRF_TRUSTED_ORIGINS`, `SECURE_*` flags set explicitly in `settings/prod.py`.
- `CORS_ALLOWED_ORIGINS` is an explicit whitelist; never `CORS_ALLOW_ALL_ORIGINS = True` in prod.
- Keep `DEBUG = False` outside local dev; never ship the default `SECRET_KEY`.
- Use Django's password hashers and validators; never store plaintext.

## Testing

- Use `pytest` + `pytest-django`; mark DB tests with `@pytest.mark.django_db`.
- Build fixtures with `factory-boy` (`DjangoModelFactory`) — avoid loading large JSON fixtures.
- Per endpoint, cover at minimum: happy path, validation error (400), auth failure (401/403), not-found (404).
- Use DRF `APIClient` for integration tests; assert on status + serialized body.
- Use the fast password hasher and a local-memory cache in `settings/test.py`.
- Coverage target: **85%+ lines** (services and serializers are the priority surface).

## Dependencies

- Pin versions in `pyproject.toml` under `[project.dependencies]`.
- Core: `django`, `djangorestframework`, `django-filter`, `django-environ`.
- Dev extras: `ruff`, `mypy` (with `django-stubs`), `pytest`, `pytest-django`, `factory-boy`.
