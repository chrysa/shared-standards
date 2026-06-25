# GitHub Copilot Instructions — FastAPI

<!-- @[claude-sonnet-4] -->

Extends [base.md](base.md). Read base rules first; rules here take precedence where they conflict.

## Scaffolding

New FastAPI modules (router / schemas / models / service / dependencies + Alembic stub)
**must** be generated from a YAML spec with `Forge-Stack-Workshop/fastapi-app-generator`
(`fastapi-app-generator` CLI). Never hand-copy a module from a sibling service or
hand-roll the boilerplate. Keep generated modules consistent with the layout below.

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
  constants.py  # typed loader exposing constants read from external YAML (Final)
  config/       # external YAML files holding all constants & config values
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
- No hardcoded constants in code: thresholds, business rules, labels, URLs and magic
  numbers live in external YAML under `config/`, loaded once via `constants.py`. Only
  `status.HTTP_*` and language enums are exempt.

## API design

- All paths use kebab-case: `/user-profiles/{id}`.
- Version prefix: `/api/v1/`.
- HTTP semantics: `POST` creates, `PUT` replaces, `PATCH` updates partial, `DELETE` removes.
- Always return typed Pydantic response models, not raw dicts.
- Use `status.HTTP_*` constants, not magic integers.
- Validate path and query params with Annotated types and field constraints.

## HATEOAS (NON-NEGOTIABLE)

Every endpoint that returns a resource or collection **MUST** include a `links` field. Clients must be able to navigate the entire API from links — no hardcoded paths allowed.

```python
class Link(BaseModel):
    href: str
    rel: str
    method: str = "GET"

class ResourceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    # ... resource fields ...
    links: list[Link]
```

- `links` is **required** on every response model, never optional.
- Standard rels: `self`, `collection`, `next`, `prev`, `first`, `last`, `related`, `create`, `update`, `delete`.
- Follow [IANA link relations](https://www.iana.org/assignments/link-relations/) where applicable.
- Build URLs via `request.url_for()` or `str(request.base_url)` — never hardcode host/port.
- Collection responses must include `total`, `page`, `size` and full pagination links (`next`, `prev`, `first`, `last`).

## RFC 7807 — Problem Details

All error responses **MUST** use [RFC 7807](https://www.rfc-editor.org/rfc/rfc7807) with `Content-Type: application/problem+json`.

```python
class ProblemDetail(BaseModel):
    type: str = "about:blank"
    title: str
    status: int
    detail: str
    instance: str  # request URL
```

- Register a global `HTTPException` handler in `main.py` that wraps all errors in `ProblemDetail`.
- Never return FastAPI's default `{"detail": "..."}` in production.
- Never expose stack traces or internal paths in `detail` or `instance`.

## Health endpoints

Every API must expose:

| Path | Purpose | Auth |
|---|---|---|
| `GET /health` | General health | None |
| `GET /health/live` | Kubernetes liveness | None |
| `GET /health/ready` | Kubernetes readiness (checks DB) | None |

- `HealthResponse`: `{"status": "ok" | "degraded" | "down", "version": "x.y.z"}`.
- `/health/ready` must execute `SELECT 1` to verify DB reachability.
- Health endpoints are excluded from auth, rate limiting, and CORS restrictions.

## Filtering, sorting, search

- `sort`: `-` prefix = DESC. Example: `?sort=-created_at,name`.
- Filters: bracket notation `?filter[status]=active` — never flat `?status=active`.
- `search`: full-text on documented fields.
- `size` max: **100** — never allow unbounded collection queries.
- Use a shared `CollectionParams` Pydantic model injected via `Depends()`.

## Idempotency

- Critical `POST` endpoints (payments, bookings, notifications) must accept `Idempotency-Key` header.
- Store the key on the resource row; return the identical response on replay within 24 h.
- Document supported endpoints in Swagger.

## API versioning & deprecation

- Version prefix: `/api/v1/` — bump to `/api/v2/` on breaking changes only.
- Deprecated endpoints must set response headers: `Deprecation: true`, `Sunset: <RFC7231 date>`, `Link: </api/v2/resource>; rel="successor-version"`.
- Minimum deprecation window: **3 months**. Remove only after Sunset date and zero traffic.

## Structured logging & observability

- Every request must emit a structured JSON log: `timestamp`, `request_id`, `method`, `path`, `status`, `duration_ms`, `user_id`.
- Propagate `X-Request-ID` from incoming request or generate one; return it in every response.
- **Never log PII** — mask or omit email, token, password, card data.
- Log level: `WARNING` for 4xx, `ERROR` for 5xx.
- Wire Sentry in `lifespan` for 5xx exception capture.
- Add a `RequestLoggingMiddleware` that sets `X-Request-ID` and emits the access log entry.

## Rate limiting

- Use `slowapi`. Always include rate limit headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`, `Retry-After` (on 429).
- Default limits: login/register `5/min` · public reads `100/min` · authenticated `1000/min`.
- 429 body must be a `ProblemDetail` with `type: "urn:problem:rate-limit-exceeded"`.

## HTTP caching

- Return `ETag` (content hash) and `Cache-Control` on read-heavy GET endpoints.
- Respond `304 Not Modified` when `If-None-Match` matches the current ETag.
- `Cache-Control: private` for authenticated resources, `no-store` for collections and mutations.

## Long-running async operations

- Operations > ~2 s: return `202 Accepted` + `JobResponse` with `links.status`; run in `BackgroundTasks` or ARQ.
- `JobResponse` fields: `job_id`, `status` (`pending|running|done|failed`), `result`, `error`, `links`.
- Polling endpoint returns `Retry-After` header while job is in progress.

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
