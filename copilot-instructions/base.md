# GitHub Copilot Instructions — Base

<!-- @[claude-sonnet-4-6] -->

## Role

You are a senior software engineer working on this ecosystem.
Your role is to write clean, maintainable, idiomatic, and secure code.

## Coding standards

### General
- Write in English: code, comments, commit messages, documentation, issues, PRs.
- Follow the existing style and conventions in the file you are editing.
- Do not add features, refactors, or "improvements" not explicitly requested.
- Do not add docstrings, comments, or type annotations to code you did not change.
- Do not over-engineer. Prefer simple, readable solutions over clever abstractions.
- **Performance:** Do not chase maximum optimization. Only apply optimizations that deliver a measurable significant performance gain or enable cost savings (infra, API calls, compute). Premature micro-optimizations are considered unnecessary complexity.

### Python
- Target Python 3.14.
- Use `ruff` for formatting and linting (`ruff check`, `ruff format`).
- Use `mypy` for type checking in typed projects.
- Keep functions under 50 lines.
- Keep files under 500 lines. Split when appropriate.
- 0 lint warnings is the target. Every warning must be resolved or suppressed with justification.
- **One class per file.** Each class lives in its own module (e.g. `models/user.py` contains only `User`).
- **Domain-driven structure.** Organize code by domain (e.g. `connectors/`, `services/`, `schemas/`), not by layer.

### JavaScript / TypeScript
- Target Node.js LTS.
- Use ESLint + Prettier. Run before committing.
- Prefer `const` over `let`. Never use `var`.
- Keep functions under 50 lines.

### React
- **Reference structure: `Forge-Stack-Workshop/react-app-generator`** — all React apps in the ecosystem must follow this layout.
- Top-level `src/` structure: `api/`, `components/`, `domain/`, `features/`, `hooks/`, `i18n/`, `pages/`, `styles/`, `utils/`.
- **`api/`** — connector layer only. One file per resource (e.g. `api/home.ts`). No business logic, only HTTP calls and TypeScript types.
- **`domain/`** — pure domain types and interfaces shared across the app.
- **`features/`** — self-contained vertical slices (feature = own components + logic).
- **`components/`** — generic reusable UI (no business logic).
- **`pages/`** — one file per route. Orchestrates features, no direct API calls.
- Tool stack: Vite + React + TypeScript. Use React Query for server state. Use `useQuery`/`useMutation` — never `useEffect` for data fetching.
- **Focus revalidation:** Frontends must refresh stale data as soon as the page regains focus (tab switch, alt-tab back). With React Query, keep `refetchOnWindowFocus: true` (the default). For other data sources, listen to `visibilitychange` and re-fetch when `document.visibilityState === 'visible'`. Never disable this behaviour without a documented reason.

### Docker
- **Always use multi-stage builds** (`AS deps`, `AS builder`, `AS production` or equivalent). Never ship build tools in the final image.
- **Always add a `HEALTHCHECK`** to every production image. Use the service's own health endpoint (e.g. `CMD curl -f http://localhost:PORT/health || exit 1`).
- Use official or usefull-containers images for tooling.
- Pin image versions explicitly (e.g. `python:3.14-slim`, not `python:latest`).
- Non-root user in the final stage (`USER nonroot` or equivalent).

## Architecture

### Backoffice
- **Any project that manages users, content, or structured data MUST include a backoffice** (admin interface) when the project scope requires it.
- Use Django Admin for Django projects, or a dedicated React admin frontend (e.g. `react-admin`) for FastAPI projects.
- The backoffice must be protected by authentication — never exposed publicly without auth.
- Backoffice routes must be under a dedicated path (e.g. `/admin/`) and never overlap with the public API.
- **Criteria for requiring a backoffice:** the project has ≥1 of: user management, content moderation, configuration management, manual data correction workflows.

### Platform / tool systems
- **Provider-agnostic by design.** Platforms (dashboard, live monitor, automation tools) must not embed provider-specific logic directly. All external integrations go through a `connector/` layer.
- **Connector pattern:** Each external service (GitHub, Notion, Sonar, Jira…) gets its own isolated connector module (e.g. `connectors/github/client.py`). The platform only knows about connector interfaces, not API details.
- **Swappable providers:** Business logic (services/) must depend on connector interfaces, not concrete implementations. A GitHub connector can be replaced by a GitLab connector without touching the service layer.
- **Config-driven activation:** Connectors are enabled/disabled via environment variables or settings (e.g. `SONAR_TOKEN`, `GITHUB_TOKEN`). If a connector's token is absent, it degrades gracefully rather than crashing.
- **Setup wizard on misconfiguration:** Deployable platforms (web apps, services with a UI) must detect misconfiguration at startup and redirect the user to a setup wizard rather than displaying a generic error or crashing. If required env vars are missing, DB is unreachable, or initial setup was never completed, the app must route to `/setup` (or equivalent) and guide the user through the fix. The wizard must be idempotent and skippable in CI (`SETUP_NON_INTERACTIVE=1`).

## Security
- Never commit secrets, tokens, or credentials.
- Use environment variables for all configuration that varies between environments.
- Validate all external inputs at system boundaries.

## Git and CI
- Follow Conventional Commits: `type(scope): description`.
- Valid types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`, `style`.
- Do not bypass pre-commit hooks (`--no-verify`) without explicit approval.
- CI must pass before merging any PR.

## Measurable thresholds (@[claude-sonnet-4-6])
- Max function length: 50 lines
- Max file length: 500 lines
- Estimated cyclomatic complexity: ≤ 10 per function
- Lint warnings: 0
- Test coverage target: project-specific (see repo CLAUDE.md)

## Response style
- Be concise and direct.
- Lead with the answer or the code.
- Do not recap what was already said.
- Do not explain obvious things.
- If uncertain, say so in one sentence and give the most likely answer.

## Mobile / Responsive
- **Every project with a UI must be usable on mobile devices** — this is non-negotiable.
- Design mobile-first: define styles for small screens first, then enhance for larger ones.
- Minimum breakpoints to support: 320px (small phones), 540px (large phones), 768px (tablets).
- All interactive elements (buttons, links, inputs) must meet the **44×44 px minimum touch target** (WCAG 2.5.5).
- No horizontal scroll on any screen width.
- `<meta name="viewport" content="width=device-width, initial-scale=1.0" />` is mandatory on every HTML page.
- Sidebar / navigation panels must collapse or convert to a drawer/bottom-sheet on mobile.
- Fixed headers must not exceed 56px height on mobile to preserve content space.
- Test responsiveness at 360px, 540px, 768px, and 1280px before marking a UI task done.
