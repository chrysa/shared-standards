# CODE MANIFEST — chrysa portfolio

**Version 1.0 — 2026-04-28**
**Source de vérité unique** pour les standards transverses du portefeuille.
Complémente `EXECUTION_STANDARD.md` (procédural Makefile/CI) avec les standards architecturaux.

> Ce manifest est **applicable à tous les projets** chrysa. Toute dérogation nécessite un ADR (`<repo>/DECISIONS.md`).
> Le gate Ready-to-Dev (📦 Projets chrysa) vérifie sa conformité.

---

## 0. Principes directeurs

1. **Agnosticisme** — projets indépendants de la machine, de l'OS, du dev. Open-source ou vente possibles sans refactor.
2. **Single responsibility** — un container, une fonction, un service = une raison de changer.
3. **Reproductibilité** — `git clone && make install && make dev` doit suffire à démarrer en local.
4. **Observabilité par défaut** — logs structurés, metrics, healthchecks dès V1.
5. **Sécurité par défaut** — secrets externalisés, auth dès V1, pas de `--privileged`.

---

## 1. Repository structure

### 1.1 Repo de configuration consolidé : `claude-config`

Mono-repo **PUBLIC AGNOSTIQUE** consolidant :

```
claude-config/
├── workstation/          # Setup workstation (config OS, dotfiles, outils)
├── claude/               # Configuration agent Claude (settings, commands, hooks)
├── skills/               # Bibliothèque de skills réutilisables
├── multi-machine/        # Sync multi-machines (gist, listeners, snapshots)
├── secrets/              # Templates uniquement (.env.example, vault-config.example)
├── claude-config.env.example  # Personnalisation locale (gitignored: claude-config.env)
└── README.md             # Quickstart + contribution guide
```

**Règles absolues :**
- Aucune référence hardcodée à un utilisateur, une organisation ou une infrastructure privée.
- Personnalisation **uniquement** via `claude-config.env` (gitignored).
- Aucun secret réel — uniquement des templates `.example`.
- LICENSE explicite (MIT recommandé).

### 1.2 Conventions de nommage

| Type             | Convention                                                                  |
| ---------------- | --------------------------------------------------------------------------- |
| Repo apps        | `kebab-case` descriptif (`dev-nexus`, `fridge-ai`)                          |
| Repo libs        | Préfixe `lib-` ou suffixe `-lib` (`lib-auth`, `chrysa-lib`)                |
| Repo infra/tools | Préfixe explicite (`infra-`, `tools-`)                                     |
| Branches         | `feature/`, `fix/`, `chore/`, `hotfix/`, `release/`                        |
| Commits          | Conventional Commits (`feat:`, `fix:`, `chore:`, etc.)                      |

---

## 2. Containerization (OBLIGATOIRE)

### 2.1 Règles dures

- ✅ **Tout projet** livre un `Dockerfile` + `docker-compose.yml`
- ✅ **1 container = 1 responsabilité** (no multi-process, no app+db combinés)
- ✅ **Healthcheck obligatoire** dans chaque service Compose
- ✅ **Volumes nommés** pour data persistante (jamais bind-mount en prod)
- ✅ **Multi-service** → containers séparés (`app`, `db`, `cache`, `queue`, `worker`)
- ✅ **Non-root user** dans tous les containers applicatifs
- ✅ **Multi-stage build** pour les binaires (Python, Node, Go)
- ✅ **`.dockerignore` exhaustif** (au minimum : `.git`, `node_modules`, `__pycache__`, `.env*`, `*.log`)

### 2.2 Interdits absolus

- ❌ **Reverse proxy** dans le repo applicatif (responsabilité = repo `infra-server`)
- ❌ `supervisor` / `s6` / `runit` / `tini` pour multi-process — utiliser docker-compose
- ❌ Application + base de données dans le même container
- ❌ Hardcoded ports dans le Dockerfile — toujours via env vars + arg
- ❌ Image basée sur `:latest` — toujours pin version explicite ou digest
- ❌ Secrets en build args — utiliser BuildKit secrets ou runtime env

### 2.3 Image standards

| Aspect          | Standard                                                                  |
| --------------- | ------------------------------------------------------------------------- |
| Base image      | `python:3.14-slim`, `node:22-alpine`, `distroless` quand possible        |
| User            | UID/GID non-root, déclaré explicitement (`USER 1000:1000`)               |
| Layer caching   | Dependencies installées avant copie du code source                        |
| Healthcheck     | `HEALTHCHECK CMD curl -f http://localhost:PORT/health` ou équivalent     |
| Labels OCI      | `org.opencontainers.image.{source,version,licenses,title}` requis        |
| Scan sécurité   | Trivy en CI, blocage si CVE Critical                                      |

### 2.4 Compose patterns

```yaml
# docker-compose.yml — pattern minimal app+db
services:
  app:
    build: .
    env_file: .env
    depends_on:
      db:
        condition: service_healthy
    healthcheck: ...
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER"]
    restart: unless-stopped

volumes:
  db_data:
```

> **Reverse proxy** (Nginx, Traefik, Caddy) est exclusivement géré par le repo `infra-server`.
> Les apps exposent un port HTTP interne et déclarent leur nom de service Docker — le proxy fait le routing.

---

## 3. API standards

### 3.1 Versionnage (obligatoire dès V1)

- URL prefixée : `/api/v1/`, `/api/v2/`
- Header alternatif : `Accept: application/vnd.<project>.v1+json`
- Header `Deprecation` + `Sunset` sur les versions sortantes
- **Maximum 2 versions supportées simultanément**, deprecation cycle ≥ 6 mois

### 3.2 HATEOAS — pragmatique (REST level 3 modéré)

**Obligatoire sur les ressources principales**, pas sur tout :

```json
{
  "id": 42,
  "name": "...",
  "_links": {
    "self":    { "href": "/api/v1/missions/42" },
    "next":    { "href": "/api/v1/missions/43" },
    "vehicle": { "href": "/api/v1/vehicles/12" }
  }
}
```

**Format au choix par projet** (documenté en ADR projet) :
- HAL (`application/hal+json`) — recommandé pour API publiques
- JSON:API — recommandé si tooling existant
- Custom léger — si `_links` suffit

**Caveat** : ne pas générer un graphe complet à chaque réponse. Inclure les liens **utiles à la navigation client** (self, pagination, ressources liées directement consommées). Ne pas remplir `_links` avec toutes les actions possibles si le client ne les exploite pas.

### 3.3 OpenAPI / Swagger

- **Swagger UI** exposé en `/docs` — protégé par auth admin en prod
- **ReDoc** en `/redoc` — lecture seule, peut rester public
- **Schema source de vérité** : Pydantic v2 (FastAPI) ou DRF serializers (Django)
- Tous endpoints documentés : params, responses, errors, examples
- CI : `openapi-spec-validator` + détection breaking changes (`oasdiff`)
- **Visibilité conditionnelle** : le schéma OpenAPI généré doit refléter les permissions de l'utilisateur authentifié — les endpoints auxquels l'appelant n'a pas accès doivent être **omis** du schéma (ou marqués `x-hidden: true` si l'omission dynamique n'est pas supportée). Ne jamais exposer en clair des routes protégées à un utilisateur non authentifié ou sans la permission requise.

### 3.4 Permissions

- **RBAC ou ABAC** au choix par projet (documenté en ADR)
- Permissions par endpoint, pas par rôle hardcodé dans le code métier
- Décorateurs / middleware réutilisables : `@requires_permission("user:read")`
- **Audit log obligatoire** sur toutes les écritures sensibles (create/update/delete sur ressources métier)
- Documentation Swagger : chaque endpoint indique la permission requise

### 3.5 Erreurs

- Format **Problem Details for HTTP APIs** (RFC 7807) :
  ```json
  {
    "type": "https://docs.<project>/errors/validation",
    "title": "Validation Error",
    "status": 400,
    "detail": "Field 'email' is required",
    "instance": "/api/v1/users",
    "errors": [...]
  }
  ```
- Codes HTTP corrects (4xx client, 5xx serveur, 422 validation)
- Pas de stack trace en prod, jamais

### 3.6 Pagination & filtering

- Pagination obligatoire sur listes (`?page=1&size=20`, max size = 100)
- Filtrage standardisé (`?filter[status]=active&sort=-created_at`)
- Total count dans header `X-Total-Count` + liens `_links.{next,prev,first,last}`

### 3.7 Auth

- 4 modes supportés (Google OAuth2, local bcrypt, LDAP, VCS OAuth)
- JWT access + refresh token rotatif
- Rate limiting par tenant + par IP (Redis)
- CORS strict — whitelist explicite par environnement

---

## 4. Setup wizard & configuration panel

> **Scope** : applicable aux **apps web/services déployables**.
> Non applicable aux libs pures, CLI agents, ou utilities.

### 4.1 Setup wizard (première exécution)

- Assistant interactif (CLI ou web) au premier démarrage
- Couvre : DB connection, admin user, intégrations tiers, secrets, locale
- **Idempotent** — rejouable sans casse
- Détection prérequis manquants avec messages explicites + suggestion fix
- Skip mode pour CI : `make setup-ci` ou env `SETUP_NON_INTERACTIVE=1`

### 4.2 Configuration panel (UI admin)

- UI admin pour configuration courante (toggles, intégrations, limits, feature flags)
- API REST CRUD (auth admin requise)
- **Versionnée** — audit trail des changements (qui, quand, valeur avant/après)
- **Hot-reload** quand techniquement possible, sinon flag `RESTART_REQUIRED` exposé
- Export / import JSON pour backup et clonage entre environnements

### 4.3 Secrets management

- `.env.example` exhaustif et commenté
- **Jamais de secret en dur** dans le code (CI bloque via `detect-secrets`)
- Support 12-factor par défaut, intégration optionnelle Doppler / Vault / AWS SM
- Pre-commit hook `detect-secrets` obligatoire

---

## 5. Machine & path agnosticism

### 5.1 Règles

- ❌ Aucun path absolu hardcodé (`/home/user/...`, `C:\Users\...`, IPs, hostnames internes)
- ✅ Tous paths via abstraction : `pathlib.Path` (Python), `path.join` (Node), `filepath.Join` (Go)
- ✅ Variables d'env pour paths configurables (`APP_DATA_DIR`, `APP_CACHE_DIR`)
- ✅ Détection runtime de l'OS pour séparateurs, encodings, line endings

### 5.2 Portabilité multi-OS

Le projet doit tourner identiquement sur :
- **Linux** (dev + prod)
- **macOS** (dev)
- **Windows WSL2** (dev)

CI matrix : tests sur 3 OS minimum pour les libs publiques. Pour les apps, Linux suffit en CI mais le `make dev` doit fonctionner sur les 3.

### 5.3 Open-source / vente

- LICENSE explicite (MIT par défaut sauf ADR contraire)
- README usable par un dev externe sans contexte interne (5 min to first run)
- Aucune référence à infrastructure privée (Tailscale, IPs, hostnames spécifiques)
- Documentation déploiement complète (Docker Compose + variables d'env documentées)
- `CONTRIBUTING.md` + `CODE_OF_CONDUCT.md` si projet ouvert aux contributions

---

## 6. Code quality

### 6.1 Linting & types (0 warning bloquant en CI)

| Stack         | Linter      | Type checker | Formatter   |
| ------------- | ----------- | ------------ | ----------- |
| Python        | ruff        | mypy strict  | ruff format |
| TypeScript    | ESLint      | tsc strict   | prettier    |
| Go            | golangci-lint | (intégré)  | gofmt       |
| Shell         | shellcheck  | —            | shfmt       |

### 6.2 Limites de taille

| Métrique                     | Python | TS  | Go  |
| ---------------------------- | ------ | --- | --- |
| Lignes par fonction          | 40     | 50  | 60  |
| Lignes par fichier           | 300    | 500 | 500 |
| Arguments par fonction       | 5      | 4   | 5   |
| Complexité cyclomatique      | 10     | 10  | 10  |
| Niveaux d'imports indirects  | 3      | 3   | 3   |

### 6.3 Nested functions interdites (cross-repo)

- ❌ Fonctions imbriquées nommées > 5 lignes
- ✅ Lambdas / arrows inline (callbacks `map`/`filter`/predicates 1-3 lignes)
- ✅ Closure factory si privée + 1 site d'appel
- Enforcement : `ESLint max-nested-callbacks=2` · Ruff `PLR0915` + custom def-in-def

### 6.4 Tests

- Coverage minimum **≥ 85 %** (≥ 80 % pour frontend SPA)
- Au moins **1 test négatif** par endpoint API
- Mock DB en unit (sauf `@pytest.mark.integration`)
- Tests parallèles obligatoires si runtime > 30s
- Snapshot tests pour les composants UI critiques

---

## 7. Documentation (obligatoire par repo)

| Fichier            | Contenu                                                  | Obligatoire |
| ------------------ | -------------------------------------------------------- | ----------- |
| `README.md`        | Quickstart 5 min max, badges CI, lien doc complète       | ✅          |
| `CLAUDE.md`        | Contexte agent (stack, conventions, rules, model tag)    | ✅          |
| `DECISIONS.md`     | ADR projet (D-XXXX local, format mini)                   | ✅          |
| `CHANGELOG.md`     | Format Keep a Changelog                                   | ✅          |
| `LICENSE`          | Texte de licence intégral                                 | ✅          |
| `CONTRIBUTING.md`  | Setup dev, conventions, process PR                       | si public   |
| `docs/`            | Architecture, API, deployment, runbooks                  | si app      |

### Generated docs

- Swagger / ReDoc (API) — exposés en runtime
- TypeDoc / Sphinx (libs publiques) — publiés sur GitHub Pages
- ADR rendered HTML (optionnel, via `adr-tools` ou `log4brains`)

---

## 8. CI/CD

### 8.1 Workflows obligatoires (templates dans `shared-standards/templates`)

- `quality-checks.yml` — lint + type + test + coverage
- `security.yml` — `detect-secrets` + Trivy + bandit/audit
- `build-image.yml` — Docker build + scan + push registry
- `release.yml` — GitVersion + CHANGELOG + GitHub Release
- `enforce-issue-link.yml` — toute PR doit référencer une issue (status check bloquant)

### 8.2 Quality gates

- SonarCloud rating **A** obligatoire
- **0 hotspot security** non-traité
- Coverage ≥ seuil projet (default 85%)
- All actions **pinned by SHA256**
- GitVersion semantic auto — jamais de bump manuel

### 8.3 Branch protection

- `main` / `develop` protégées
- Reviews requises (minimum 1, 2 pour libs publiques)
- Status checks obligatoires : CI + SonarCloud + enforce-issue-link
- Squash merge **uniquement**, push force interdit

---

## 9. Observability

### 9.1 Logs

- **Structured (JSON)** en production
- Levels : `DEBUG`, `INFO`, `WARN`, `ERROR`
- **Correlation ID** (request ID) propagé sur toute la stack
- Pas de PII en clair (masquer email, tokens, etc.)
- Centralisation : Loki (self-hosted) ou stdout en local

### 9.2 Metrics (Prometheus format)

- Endpoint `/metrics` exposé (auth admin en prod)
- **4 golden signals** : latency, traffic, errors, saturation
- Custom metrics business par projet (events count, revenue, etc.)

### 9.3 Tracing (OpenTelemetry)

- Spans automatiques sur DB queries, external calls, async tasks
- Propagation `traceparent` header
- Backend : Jaeger / Tempo (self-hosted)

### 9.4 Alerting

- **Sentry** : erreurs applicatives + performance
- **Uptime Kuma** : healthchecks endpoints publics
- Alertes routées (email, Discord) **sur critique seulement** (no alert fatigue)

---

## 10. Internationalization (FR + EN dès V1)

- Backend : `fastapi-babel`, `django-i18n`
- Frontend : `react-i18next`
- **Toutes les strings user-facing** extraites (CI grep + lint plugin)
- Fallback **EN** obligatoire
- Tests : 1 langue testée par CI run (rotation)
- Détection auto via `Accept-Language` header

---

## 11. Accessibility (WCAG 2.1 AA)

- **Dark mode** obligatoire dès V1
- Lighthouse a11y score **≥ 90**
- Keyboard navigation complète (Tab, Esc, focus visible)
- Screen reader testé sur les flows critiques (signup, login, checkout)
- Contraste 4.5:1 minimum sur texte (3:1 sur large text)

---

## 12. Versioning & releases

- **GitVersion** (semantic auto)
- **Conventional Commits** enforced via `commitlint`
- Tags : `v.X.Y.Z` ou `prd-X.Y.Z` selon repo (documenté en `CLAUDE.md` repo)
- Release notes auto-générées depuis CHANGELOG
- Pre-release : `-alpha.N`, `-beta.N`, `-rc.N`

---

## 13. Compliance check — Gate Ready-to-Dev

Un projet est **Ready-to-Dev** quand les 10 critères suivants sont validés :

```
[ ] 1.  Repo créé via `project-init` CLI (shared-standards)
[ ] 2.  Dockerfile + docker-compose.yml + healthchecks présents
[ ] 3.  Setup wizard accessible (CLI ou web) — si app déployable
[ ] 4.  Config panel admin — si app déployable
[ ] 5.  API versionnée + Swagger + permissions documentées — si API
[ ] 6.  Aucun path/IP/hostname hardcodé (CI grep)
[ ] 7.  README + CLAUDE.md + DECISIONS.md + LICENSE + CHANGELOG initialisés
[ ] 8.  CI workflows shared-standards installés et verts
[ ] 9.  pre-commit configuré (detect-secrets + ruff/eslint + commitlint)
[ ] 10. i18n FR+EN + dark mode + a11y baseline configurés
```

Le gate est tracé dans la propriété `Ready to Dev Gate ✓` de la database `📦 Projets chrysa` (Notion).

---

## 14. Évolution du manifest

- Les modifications passent par PR sur `shared-standards`
- Toute modification crée un nouvel ADR (`D-XXXX` dans `shared-standards/DECISIONS.md`)
- Communication aux repos consommateurs via tag de release (`manifest-vX.Y`)
- Migration des projets existants : ADR par projet documentant l'écart et le plan de mise en conformité

---

**Références**
- ADR-0027 — Consolidation `claude-config` (2026-04-28)
- ADR-0028 — Code manifest + standards transverses (2026-04-28)
- `EXECUTION_STANDARD.md` — Conventions Makefile + structure
- `AGENTS.md` — Standards spécifiques aux agents IA
- Notion `📘 DECISIONS` — Source de vérité ADR cross-repo
