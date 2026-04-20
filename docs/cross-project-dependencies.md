# Cross-project dependencies — actions à tracker

> Chaque ligne = une action bloquante qui touche un repo depuis un autre.
> Quand validée : issue GitHub créée + page Notion + ligne ROADMAP.md mise à jour.

---

## Table de dépendances

| # | Repo source (blocant) | Repo cible (bloqué) | Action attendue | Priorité | Statut |
|---|------------------------|---------------------|------------------|----------|--------|
| X-1 | chrysa-lib | dev-nexus, my-fridge, lifeos, doc-gen | Livrer `@chrysa/auth` Sprint 1 (4 modes) | P0 | Open |
| X-2 | doc-gen | (lui-même, mais bloque Actif) | Résoudre PR #1 `python-jose → joserfc` | P0 | Open |
| X-3 | ai-aggregator | dev-nexus, lifeos | Livrer module `prompt-optimizer` (D-0001) | P1 | Open |
| X-4 | server | tous les projets déployés | Déployer monitoring stack Prometheus+Grafana+Loki+Qdrant (D-0001 server) | P1 | Open |
| X-5 | shared-standards | tous | Workflow `auto-PR-handler` (D-0005 shared-standards) — pré-requis GitHub MCP | P2 | Open |
| X-6 | chrysa-workstation (n/a) | windows-autonome + agent-config | Livrer DECISIONS.md local sur chaque repo (ADR-0026) | P2 | Open |
| X-7 | resume (à créer) | linkendin-resume + my-resume | Fusion effective selon D-0011/0025 | P3 | Open |
| X-8 | coaching-tracker (à créer) | coaching-sport + coaching-guitare | Fusion selon D-0012 | P3 | Open |
| X-9 | shared-standards/packages | guideline-checker (standalone existant) | Déplacer guideline-checker en package (D-0016) | P2 | Open |
| X-10 | ai-aggregator | all IA projects | Installer Ollama self-hosted | P2 | Open |
| X-11 | Notion workspace | tous | Créer DB Bugs + DB Dette technique (notion-restructure-plan P1) | P1 | Open |

---

## Structure issue GitHub (à créer par gh cli)

```yaml
title: "[{priorité}] {titre court}"
body: |
  ## Context
  {description · 2-3 lignes}

  ## Bloqueurs
  - {qui attend}

  ## Critères d'acceptation
  - [ ] …

  ## Liens
  - Décision : `{repo}/DECISIONS.md` §D-XXXX
  - Autres tickets : #N
labels:
  - cross-project
  - priority/{p0|p1|p2|p3}
```

---

## Procédure

1. Lancer `bash shared-standards/scripts/generate-cross-project-issues.sh` → génère un fichier `cross-project-issues.sh` avec toutes les commandes `gh issue create`
2. Inspecter puis `bash cross-project-issues.sh` pour les créer en batch (nécessite `gh auth login`)
3. Les pages Notion correspondantes sont déjà créées (voir ci-dessous)
4. Les ROADMAP.md des repos bloqués sont mis à jour avec la référence
