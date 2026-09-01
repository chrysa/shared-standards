# chrysa — Settled Stack (concrete choices)

> This annexe is the deliberate record of chrysa's **concrete, settled stack choices** — the
> products and versions the ecosystem has agreed on and does not relitigate. Unlike the
> transverse canon (`standards/STANDARDS.chrysa.md`), which is **product-agnostic** and names
> functional categories rather than vendors, this file **names products on purpose**: it is the
> answer to "which concrete tool implements the category the canon mandates".
>
> These are settled ADR outcomes — do not relitigate them here; a change is a new ADR
> (`docs/adr/`, `/adr-new`). Where this annexe and the canon disagree, **the canon wins**: the
> canon states the obligation (a reverse proxy, an error-tracking service, a local model
> runtime), this annexe records the current pick (see below).

## Cross-cutting stack (settled ADRs — do not relitigate)

| Layer            | Decision                                                        |
|------------------|----------------------------------------------------------------|
| Python           | 3.14 target (CI matrix 3.12 + 3.14)                            |
| FastAPI          | >= 0.115 + Pydantic v2                                          |
| Frontend         | React 19 + TypeScript 7 + Vite 8                                |
| UI               | shadcn/ui + Tailwind CSS                                        |
| State            | TanStack Query + Zustand                                        |
| DB               | PostgreSQL 16 + Redis 7                                         |
| ORM              | SQLAlchemy 2.0 async + Alembic                                  |
| Auth             | Cluster SSO (OIDC) → external OAuth → local (bcrypt) · MFA-capable |
| i18n             | react-i18next + fastapi-babel · FR + EN from V1                 |
| Monorepo         | Turborepo + pnpm workspaces                                     |
| Versioning       | [GitVersion](https://gitversion.net/) (semantic auto — never bump manually) |
| Quality CI       | SonarCloud (0 hotspot · rating A)                               |
| Linting          | Ruff + Mypy (Python) · ESLint (TS)                             |
| Pre-commit       | detect-secrets + ruff + mypy + commitlint                      |
| Error handling   | withErrorHandling() → auto GitHub Issue on failure             |
| Hosting          | Kimsufi · Docker Compose (local) · Nginx · Certbot · Tailscale  |
| Monitoring       | Sentry + Uptime Kuma (self-hosted)                            |
| Agents           | Claude API (primary) · Ollama (fallback)                       |
| Orchestration    | LangGraph (stateful) · PydanticAI (structured outputs)         |
| Registry         | GHCR private `ghcr.io/chrysa/{repo}` — never public            |
| Docs             | MkDocs → GitHub Pages (`pages.yml`) · ADRs in `docs/adr/`       |
| Changelog        | [git-cliff](https://git-cliff.org/) (`cliff.toml`) · Keep a Changelog |
