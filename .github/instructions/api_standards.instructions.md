---
applyTo: "**/api/**/*.py,**/routers/**/*.py,**/endpoints/**/*.py"
---

# API Standards — chrysa ecosystem

## Versioning

All APIs MUST be versioned in the URL path.

```python
# ✅ Correct
app.include_router(router, prefix="/api/v1")

# ❌ Forbidden
app.include_router(router, prefix="/api")
app.include_router(router)
```

Breaking changes → increment version: `/api/v2/`. Never modify existing versioned contracts.

## URL Structure

```
/api/v1/{resource}              # list
/api/v1/{resource}/{id}         # single
/api/v1/{resource}/{id}/{sub}   # sub-resource
```

Rules:
- Plural nouns only: `/projects`, `/users`, `/characters`
- No verbs in path: ❌ `/getProjects`, ❌ `/createUser`
- kebab-case for multi-word: `/character-sheets`, `/skill-checks`

## HATEOAS

Every response MUST include a `_links` object:

```json
{
  "data": { "id": "abc", "name": "Gandalf" },
  "_links": {
    "self":    { "href": "/api/v1/characters/abc" },
    "update":  { "href": "/api/v1/characters/abc", "method": "PATCH" },
    "delete":  { "href": "/api/v1/characters/abc", "method": "DELETE" },
    "campaign": { "href": "/api/v1/campaigns/xyz" }
  }
}
```

FastAPI implementation:

```python
from pydantic import BaseModel, AnyHttpUrl

class Link(BaseModel):
    href: AnyHttpUrl
    method: str = "GET"

class Links(BaseModel):
    self: Link
    update: Link | None = None
    delete: Link | None = None

class CharacterResponse(BaseModel):
    data: CharacterData
    links: Links = Field(alias="_links")

    model_config = ConfigDict(populate_by_name=True)
```

## Pagination

All list endpoints MUST support pagination via query parameters:

```
GET /api/v1/characters?page=1&page_size=20
GET /api/v1/characters?page=2&page_size=50&sort=name:asc
```

**Response envelope**:

```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 142,
    "pages": 8,
    "has_next": true,
    "has_prev": false
  },
  "_links": {
    "self":  { "href": "/api/v1/characters?page=1&page_size=20" },
    "next":  { "href": "/api/v1/characters?page=2&page_size=20" },
    "prev":  null,
    "first": { "href": "/api/v1/characters?page=1&page_size=20" },
    "last":  { "href": "/api/v1/characters?page=8&page_size=20" }
  }
}
```

**Pydantic models**:

```python
from pydantic import BaseModel
from typing import Generic, TypeVar

T = TypeVar("T")

class PaginationMeta(BaseModel):
    page: int
    page_size: int
    total: int
    pages: int
    has_next: bool
    has_prev: bool

class PaginatedResponse(BaseModel, Generic[T]):
    data: list[T]
    pagination: PaginationMeta
    links: Links = Field(alias="_links")

    model_config = ConfigDict(populate_by_name=True)

class PaginationParams(BaseModel):
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)
    sort: str | None = Field(default=None, pattern=r"^[\w]+:(asc|desc)$")
```

## Filtering

Filtering via query parameters using `filter[field]=value` convention:

```
GET /api/v1/characters?filter[class]=wizard&filter[level]=5
GET /api/v1/characters?filter[level__gte]=3&filter[level__lte]=10
```

Supported operators: `eq` (default), `gte`, `lte`, `contains`, `in`.

```python
from fastapi import Query

@router.get("", response_model=PaginatedResponse[CharacterResponse])
async def list_characters(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    sort: str | None = Query(default=None, pattern=r"^[\w]+:(asc|desc)$"),
    filter_class: str | None = Query(default=None, alias="filter[class]"),
    filter_level: int | None = Query(default=None, alias="filter[level]"),
    service: CharacterService = Depends(get_service),
) -> PaginatedResponse[CharacterResponse]:
    ...
```

## Swagger / OpenAPI

**Mandatory** on every endpoint:

```python
@router.get(
    "",
    response_model=PaginatedResponse[CharacterResponse],
    status_code=status.HTTP_200_OK,
    summary="List characters",
    description="Returns a paginated, filterable list of characters for the current campaign.",
    responses={
        200: {"description": "Paginated list of characters"},
        400: {"description": "Invalid filter or sort parameters"},
        401: {"description": "Missing or invalid JWT token"},
        403: {"description": "Insufficient permissions"},
    },
    tags=["characters"],
)
async def list_characters(...): ...
```

App-level OpenAPI config:

```python
app = FastAPI(
    title="chrysa API",
    version="1.0.0",
    description="REST API — versioned, HATEOAS, paginated",
    openapi_url="/api/v1/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
    contact={"name": "chrysa", "url": "https://github.com/chrysa"},
    license_info={"name": "MIT"},
)
```

## HTTP Status Codes

Always use `fastapi.status` or `http.HTTPStatus` constants — **never** raw integers:

```python
from fastapi import status

# ✅ Correct
status.HTTP_200_OK
status.HTTP_201_CREATED
status.HTTP_204_NO_CONTENT
status.HTTP_400_BAD_REQUEST
status.HTTP_401_UNAUTHORIZED
status.HTTP_403_FORBIDDEN
status.HTTP_404_NOT_FOUND
status.HTTP_409_CONFLICT
status.HTTP_422_UNPROCESSABLE_ENTITY
status.HTTP_429_TOO_MANY_REQUESTS

# ❌ Forbidden
return JSONResponse(content={}, status_code=200)
```

## Error Response Format

```json
{
  "error": {
    "code": "CHARACTER_NOT_FOUND",
    "message": "No character with id 'abc' exists.",
    "detail": null
  }
}
```

```python
class APIError(BaseModel):
    code: str
    message: str
    detail: dict | None = None

class ErrorResponse(BaseModel):
    error: APIError
```

Never expose internal stack traces or DB errors in error bodies.

## Authentication

- Auth via `Authorization: Bearer <token>` header — never query params
- Use `Depends(get_current_user)` on every protected route
- Rate limit public/unauthenticated endpoints (e.g., `slowapi`)
- CORS: explicit `allow_origins` list — never `["*"]` in production

## Security (OWASP)

- Validate all inputs via Pydantic schemas — never trust raw request data
- No sensitive data in `4xx`/`5xx` error bodies
- Sanitize string inputs used in queries (SQLAlchemy ORM — no raw SQL)
- Secrets via env vars only — never hardcoded
