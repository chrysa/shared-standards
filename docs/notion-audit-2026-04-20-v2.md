# Audit Notion v2 (post-session 2026-04-20) — manques + restructuration

> Mise à jour de `notion-restructure-plan.md` + `divergences-2026-04-20.md`.
> Inclut les éléments produits dans la session d'uniformisation padam-av.

---

## 1 · Manques identifiés (non présents dans Notion, produits cette session)

### Contenu technique
- **Template palette labels + couleurs** (`shared-standards/templates/labels.yml`) — palette unifiée 60+ labels, aucune référence Notion
- **Workflows GitHub** : `sync-labels.yml`, `labeler.yml`, `pr-size-label.yml`, `dependabot-auto-merge.yml`, `branch-auto-update.yml`, `enforce-issue-link.yml`, `_reusable-ci.yml`
- **`.claude/` hooks** : `config.json`, `settings.json`, `quality-check.sh`, `thresholds.md`, `secret-scanner-allowlist.json`
- **Scripts shared-standards** : `audit-github-issues.sh`, `cleanup-session-artifacts.sh`, `chrysa-init.sh`, `generate-cross-project-issues.sh`, `_lib.sh`
- **Pre-commit enrichi** (actionlint, hadolint, codespell, interrogate, markdownlint, bashate)

### Conventions + méthodologie
- **CONVENTIONS.md** source unique de vérité (conventions transverses)
- **FRAMEWORK-chrysa.md** pyramide 4 couches + repriorisation server P0
- **Règle "issue ↔ PR obligatoire"** formalisée (enforce-issue-link + PR template)
- **Pattern dédup bash via `_lib.sh`** (helpers communs)
- **CI réutilisable `_reusable-ci.yml`** (mutualisation python+node)

### Projets / idées
- **D-0003 lifeos** : visu Notion ergonomique + découplage V2 PostgreSQL
- **FabForge GDD** : non recensé dans `portfolio-metadata.yml`
- **DEV Nexus V2 (SaaS AI Extension)** : page Notion existe, pas dans metadata

### Veille
- **9 sources veille catégorisées** (dev, domotique, jeux, automatisation)
- **Pattern "propose-more-sources"** à chaque run veille

---

## 2 · Restructuration Notion cible (améliorée)

### Architecture "Home-first" (accès en 1 clic)

```
🏠 Home (landing chrysa)
├── 🎯 Aujourd'hui — widgets (DB Tâches filtré · briefing du jour · alertes CI)
├── 🚀 Portfolio actif — vue DB Projets (Actifs + Socle uniquement)
├── 🗺️ Roadmaps rapides — liens directs Roadmaps par écosystème
├── 📊 Santé système — CI status · budget GH · conso tokens Claude
└── 🔎 Chercher — raccourcis recherche sauvegardée

📚 Wiki (référence stable)
├── CONVENTIONS (git, code, portefeuille, décisions)
├── Framework 4 couches + règle 1+2
├── Hooks locaux (validate-prompt · dev-run · chrysa-init)
├── Migration ADRs → DECISIONS.md par repo
├── Patterns XDA actionnables
└── Secrets management procedure

📋 Databases (données structurées)
├── Projets (vue principale + 4 vues filtrées)
│   ├── Portfolio dev (hors Gelés)
│   ├── Travaux maison
│   ├── Aménagement Notion
│   └── Gelés + Archive
├── Tâches
├── 🆕 Bugs (Nom · Projet→rel · Severity · Statut · Repro)
├── 🆕 Dette technique (Nom · Projet · Catégorie · Coût · Impact)
├── 🆕 Veille tech (Titre · Source · Catégorie · Actionnable · Date)
└── Scheduled tasks

🧭 Roadmaps (par écosystème)
├── Portefeuille global (Now/Next/Later agrégé)
├── Dev
├── LifeOS + assistant
├── Jeux
├── Travaux maison
├── Domotique
└── Apprentissages perso

📊 Reviews
├── Sprint (clôtures)
├── Semaine
└── Mois

🤖 Agents & scheduled tasks
├── briefing-agent (08h)
├── daily-veille-technique (07h) 🆕
├── pr-review-agent
├── sprint-agent
├── health-agent
├── notion-sync-agent
├── pr-aging
└── ci-sweep

🗃️ Archive (migrés + inactifs)
└── [MIGRÉ 2026-04-20] × N anciennes ADRs
```

### Améliorations d'accès (UX Notion)

1. **Linked DB views** sur Home → une vue Tâches P0 + Bugs P0 + Bloqueurs du jour
2. **Pages pinned** dans sidebar : Home · Portfolio actif · Roadmap global · Conventions
3. **Emoji-first** (🔴🟠🟡🟢 pour statuts) — lisibilité immédiate
4. **Raccourcis recherche** : `?projet=doc-gen`, `?role=Actif`, `?priority=P0`
5. **Relation bidirectionnelle** Projets ↔ Tâches ↔ Bugs ↔ Dette (clics rapides)

### Nouveaux rollups DB Projets

Exposer directement dans la ligne projet :
- Nb issues GitHub ouvertes (via MCP sync)
- Budget annuel total (infra + saas + effort_h)
- Dernière activité (dernier commit via MCP GH)
- Bloqueurs actifs (count)
- Statut CI (vert/rouge)

---

## 3 · Script/automatisation pour alimenter Notion

Ce qui peut être scripté (via MCP Notion) :
- **Import `portfolio-metadata.yml` → DB Projets** (mise à jour rôle/budget/bloqueurs pour chaque repo)
- **Import cross-project-dependencies.md → DB Tâches** (créer tâches X-1 → X-11)
- **Import `issues-audit-YYYY-MM-DD.md` → DB Bugs** (après audit GitHub)

Script à créer : `shared-standards/scripts/sync-notion-from-disk.py`

Ce qui reste UI :
- Création des 3 nouvelles DBs (Bugs · Dette · Veille tech)
- Vues filtrées (4 sur DB Projets)
- Layout Home avec widgets
- Relations entre DBs

---

## 4 · Actions manuelles prioritaires

| # | Action | Durée | Prérequis |
|---|--------|-------|-----------|
| 1 | Créer DB Bugs (UI) | 15 min | — |
| 2 | Créer DB Dette technique (UI) | 15 min | — |
| 3 | Créer DB Veille tech (UI) | 15 min | — |
| 4 | Ajouter 4 vues à DB Projets | 15 min | — |
| 5 | Créer page Home + widgets | 30 min | DBs créées |
| 6 | Pinner les 4 pages racines | 5 min | Home créée |
| 7 | Rollups budget + activité sur DB Projets | 20 min | — |
| 8 | Archiver 10+ pages doublons | 30 min | (voir divergences-2026-04-20.md) |
| 9 | Créer page Wiki "CONVENTIONS chrysa" | 20 min | — |
| 10 | Importer portfolio-metadata.yml (via script à écrire) | 15 min + dev script | DB Projets à jour |

**Total** : ~3h UI + 2-3h dev script

---

## 5 · Divergences restantes (complément au doc précédent)

Non couverts dans la précédente itération mais visibles maintenant :
- Pages `[github-state-sync] FAILED` continuent d'arriver → scheduled task à désactiver en attendant fix gh auth
- Pas de page dédiée à "CI budget GitHub Free" (tracking 2000 min/mois)
- Labels GitHub actuels disparates par repo → `sync-labels.yml` déploiera la palette unifiée
