# GitHub Copilot Instructions — Monorepo

<!-- @[claude-sonnet-4] -->

Extends [base.md](base.md). Read base rules first; rules here take precedence where they conflict.

## Tooling

- Package manager: `pnpm` with workspaces.
- Build orchestration: `turborepo` (or `nx` for large repos).
- Versioning: `changesets` for independent package versioning.
- Root `package.json` is the workspace root — never install app deps there.

## Layout

```
apps/
  web/          # React frontend
  api/          # FastAPI / Express backend
  docs/         # documentation site
packages/
  ui/           # shared design system
  utils/        # shared utility functions
  types/        # shared TypeScript types / Pydantic models
  config/       # shared tooling config (eslint, tsconfig, ruff)
```

## Rules

- Each `packages/*` package must be independently publishable (`package.json` with `name`, `version`, `exports`).
- Cross-package imports use the package name, never relative `../../packages/...` paths.
- `apps/*` must not import from each other.
- `packages/*` must not import from `apps/*`.
- Shared configuration (ESLint, TypeScript, Ruff) lives in `packages/config` and is extended, not duplicated.

## CI

- All CI jobs use `--filter` to only run affected packages.
- Cache `pnpm store` and Turborepo cache in CI.
- Release is automated via `changesets/action` on merge to `main`.

## Makefiles

- Root `Makefile` extends `Forge-Stack-Workshop/base-makefile`.
- Targets delegate to Turborepo: `make dev` → `turbo run dev`, `make test` → `turbo run test`.
- Never duplicate per-package targets in root — use filters instead.

## Versioning

- Each package has its own semver version managed by `changesets`.
- Add a changeset for every user-facing change: `pnpm changeset`.
- `CHANGELOG.md` per package is auto-generated on release.
- Breaking changes bump major; new features bump minor; fixes bump patch.

## Dependency management

- Hoist common devDependencies to workspace root (`pnpm add -Dw`).
- Pin workspace deps with `workspace:*` protocol in `package.json`.
- Renovate or Dependabot must be configured for workspace-wide updates.
