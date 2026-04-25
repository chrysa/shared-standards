# GitHub Copilot Instructions — FastAPI

<!-- @[claude-sonnet-4] -->

Extends [base.md](base.md). Read base rules first; rules here take precedence where they conflict.

## Project layout

```
app/
  api/          # routers, grouped by resource
  core/         # settings, security, startup
  db/           # session, base model, migrations
  models/       # SQLAlchemy ORM models
  schemas/      # Pydantic request/response schemas
  services/     # business logic (no HTTP or ORM imports)
  dependencies/ # FastAPI Depends() factories
  constants.py  # app-wide constants (Final)
tests/
  unit/
  integration/
  conftest.py
```

## Architecture rules

- Routers own HTTP concerns only (request parsing, response serialisation, status codes).
- Services own business logic — they must not import FastAPI, Request, or Response.
- ORM models and Pydantic schemas are separate classes; never share them.
- Use `Depends()` for DB sessions, auth, pagination — never pass them as plain args.
- Settings come from `pydantic_settings.BaseSettings`; never use `os.environ` directly.

## API design

- All paths use kebab-case: `/user-profiles/{id}`.
- Version prefix: `/api/v1/`.
- HTTP semantics: `POST` creates, `PUT` replaces, `PATCH` updates partial, `DELETE` removes.
- Always return typed Pydantic response models, not raw dicts.
- Use `status.HTTP_*` constants, not magic integers.
- Validate path and query params with Annotated types and field constraints.

## Database

- Use SQLAlchemy 2.x async (`AsyncSession`).
- One session per request via `Depends(get_db)`.
- Migrations with Alembic — always generate migration files, never `create_all()` in production.
- Keep queries in service layer, not in routers.

## Error handling

- Use `HTTPException` for client errors (4xx).
- Use a global exception handler for unexpected server errors (5xx) — log and return a safe message.
- Never expose stack traces or internal DB errors to the client.

## Security

- Authenticate via JWT (`python-jose` or `python-jose[cryptography]`). Validate `aud`, `iss`, `exp`.
- Hash passwords with `passlib[bcrypt]` — never store plaintext.
- CORS: whitelist explicit origins, never `allow_origins=["*"]` in production.
- Rate-limit sensitive endpoints (login, register) with `slowapi` or a middleware.
- Sanitise user input — use Pydantic validators; never interpolate input into SQL.

## Testing

- Use `pytest` + `httpx.AsyncClient` + `pytest-asyncio`.
- Integration tests hit a real test DB (Postgres in Docker).
- At minimum: happy path, validation error (422), auth failure (401/403) per endpoint.
- Coverage target: 80%+ lines on services layer.

## Dependencies

- Pin versions in `pyproject.toml` under `[project.dependencies]`.
- Use `uv` or `pip-tools` to manage lock files.
- Dev extras: `ruff`, `mypy`, `pytest`, `pytest-asyncio`, `httpx`, `factory-boy`.
