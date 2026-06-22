# Interface Review Ledger — portfolio-wide coherence campaign

> Goal: make every product's interface optimal and **coherent per product
> family**. "Interface" = public API for libs, HTTP surface for services,
> UI for frontends, CLI for tools.
>
> Driving standards: `docs/PUBLIC-API-CONTRACT.md` (libs),
> `CODE_MANIFEST.md` §3 (services), `docs/UX-UI-GUIDELINES.md` +
> `.claude/skills/ui-ux/SKILL.md` (UI), this ledger (tracking).
>
> Execution rule: **Rule 1+2** — max 1 Socle + 2 Actifs repos in flight.
> One family per session. Each repo: review → P0/P1/P2 findings →
> worktree → fix → `make test` (Docker) → `review` agent → draft PR → mark.
>
> Status legend: `todo → in-review → fix → PR-open → merged`

## Phase 1 — Lib mirror families `django-*` / `fastapi-*`

| Repo | Status | PR | P0/P1/P2 | Notes |
|---|---|---|---|---|
| django-traceid | PR-open | #23 | — | ✅ src/ migration + importlib.metadata; Docker 29 pass cov 98.7% |
| fastapi-traceid | PR-open | #4 | — | ✅ importlib.metadata; Docker 27 pass cov 97.9% |
| django-query-optimizer | PR-open | #57 | — | ✅ metadata, relative imports, export `Severity`, sorted `__all__`; Docker 288 pass cov 95% |
| fastapi-query-optimizer | PR-open | #4 | — | ✅ metadata, relative imports; `__getattr__` kept (justified); Docker 179 pass |
| django-pytest | PR-open | #28 | — | ✅ src/ migration + importlib.metadata + `__all__`; Docker 45 pass cov 85% |
| fastapi-pytest | PR-open | #4 | — | ✅ importlib.metadata + relative imports + RUF022 `__all__`; Docker 135 pass cov 97% |
| django-autoload | PR-open | #17 | — | ✅ hatchling→setuptools backend + importlib.metadata; Docker 19 pass |
| fastapi-autoload | PR-open | #4 | — | ✅ importlib.metadata; Docker 21 pass cov 96.7% |
| django-app-forge | PR-open | #29 | — | ✅ src/ migration + importlib.metadata; Docker 32 pass cov 93% |
| fastapi-app-forge | PR-open | #4 | — | ✅ importlib.metadata; Docker 95 pass cov 96.2% |

## Phase 2 — Other libs (chrysa-lib first: extract shared enums)

| Repo | Status | PR | Notes |
|---|---|---|---|
| chrysa-lib | todo | — | Socle — host shared `Severity` and friends (C7) |
| doc-gen | todo | — | |
| discord-bot-back | todo | — | |
| guideline-checker | todo | — | issue #98 open (allowlist) |
| pre-commit-tools | todo | — | large surface (~1214 symbols) |
| quality-gatekeeper | todo | — | |
| chrysa-portfolio-viz | todo | — | |
| ai-aggregator | ✓ done | #159 | design campaign |

## Phase 3 — API-only services (CODE_MANIFEST §3 conformance)

| Repo | Status | PR | Notes |
|---|---|---|---|
| audit-platform | todo | — | |
| cdn-explorer | todo | — | |
| sport-intelligence-hub | todo | — | |
| link-reader-bot | todo | — | phase 3 semantic search blocked on ai-aggregator embeddings |
| feedback-gateway | todo | — | stateless gateway |
| mirrador | todo | — | API surface (UI tracked in Phase 4) |

## Phase 4 — UI (= existing Design Campaign, epic 37759293e35e81e1973ce30839822b79)

Build on `docs/UX-UI-GUIDELINES.md` + `DESIGN-SYSTEM.md` (do not reinvent).

| Repo | Status | PR | Notes |
|---|---|---|---|
| gaming-os | ✓ done | #128 | |
| ai-aggregator | ✓ done | #159 | |
| studioverse | ✓ done | #65 | |
| mirrador | ✓ done | #137 | Console persona + request-inspector IA (pilot); merged 2026-06-13 |
| dev-nexus | ✓ done | #327 | Console persona conformance (data-persona + IA brief); token migration was #279 |
| devtool | todo | — | React — resume here (6/16) |
| container-webview | todo | — | React |
| satisfactory-factory-manager | todo | — | React 19 |
| discordium | todo | — | React; CI red, PRs #89/#90 open |
| D-D | todo | — | SvelteKit |
| PO-GO-DEX | todo | — | SvelteKit |
| my-resume | todo | — | SvelteKit (predecessor of linkendin-resume) |
| linkendin-resume | todo | — | React 19 |

## Phase 5 — CLI + VS Code extension

| Repo | Status | PR | Notes |
|---|---|---|---|
| coach | todo | — | |
| genealogy-validator | todo | — | |
| diy-stream-deck | todo | — | |
| floating-agent | todo | — | overlay; lifeos/my-assistant are siblings |
| gestureOS | todo | — | pre-alpha |
| lifeos | todo | — | pre-alpha (sibling of my-assistant) |
| my-assistant | todo | — | pre-alpha |
| notion-readme-sync | todo | — | |
| pilote-paperclip | todo | — | |
| project-init | todo | — | |
| satisfactory-automated_calculator | todo | — | GAS |
| windows-docker-state-notification | todo | — | |
| pre-commit-hooks-changelog | todo | — | |
| automations | todo | — | Node/GAS |
| django-query-optimizer-vscode | todo | — | `contributes.commands` naming |

## Out of scope
agent-config, catalog, chrysa-skills, claude-config, dotfiles,
github-actions, homeassistant-config, infra-v2, orchestrator, paperclip,
server, shared-standards, usefull-containers, windows-autonome (infra/meta);
django_auto_discover, game-solver-platform, mediavault (stub/empty).
