---
fka_managed: true
source: notion
notion_id: 37659293-e35e-810e-94f1-fd89739b10ff
notion_url: https://app.notion.com/p/Standard-Documentation-structure-37659293e35e810e94f1fd89739b10ff
notion_last_edited_time: 2026-07-20T21:13:00.000Z
---
# 📐 Standard — Documentation structure

> Org-wide standard for the documentation skeleton every chrysa repo carries. Source of truth: [`chrysa/shared-standards`](https://github.com/chrysa/shared-standards/tree/main/templates/docs-structure)[ › ](https://github.com/chrysa/shared-standards/tree/main/templates/docs-structure)[`templates/docs-structure/`](https://github.com/chrysa/shared-standards/tree/main/templates/docs-structure). New repos inherit it automatically via `/chrysa-init`; existing repos are backfilled gradually.
## Why
Every repo should expose the same predictable set of docs so humans and AI agents can navigate any project the same way. This standardizes product/architecture docs, AI assets, schemas, workflows, decisions, postmortems, tests, and reference "perfect" examples.
## The tree
```javascript
docs/        app-spec, architecture, business-rules, brand-brief, data-dictionary,
             api-contracts, integrations, personas, ux-rules, copywriting-guide,
             coding-standards, system-patterns, domain-glossary, decision-log,
             security, deployment, observability, changelog, known-issues,
             anti-patterns, feature-backlog, error-journal
ai/          CLAUDE.md (pointer), prompt-library, evaluation-datasets
prompts/     onboarding / support / sales / extraction / classification agents
schemas/     user / project / payment  (JSON Schema 2020-12)
workflows/   auth / onboarding / billing / notification flows
decisions/   _TEMPLATE + DEC-NNN records
postmortems/ _TEMPLATE + incident records
tests/       edge-cases, regression-tests, e2e-scenarios
examples/    "perfect" reference implementations (python OR node per stack)
```
Files ship as **stubs** marked `status: stub` — placeholders to fill per project.
## Reconciliation (no duplication of existing canon)
- Never overwrites an existing root `CLAUDE.md`, `AGENTS.md`, `README.md`, `CHANGELOG.md`, `DECISIONS.md`, or `docs/adr/`.
- `ai/CLAUDE.md` and `docs/changelog.md` are **pointers** to root canon.
- `docs/decision-log.md` **indexes** `docs/adr/` + root `DECISIONS.md`.
- `examples/` is **stack-split**: Python (DRF/pydantic) or Node (React/TS).
## Propagation
- **New repos**: `/chrysa-init` copies `docs-structure/` and keeps the stack-matching `examples/` (node for frontend/fullstack, python otherwise).
- **Existing repos**: backfilled per sprint via a `docs/standard-doc-structure` PR.
## Rollout status — ✅ FULLY SHIPPED (verified 2026-06-22)
<table header-row="true">
<tr>
<td>Repo</td>
<td>Role</td>
<td>PR</td>
</tr>
<tr>
<td>chrysa/shared-standards</td>
<td>canonical source + [CLAUDE.md](http://CLAUDE.md) ref</td>
<td>#82</td>
</tr>
<tr>
<td>chrysa/claude-config</td>
<td>wire `/chrysa-init` copy step</td>
<td>#57</td>
</tr>
<tr>
<td>chrysa/project-init</td>
<td>adopt (python)</td>
<td>#79</td>
</tr>
<tr>
<td>Forge-Stack-Workshop/react-app-generator</td>
<td>adopt + scaffold emits into generated apps (react)</td>
<td>#84</td>
</tr>
<tr>
<td>chrysa/django-app-forge</td>
<td>backfill (python)</td>
<td>#11</td>
</tr>
<tr>
<td>chrysa/discordium</td>
<td>backfill (python)</td>
<td>#112</td>
</tr>
</table>
*All six PRs merged — verified live on **`main`** 2026-06-22: shared-standards **`templates/docs-structure/`** = 60 files (**`ea71b93`**); **`/chrysa-init`** copy step active (**`chrysa-init.md:38`**); react-app-generator scaffold emits the tree (**`scaffold.mjs:1143`**); project-init, django-app-forge & discordium carry the tree. Further repos backfilled gradually via **`/chrysa-init`** + per-sprint **`docs/standard-doc-structure`** PRs.*
