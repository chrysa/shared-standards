# Actions manuelles restantes — portefeuille chrysa

> Dernière MAJ : 2026-04-20
> Scope interne (suivi personnel) : tout le portefeuille chrysa **hors padam** — **inclut travaux + aménagement Notion**.
> Scope externe (portfolio.html pour recruteurs/externes) : idem mais **filtre** travaux + aménagement (voir `generate-portfolio-html.sh --external`).
> Complément au script `fix-all.sh` qui couvre tout ce qui est scriptable.

---

## 1 · Décisions utilisateur en attente (5)

| ID  | Sujet                           | Question à trancher                                                                  | Impact si pas décidé                    |
| --- | ------------------------------- | ------------------------------------------------------------------------------------ | --------------------------------------- |
| D6  | Breakline · 3 études            | Merger en 1 repo unique, garder séparés, ou geler les 3 ?                            | 3 repos zombies dans le portefeuille    |
| D7  | Discordium V3 · audit stack     | Reprendre (stack TBD, Godot retiré ADR-0007) ou geler définitivement ?                | Vision floue sur roadmap jeu            |
| D8  | Shadow Mandate · scission       | Scinder en sous-projets ou garder monolithique ?                                     | Repo à 300+ issues non scoped           |
| D10 | Life Roguelike · déployer ?     | Passer Vision → Actif, ou rester Vision ?                                            | Règle 1+2 non violée mais backlog grossit |
| D11 | V5 Architecture · déployer ?    | Idem D10 (projet infra perso)                                                        | Idem                                    |

**Action** : bloquer 30 min avec soi-même (`/decide` par projet) et écrire la décision dans un ADR (`shared-standards/docs/adrs/ADR-00XX-...md`).

---

## 2 · Création de DB Notion (API limitation)

L'API Notion ne permet pas de créer une DB depuis zéro de manière fiable (les propriétés doivent être ajoutées manuellement après coup).

| DB à créer         | Emplacement                | Propriétés minimales                                              |
| ------------------ | -------------------------- | ----------------------------------------------------------------- |
| **Bugs**           | Workspace chrysa / Ops     | Nom, Projet (relation Projets), Severity, Statut, Repro, Assigné |
| **Dette technique**| Workspace chrysa / Ops     | Nom, Projet, Catégorie, Coût (XS/S/M/L/XL), Impact, Statut       |

**Action** : créer via UI Notion, puis récupérer `data_source_id` et l'ajouter au CLAUDE.md global.

---

## 3 · Infrastructure / secrets (Kimsufi + OVH)

| Action                                          | Outil                                        | Priorité |
| ----------------------------------------------- | -------------------------------------------- | -------- |
| Créer compte GitHub Pro (40 repos privés)       | github.com/settings/billing                  | P1       |
| Renouveler Kimsufi + DNS OVH (`*.chrysa.dev`)   | manager.ovh.com                              | P1       |
| Générer secrets prod : DB password, JWT, ...    | openssl rand + Vault ou `.env.prod` chiffré | P1       |
| Tailscale auth key pour nodes Kimsufi           | tailscale.com/admin                          | P2       |
| Cert Let's Encrypt via certbot sur Nginx        | SSH Kimsufi + `certbot --nginx`              | P2       |

---

## 4 · Monitoring stack (ADR-0019)

| Composant            | Rôle                                       | Installation                          |
| -------------------- | ------------------------------------------ | ------------------------------------- |
| Prometheus           | Metrics collector                          | docker-compose + prometheus.yml       |
| Grafana              | Dashboards (CPU, RAM, requêtes, etc.)      | docker-compose + datasources.yml      |
| Loki + Promtail      | Logs aggregation                           | docker-compose                        |
| Uptime Kuma          | Checks HTTP(S) uptime (déjà prévu)         | docker-compose                        |
| Sentry               | Error tracking (déjà prévu)                | sentry.io (SaaS ou self-hosted)       |

**Action** : ajouter un service `monitoring/` dans `chrysa/server` + runbook dans `shared-standards/docs/runbooks/monitoring.md`.

---

## 5 · GitHub — réglages non scriptables (plan Free)

| Réglage                                          | Où                                                 |
| ------------------------------------------------ | -------------------------------------------------- |
| Branch protection sur repos privés (HTTP 403)    | Passer au plan Pro OU rendre le repo public        |
| Rulesets (remplacent branch protection depuis '24)| github.com/chrysa/<repo>/settings/rules            |
| Secrets Actions (`NOTION_TOKEN`, `OVH_TOKEN`, …) | github.com/chrysa/<repo>/settings/secrets/actions  |
| Environments (dev/staging/prod) + reviewers      | github.com/chrysa/<repo>/settings/environments     |
| Dependabot alerts + security advisories          | UI uniquement pour les toggles                     |

---

## 6 · Revue `windows-autonome` + `agent-config` (ADR-0026)

Décision prise : **keep them separate, both Socle** (ADR-0026 révoque ADR-0014).

- [ ] Vérifier présence dans DB Projets Notion ; si absent, créer 2 entrées Socle
- [ ] Ajouter README.md à jour sur chaque repo (rôle + scope)
- [ ] Rédiger ADR-0027 (optionnel) si frontières entre les deux à clarifier

---

## 7 · Points récurrents à garder en tête

- **`gh auth login`** : expire tous les ~90 jours · penser à `gh auth refresh` mensuel
- **`pre-commit autoupdate`** : trimestriel sur tous les repos
- **Semver bump manuel interdit** : GitVersion s'en charge via tags `prd-*`
- **Règle 1+2** : max 1 Socle actif + 2 Actifs simultanés — à auditer à chaque sprint
- **Scheduled tasks à surveiller** : briefing-agent, ci-sweep, pr-aging, monthly-travel-expenses, notion-comments-processor

---

## Checklist rapide avant la prochaine session

```text
[ ] Trancher D6, D7, D8, D10, D11 (30 min)
[ ] Créer DB Bugs + Dette technique dans Notion (45 min · voir notion-restructure-plan.md)
[ ] Renouveler GitHub Pro si ajout >3 repos privés récents
[ ] Vérifier monitoring stack déployé sur Kimsufi
[ ] Audit règle 1+2 sur portefeuille (vu la semaine qui arrive)
[ ] Lancer bash fix-all.sh --dry-run puis fix-all.sh
[ ] Review + commit/push DECISIONS.md des 8 repos créés cette session
[ ] Éditer portfolio-metadata.yml pour les repos manquants
[ ] Appliquer le plan Notion (2h15 · voir notion-restructure-plan.md)
```

## Ajouts 2026-04-20 — uniformisation + restructuration

### Fichiers créés cette session à commit dans shared-standards

```text
templates/
  pre-commit/python.yaml
  pre-commit/node.yaml
  github-workflows/ci-python.yml
  github-workflows/ci-node.yml
  makefiles/Makefile.python
  makefiles/Makefile.node
  dockerfiles/Dockerfile.python
  dockerfiles/Dockerfile.node
  docs/README.template.md
  docs/CLAUDE.template.md
  docs/DECISIONS.template.md
  docs/ROADMAP.template.md
  docs/ARCHITECTURE.template.md
  docs/PRD.template.md
  GitVersion.yml
  gitignore.common
scripts/
  apply-standards.sh
  validate-prompt.py
  dev-run.sh
  generate-roadmap-rollup.sh
  generate-deps-graph.sh
  generate-docs-index.sh
  (+ patches sur fix-all.sh, archive-*.sh, repos-push-pending.sh, generate-portfolio-html.sh)
docs/
  DECISIONS-MIGRATION-MAP.md
  ideas-not-in-notion-2026-04-20.md
  notion-restructure-plan.md
  remaining-manual-actions.md (ce fichier)
portfolio-metadata.yml
DECISIONS.md (shared-standards scope)
```

Dans les 8 repos actifs :
```text
<repo>/DECISIONS.md  (ai-aggregator, chrysa-lib, dev-nexus, doc-gen, lifeos, my-fridge, satisfactory-automated_calculator, server)
```

### Actions manuelles exclusives (non couvertes par scripts)

1. **Notion · création DB Bugs** — `notion-restructure-plan.md` §3.P1.1
2. **Notion · création DB Dette technique** — `notion-restructure-plan.md` §3.P1.2
3. **Notion · 4 vues DB Projets** (Portfolio dev / Travaux / Aménagement / Gelés) — §3.P1.3
4. **Notion · migration pages ADRs → Archive** (rapatriement) — §3.P2.4
5. **Notion · pages Wiki Engineering** (Migration ADRs, Convention DECISIONS.md, LifeOS V2 visu Notion) — §3.P2.5-7
6. **Notion · audit et classification DB Projets** — §3.P3.8
7. **Gitignore global** : `echo '.claude/settings.local.json' >> ~/.gitignore_global && git config --global core.excludesfile ~/.gitignore_global`
8. **Décisions utilisateur** : D6 Breakline · D7 Discordium V3 · D8 Shadow Mandate · D10 Life Roguelike · D11 V5 Architecture
9. **Infrastructure** : GitHub Pro, renouvellement Kimsufi + OVH DNS, secrets prod, Tailscale keys, cert Let's Encrypt
10. **Monitoring stack** Prometheus + Grafana + Loki + Qdrant sur Kimsufi (~4 Go RAM)
