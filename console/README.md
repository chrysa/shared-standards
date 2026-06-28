# standards-console

Local management console for the chrysa shared-standards fleet. A thin
GitHub-API-backed app: it holds almost no local state — the fleet, `repos.yml`,
the canonical standard, workflow runs and PRs are read live from GitHub, and
writes go back through the API. Compliance is read from the hosted
guideline-checker central server when configured.

Hybrid by design: monitoring is hosted (the guideline-checker central server),
write actions run locally with your own GitHub token.

## Architecture

```
console/
├── standards_console/     FastAPI JSON API (Python 3.12+)
│   ├── github_gateway.py  the ONLY GitHub API access point
│   ├── manifest.py        repos.yml round-trip edits (ruamel)
│   ├── standard.py        standard edits → open a PR
│   ├── distribution.py    trigger distribute-standards, list runs/PRs
│   ├── compliance.py      read the central server
│   ├── config.py          Pydantic Settings + constants.yaml loader
│   └── app.py             top-level route handlers, JSON only
└── web/                   React 19 + Vite 6 + TS SPA
    └── src/               shadcn/ui-style components, TanStack Query,
                           react-i18next (FR + EN), dark mode, WCAG AA
```

No constant is inlined in code: tunables live in `standards_console/constants.yaml`
and load through the typed `config.Constants` model (chrysa standard).

| Surface | Reads | Writes |
|---|---|---|
| **Fleet** | live repo list + `repos.yml` + compliance | `status` → **direct commit** to `repos.yml` |
| **Distribution** | recent runs + open sync PRs | triggers the workflow (check / apply) |
| **Standard** | `STANDARDS.chrysa.md` | edit → **opens a PR** |

## Run

```bash
# Backend (terminal 1)
uv venv && uv pip install -e '.[dev]'
standards-console                       # JSON API on http://127.0.0.1:8765

# Frontend dev server (terminal 2) — proxies /api to the backend
cd web && pnpm install && pnpm dev      # http://localhost:5173
```

Production single-process: `cd web && pnpm build` emits the SPA into
`standards_console/web_dist/`, which the backend serves at `/`.

The token is resolved from `GITHUB_TOKEN`/`GH_TOKEN`, falling back to
`gh auth token`. Nothing is stored.

## Configuration (all optional — sensible defaults)

| Env var | Default | Purpose |
|---|---|---|
| `STANDARDS_ORG` | `chrysa` | GitHub org/owner |
| `STANDARDS_REPO` | `shared-standards` | source-of-truth repo |
| `STANDARDS_BRANCH` | `main` | default branch |
| `STANDARDS_FILE` | `standards/STANDARDS.chrysa.md` | canonical standard |
| `STANDARDS_MANIFEST` | `repos.yml` | fleet manifest |
| `STANDARDS_DISTRIBUTE_WORKFLOW` | `distribute-standards.yml` | workflow to dispatch |
| `GUIDELINE_CENTRAL_URL` | — | compliance server base URL |
| `GUIDELINE_CENTRAL_API_KEY` | — | `X-Api-Key` for the server |
| `CONSOLE_HOST` / `CONSOLE_PORT` | `127.0.0.1` / `8765` | bind address |

## Test

```bash
uv run pytest --cov=standards_console      # backend (94% cov)
ruff check . && mypy standards_console
cd web && pnpm test && pnpm lint && pnpm build
```
