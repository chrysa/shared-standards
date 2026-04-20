# ROADMAP ROLLUP — chrysa

> Généré 2026-04-20 21:42 par generate-roadmap-rollup.sh
> Aggrégation des ROADMAP.md + DECISIONS.md des repos actifs

---

## Sommaire

- [ai-aggregator](#ai-aggregator)
- [chrysa-lib](#chrysa-lib)
- [coach](#coach)
- [container-webview](#container-webview)
- [D-D](#D-D)
- [dev-nexus](#dev-nexus)
- [discord-bot-back](#discord-bot-back)
- [diy-stream-deck](#diy-stream-deck)
- [doc-gen](#doc-gen)
- [epub-sorter](#epub-sorter)
- [genealogy-validator](#genealogy-validator)
- [github-actions](#github-actions)
- [guideline-checker](#guideline-checker)
- [lifeos](#lifeos)
- [my-fridge](#my-fridge)
- [notion-automation](#notion-automation)
- [PO-GO-DEX](#PO-GO-DEX)
- [pre-commit-tools](#pre-commit-tools)
- [project-init](#project-init)
- [pycharm_settings](#pycharm_settings)
- [satisfactory-automated_calculator](#satisfactory-automated_calculator)
- [server](#server)
- [shared-standards](#shared-standards)
- [usefull-containers](#usefull-containers)
- [windows-docker-state-notification](#windows-docker-state-notification)

---

## ai-aggregator

*Dernière activité : il y a 2 minutes · branche : chore/quality-uniformization*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

---

## NOW (sprint actuel)

| Item | Issue | Priorité | Effort | Statut |
| ---- | ----- | -------- | ------ | ------ |
| {{item}} | #{{n}} | P0/P1 | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
| | | | |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

---

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
| | | |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

---

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)

## D-0001 — prompt-optimizer = module interne (pas repo standalone)
**Date** : 2026-04-18 (ex-ADR-0018)
**État** : ACTIF
**Date** : YYYY-MM-DD
**État** : ACTIF

---

## chrysa-lib

*Dernière activité : il y a 2 jours · branche : chore/claude-hooks-refactor*

### Roadmap


> **Rôle** : Socle (bloque 4+ projets aval · règle 1+2)
> Dernière revue : 2026-04-20

---

## NOW (sprint 1 — @chrysa/auth)

| Item                          | Priorité | Effort | Statut         |
| ----------------------------- | -------- | ------ | -------------- |
| Module `@chrysa/auth` 4 modes | P0       | L      | NOT_STARTED 🔴 |
| Tests unitaires ≥ 85%         | P0       | M      | NOT_STARTED    |
| Doc API + README              | P0       | S      | NOT_STARTED    |

## NEXT (sprint 2)

| Item                     | Prérequis    | Effort |
| ------------------------ | ------------ | ------ |
| Module `@chrysa/config`  | auth livré   | M      |
| Module `@chrysa/logging` | config livré | M      |

## LATER

- [ ] `@chrysa/errors` (patterns withErrorHandling)
- [ ] `@chrysa/i18n` (wrapper react-i18next + fastapi-babel)

## Dépendances aval (projets qui attendent)

- `dev-nexus` — auth obligatoire pour cockpit V1
- `my-fridge` — auth obligatoire PWA
- `lifeos` — auth obligatoire pour agents
- `doc-gen` — auth pour génération multi-tenant
- `ai-aggregator` (indirect) — via dev-nexus
- `server` (indirect) — déploiement aval

## Bloqueurs actuels

| Bloqueur             | Impact             | Action                 |
| -------------------- | ------------------ | ---------------------- |
| Sprint 1 pas démarré | Cascade 4+ projets | Démarrer immédiatement |

## Cross-project issues

- X-1 : bloque `dev-nexus`, `my-fridge`, `lifeos`, `doc-gen` → issues à créer via `generate-cross-project-issues.sh`

## Revues

- Prochaine revue : fin Sprint 1 (à planifier)

### Décisions (extrait)

## D-0001 — Auth 4 modes (Google OAuth2 · local bcrypt · LDAP · VCS OAuth)
**Date** : 2026-04-01 (ex-ADR-0004)
**État** : ACTIF
## D-0002 — chrysa-lib = Socle bloquant (portfolio-wide)
**Date** : 2026-04-01 (ex-ADR-0002, transverse mais ancré ici)
**État** : ACTIF
**Date** : YYYY-MM-DD
**État** : ACTIF | SUPERSEDED par D-XXXX | RETIRED

---

## coach

*Dernière activité : il y a 12 minutes · branche : chore/quality-uniformization*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

---

## NOW (sprint actuel)

| Item | Issue | Priorité | Effort | Statut |
| ---- | ----- | -------- | ------ | ------ |
| {{item}} | #{{n}} | P0/P1 | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
| | | | |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

---

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
| | | |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

---

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)


---

## container-webview

*Dernière activité : il y a 2 jours · branche : fix/frontend-build*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

---

## NOW (sprint actuel)

| Item | Issue | Priorité | Effort | Statut |
| ---- | ----- | -------- | ------ | ------ |
| {{item}} | #{{n}} | P0/P1 | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
| | | | |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

---

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
| | | |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

---

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)


---

## D-D

*Dernière activité : il y a 3 jours · branche : chore/quality-uniformization*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

______________________________________________________________________

## NOW (sprint actuel)

| Item     | Issue  | Priorité | Effort   | Statut      |
| -------- | ------ | -------- | -------- | ----------- |
| {{item}} | #{{n}} | P0/P1    | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
|      |           |        |        |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

______________________________________________________________________

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
|          |        |                 |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

______________________________________________________________________

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)


---

## dev-nexus

*Dernière activité : il y a 9 jours · branche : feature/integrate-live-platform-v2*

### Roadmap


> **Rôle** : Actif · Statut V1
> Dernière revue : 2026-04-20

---

## NOW (post-chrysa-lib)

| Item                        | Priorité | Effort | Statut             |
| --------------------------- | -------- | ------ | ------------------ |
| Intégration @chrysa/auth    | P0       | M      | BLOCKED par X-1 🔴 |
| Cockpit GitHub + SonarCloud | P1       | L      | DESIGN             |
| AI prioritization NL→ticket | P1       | L      | DESIGN             |

## NEXT (V1.x)

| Item                         | Prérequis                | Effort |
| ---------------------------- | ------------------------ | ------ |
| Intégration prompt-optimizer | X-3 ai-aggregator        | S      |
| Dashboard uptime             | server monitoring D-0001 | M      |

## OUT V1 (explicitement exclu)

- Orchestration multi-agents (V2+)
- Email/chat integration (V2+)
- App mobile (V2+)
- Monitoring infra deep (réservé à server)

## Dépendances amont

- `chrysa-lib` / `@chrysa/auth` — bloquant (X-1)
- `ai-aggregator` / `prompt-optimizer` — pour rate-limit tokens (X-3)
- GitHub MCP — configuration à faire

## Bloqueurs actuels

| Bloqueur                 | Impact            | Action                          |
| ------------------------ | ----------------- | ------------------------------- |
| chrysa-lib/auth          | V1 non démarrable | Attendre X-1                    |
| GitHub MCP non configuré | Cockpit limité    | Configurer MCP                  |
| Rate limit Claude API    | Coût élevé        | Attendre prompt-optimizer (X-3) |

## Cross-project issues

- X-1 : bloqué par chrysa-lib Sprint 1
- X-3 : attend prompt-optimizer (ai-aggregator)

## Décisions clés

- D-0001 : V1 inclut AI prioritization (NL→ticket) (ex-ADR-0006)

### Décisions (extrait)

## D-0001 — V1 inclut AI prioritization (NL → ticket)
**Date** : 2026-04-01 (ex-ADR-0006)
**État** : ACTIF
**Date** : YYYY-MM-DD
**État** : ACTIF

---

## discord-bot-back

*Dernière activité : il y a 3 jours · branche : chore/quality-uniformization*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

---

## NOW (sprint actuel)

| Item | Issue | Priorité | Effort | Statut |
| ---- | ----- | -------- | ------ | ------ |
| {{item}} | #{{n}} | P0/P1 | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
| | | | |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

---

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
| | | |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

---

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)


---

## diy-stream-deck

*Dernière activité : il y a 3 jours · branche : chore/quality-uniformization*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

---

## NOW (sprint actuel)

| Item | Issue | Priorité | Effort | Statut |
| ---- | ----- | -------- | ------ | ------ |
| {{item}} | #{{n}} | P0/P1 | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
| | | | |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

---

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
| | | |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

---

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)


---

## doc-gen

*Dernière activité : il y a 3 jours · branche : chore/quality-uniformization*

### Roadmap


> **Rôle** : Actif · Statut V1
> Dernière revue : 2026-04-20

---

## 🔴 ALERTE BLOQUANTE

**PR #1 `python-jose → joserfc`** overdue. À résoudre AVANT toute autre action sur ce repo.

## NOW

| Item | Priorité | Effort | Statut |
| ---- | -------- | ------ | ------ |
| Merger PR #1 | P0 | S | OPEN 🔴 |
| Tester avec joserfc | P0 | S | - |

## NEXT

| Item | Prérequis | Effort |
| ---- | --------- | ------ |
| Intégration chrysa-lib/auth | X-1 | M |
| Sphinx theme chrysa unifié | - | M |
| Pipeline MkDocs multi-repo | - | L |

## LATER

- [ ] Auto-génération docs API depuis OpenAPI
- [ ] Intégration SonarCloud findings en annotations doc

## Dépendances amont (bloquent doc-gen)

- `chrysa-lib` — auth obligatoire (X-1)

## Dépendances aval

- Tous les projets chrysa (consumers de la pipeline doc)

## Bloqueurs actuels

| Bloqueur | Impact | Action |
| -------- | ------ | ------ |
| PR #1 python-jose | Bloque Actif complet | Résoudre AVANT tout |
| chrysa-lib/auth non livré | Retarde V1.5 | Attendre X-1 |

## Cross-project issues

- X-2 : PR #1 migration (issue à créer via `generate-cross-project-issues.sh`)
- X-1 : bloqué par chrysa-lib

## Décisions clés

- D-0001 : doc-gen séparé de CodeDoc AI (ex-ADR-0024, révise ADR-0015)

### Décisions (extrait)

## D-0001 — doc-gen séparé de CodeDoc AI (révise ex-ADR-0015)
**Date** : 2026-04-19 (ex-ADR-0024)
**État** : ACTIF
**Date** : YYYY-MM-DD
**État** : ACTIF

---

## epub-sorter

*Dernière activité : il y a 79 secondes · branche : chore/quality-uniformization*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

---

## NOW (sprint actuel)

| Item | Issue | Priorité | Effort | Statut |
| ---- | ----- | -------- | ------ | ------ |
| {{item}} | #{{n}} | P0/P1 | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
| | | | |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

---

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
| | | |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

---

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)


---

## genealogy-validator

*Dernière activité : il y a 3 jours · branche : chore/quality-uniformization*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

---

## NOW (sprint actuel)

| Item | Issue | Priorité | Effort | Statut |
| ---- | ----- | -------- | ------ | ------ |
| {{item}} | #{{n}} | P0/P1 | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
| | | | |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

---

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
| | | |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

---

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)


---

## github-actions

*Dernière activité : il y a 12 minutes · branche : chore/quality-uniformization*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

---

## NOW (sprint actuel)

| Item | Issue | Priorité | Effort | Statut |
| ---- | ----- | -------- | ------ | ------ |
| {{item}} | #{{n}} | P0/P1 | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
| | | | |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

---

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
| | | |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

---

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)


---

## guideline-checker

*Dernière activité : il y a 11 minutes · branche : chore/quality-uniformization*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

---

## NOW (sprint actuel)

| Item | Issue | Priorité | Effort | Statut |
| ---- | ----- | -------- | ------ | ------ |
| {{item}} | #{{n}} | P0/P1 | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
| | | | |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

---

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
| | | |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

---

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)


---

## lifeos

*Dernière activité : il y a 3 jours · branche : chore/quality-uniformization*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

---

## NOW (sprint actuel)

| Item | Issue | Priorité | Effort | Statut |
| ---- | ----- | -------- | ------ | ------ |
| {{item}} | #{{n}} | P0/P1 | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
| | | | |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

---

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
| | | |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

---

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)

## D-0001 — LifeOS = my-assistant (même repo, pas de split)
**Date** : 2026-04-01 (ex-ADR-0005)
**État** : ACTIF
## D-0002 — Architecture Hybrid Notion + LifeOS
**Date** : 2026-04-02 (ex-ADR-0008)
**État** : ACTIF
## D-0003 — Visualisation Notion plus ergonomique (avec découplage possible à terme)
**Date** : 2026-04-20
**État** : ACTIF
**Date** : YYYY-MM-DD
**État** : ACTIF

---

## my-fridge

*Dernière activité : il y a 2 jours · branche : master*

### Roadmap


> **Rôle** : Actif · Statut V0
> Dernière revue : 2026-04-20

---

## NOW (preparation V1)

| Item | Priorité | Effort | Statut |
| ---- | -------- | ------ | ------ |
| Modèle de données allergènes | P0 | M | DESIGN |
| Choix source nutrition (TheMealDB) | P1 | S | DONE |
| Intégration @chrysa/auth | P0 | M | BLOCKED par X-1 🔴 |

## NEXT (V1 MVP)

| Item | Prérequis | Effort |
| ---- | --------- | ------ |
| PWA scaffold (React 19 + Vite 6) | auth livré | L |
| Stockage inventory offline-first | scaffold | M |
| Moteur allergies conformité | modèle validé | M |
| i18n FR + EN | - | S |
| Dark mode | - | S |

## LATER

- [ ] Mode multi-foyer
- [ ] Courses automatiques (liaison stock LifeOS)
- [ ] Scan code-barre

## Dépendances amont

- `chrysa-lib` / `@chrysa/auth` — bloquant (X-1)
- `lifeos` (indirect) — pour intégration StocksAgent

## Bloqueurs actuels

| Bloqueur | Impact | Action |
| -------- | ------ | ------ |
| chrysa-lib/auth | V1 non démarrable | X-1 |
| Modèle allergènes V1 à arrêter | Scope flou | Décision user |

## Cross-project issues

- X-1 : bloqué par chrysa-lib

## Décisions clés

Aucune formalisée à ce jour (voir DECISIONS.md vide).

## Budget

- Infra annuelle : ~20 € (hosting)
- Effort estimé V1 : ~120 h solo dev

### Décisions (extrait)

**Date** : YYYY-MM-DD
**État** : ACTIF

---

## notion-automation

*Dernière activité : il y a 3 jours · branche : chore/quality-uniformization*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

---

## NOW (sprint actuel)

| Item | Issue | Priorité | Effort | Statut |
| ---- | ----- | -------- | ------ | ------ |
| {{item}} | #{{n}} | P0/P1 | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
| | | | |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

---

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
| | | |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

---

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)


---

## PO-GO-DEX

*Dernière activité : il y a 3 jours · branche : chore/quality-uniformization*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

______________________________________________________________________

## NOW (sprint actuel)

| Item     | Issue  | Priorité | Effort   | Statut      |
| -------- | ------ | -------- | -------- | ----------- |
| {{item}} | #{{n}} | P0/P1    | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
|      |           |        |        |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

______________________________________________________________________

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
|          |        |                 |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

______________________________________________________________________

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)


---

## pre-commit-tools

*Dernière activité : il y a 5 heures · branche : chore/chrysa-cowork-20260419*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

---

## NOW (sprint actuel)

| Item | Issue | Priorité | Effort | Statut |
| ---- | ----- | -------- | ------ | ------ |
| {{item}} | #{{n}} | P0/P1 | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
| | | | |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

---

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
| | | |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

---

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)


---

## project-init

*Dernière activité : il y a 2 jours · branche : main*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

---

## NOW (sprint actuel)

| Item | Issue | Priorité | Effort | Statut |
| ---- | ----- | -------- | ------ | ------ |
| {{item}} | #{{n}} | P0/P1 | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
| | | | |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

---

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
| | | |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

---

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)


---

## pycharm_settings

*Dernière activité : il y a 11 minutes · branche : chore/quality-uniformization*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

---

## NOW (sprint actuel)

| Item | Issue | Priorité | Effort | Statut |
| ---- | ----- | -------- | ------ | ------ |
| {{item}} | #{{n}} | P0/P1 | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
| | | | |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

---

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
| | | |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

---

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)


---

## satisfactory-automated_calculator

*Dernière activité : il y a 3 jours · branche : chore/quality-uniformization*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

---

## NOW (sprint actuel)

| Item | Issue | Priorité | Effort | Statut |
| ---- | ----- | -------- | ------ | ------ |
| {{item}} | #{{n}} | P0/P1 | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
| | | | |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

---

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
| | | |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

---

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)

## D-0001 — SAT multi-jeu = Opportuniste (pas Actif)
**Date** : 2026-04-18 (ex-ADR-0017)
**État** : ACTIF
**Date** : YYYY-MM-DD
**État** : ACTIF

---

## server

*Dernière activité : il y a 6 heures · branche : chore/post-industrialization-cleanup*

### Roadmap


> **Rôle** : Socle · **Priorité P0** (Couche 1 plateforme, bloque tout le reste)
> Dernière revue : 2026-04-20

---

## 🚨 Phase 0 (NOW) — Stabilisation plateforme

Doit être terminée **avant** toute reprise de développement applicatif (chrysa-lib Sprint 1 et au-delà).

| Item | Priorité | Effort | Statut |
| ---- | -------- | ------ | ------ |
| Audit Kimsufi (disque, RAM, uptime) | P0 | S | TODO |
| Renouvellement Kimsufi + DNS OVH (`*.chrysa.dev`) | P0 | S | TODO |
| Let's Encrypt : vérifier/renouveler tous les certs | P0 | S | TODO |
| Tailscale mesh : auth keys régénérées + tous nodes UP | P0 | S | TODO |
| Backup DB quotidien (postgres + redis snapshots) | P0 | M | TODO |
| Sentry self-hosted opérationnel | P0 | M | TODO |
| Stack monitoring (Prometheus + Grafana + Loki + Qdrant) | P0 | L | TODO — D-0001 |
| Runbook `docs/runbooks/server-operations.md` | P0 | S | TODO |

## NEXT — Phase 1 écosystème dev (Couche 2)

Débloque une fois Phase 0 close.

| Item | Prérequis | Effort |
|------|-----------|--------|
| Rotation secrets via Vault ou équivalent | Phase 0 | M |
| Migration k3s (documentation avant) | monitoring stable | L |
| GitHub Actions runner self-hosted | Phase 0 | M |

## LATER — Phase 2+

- [ ] CDN/edge pour assets frontend (Edgee.ai à évaluer)
- [ ] Scan vulnérabilités automatisé (trivy + grype)
- [ ] DR test annuel (restore backup)

## Bloqueurs actuels

| Bloqueur | Impact | Action |
|----------|--------|--------|
| Stack monitoring pas déployée | Projets aval sans observabilité | D-0001 |
| Backup pas automatisé | Risque de perte de données | Phase 0 |

## Dépendances aval (tout attend ça)

- chrysa-lib · doc-gen · dev-nexus · my-fridge · lifeos · ai-aggregator
- Tous les projets déployés en prod

## Cross-project issues

- X-4 : bloque tous les projets déployés → voir shared-standards/docs/cross-project-dependencies.md

## Décisions clés

- D-0001 : Stack monitoring local-first Prometheus + Grafana + Loki + Qdrant

## Budget

- Infra annuelle : ~180 € (Kimsufi + DNS OVH)

### Décisions (extrait)

## D-0001 — Stack monitoring local-first
**Date** : 2026-04-18 (ex-ADR-0019)
**État** : ACTIF
**Date** : YYYY-MM-DD
**État** : ACTIF

---

## shared-standards

*Dernière activité : il y a 50 secondes · branche : chore/claude-code-optimization*

### Décisions (extrait)

## D-0005 — détail
**Date** : YYYY-MM-DD
**État** : ACTIF

---

## usefull-containers

*Dernière activité : il y a 7 heures · branche : develop*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

---

## NOW (sprint actuel)

| Item | Issue | Priorité | Effort | Statut |
| ---- | ----- | -------- | ------ | ------ |
| {{item}} | #{{n}} | P0/P1 | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
| | | | |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

---

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
| | | |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

---

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)


---

## windows-docker-state-notification

*Dernière activité : il y a 2 jours · branche : chore/quality-uniformization*

### Roadmap


> Format Now / Next / Later — à mettre à jour à chaque sprint (10h environ).
> Source de vérité priorités : CLAUDE.md global règle 1+2 (max 1 Socle + 2 Actifs).

---

## NOW (sprint actuel)

| Item | Issue | Priorité | Effort | Statut |
| ---- | ----- | -------- | ------ | ------ |
| {{item}} | #{{n}} | P0/P1 | XS/S/M/L | IN_PROGRESS |

## NEXT (sprint +1, priorisés)

| Item | Prérequis | Effort | Valeur |
| ---- | --------- | ------ | ------ |
| | | | |

## LATER (backlog priorisé, pas encore scopé)

- [ ] {{idée}}
- [ ] {{idée}}

## OUT (pas avant V2 / jamais sans nouvelle décision)

- {{item exclu + raison}}

---

## Phases produit

- [ ] V0 — prototype interne
- [ ] V1 — MVP utilisable
- [ ] V1.x — stabilisation
- [ ] V2 — évolutions majeures

## Bloqueurs actuels

| Bloqueur | Impact | Action attendue |
| -------- | ------ | --------------- |
| | | |

## Dépendances amont

- {{autre_repo}} — raison

## Dépendances aval (repos qui attendent celui-ci)

- {{autre_repo}} — ce que ça débloque

---

## Revues

- Dernière revue : YYYY-MM-DD
- Prochaine revue : YYYY-MM-DD (fin sprint)

### Décisions (extrait)


---


## Règle 1+2 — statut actuel

Max 1 Socle actif + 2 Actifs simultanés.

Voir portfolio-metadata.yml pour le rôle officiel de chaque projet.
