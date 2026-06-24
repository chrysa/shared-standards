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

> **Brand-theme tracking (ADR 0003).** As of 2026-06-22 the UI track no longer
> tracks per-app *persona* — it tracks **brand-brief + signature + contract
> conformance** per the per-app brand-theme model. Rollout is **one repo per
> session** (Rule 1+2): brand-brief → theme tokens → signature → IA → a11y → PR.
> Conformance is verified by `scripts/audit-design-conformance.sh` (the contract:
> WCAG 2.1 AA + FR/EN i18n floor, semantic token names present, signature element
> declared, IA not generic). The UI table columns below:
> - **Brand brief** — ✓ (or link) once the app's `BRAND-BRIEF.md` exists.
> - **Signature** — one-word name of the app's signature element + ✓ once declared.
> - **Contract** — ✓ once the app imports `contract.css` **and** passes
>   `scripts/audit-design-conformance.sh`.
>
> `gaming-os`, `studioverse`, `ai-aggregator` were persona-migrated under the
> superseded ADR 0002; they fold into the brand-theme model retroactively (no
> urgency) and show **persona-migrated; brand-brief + signature pending** until the
> rollout reaches them.

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

Build on `docs/DESIGN-SYSTEM.md` + ADR 0003 (brand themes). Conformance is
verified by `scripts/audit-design-conformance.sh` (do not reinvent).

Columns: **Brand brief** = `BRAND-BRIEF.md` exists (✓/link); **Signature** =
one-word name of the app's signature element + ✓ once declared; **Contract** = ✓
once the app imports `contract.css` AND passes
`scripts/audit-design-conformance.sh`. Empty = pending (the rollout fills it).

| Repo | Status | PR | Brand brief | Signature | Contract | Notes |
|---|---|---|---|---|---|---|
| gaming-os | ✓ done | #128 | pending | pending | pending | persona-migrated; brand-brief + signature pending |
| ai-aggregator | ✓ done | #159 | pending | pending | pending | persona-migrated; brand-brief + signature pending |
| studioverse | ✓ done | #65 | pending | pending | pending | persona-migrated; brand-brief + signature pending |
| mirrador | ✓ done | #137 | pending | pending | pending | request-inspector IA (pilot); merged 2026-06-13 (was Console persona) |
| dev-nexus | ✓ done | #327 | pending | pending | pending | IA brief; token migration was #279 (was Console persona, data-persona to drop) |
| devtool | ✓ done | #120 | pending | pending | pending | trace_id-correlated incident Inspector IA (master/detail); merged 2026-06-22 |
| container-webview | ✓ done | #203 | pending | pending | pending | Project Workspace master/detail + derived live health; merged 2026-06-22 |
| satisfactory-factory-manager | frozen | — | pending | pending | pending | React 19; V1 gate (2026-06-24) journal empty → Fail/freeze (human call). IA excluded while frozen |
| discordium | ✓ done | #155 | pending | pending | pending | Command-HUD + Build/Research queue IA (live countdowns); merged 2026-06-22. Arcade surface = #154 |
| D-D | blocked | — | pending | pending | pending | SvelteKit — bare starter scaffold, zero domain. IA needs a JTBD/domain spec first |
| PO-GO-DEX | blocked | — | pending | pending | pending | SvelteKit — bare starter scaffold, zero domain. IA needs a JTBD/domain spec first |
| my-resume | n/a | — | pending | pending | pending | SvelteKit scaffold, DEPRECATED (superseded by linkendin-resume) → archive candidate |
| linkendin-resume | ✓ done | #230 | ✓ #226 | logbook index-rail | ✓ #226 | React 19; IA already document-appropriate (monograph). #230 = surface skill tier in print |

> **Phase 4 IA track is effectively complete (2026-06-24).** Every buildable
> frontend has had its IA pass; the rest are not actionable as IA work:
> `D-D` / `PO-GO-DEX` are bare SvelteKit scaffolds with no domain (need a JTBD
> spec first), `my-resume` is a deprecated scaffold (archive), and
> `satisfactory-factory-manager` is frozen pending its human V1 gate verdict.
> Do **not** manufacture an IA pass for an app that already serves its job — the
> doctrine is "surface the data the app already has," not invent new screens.

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
