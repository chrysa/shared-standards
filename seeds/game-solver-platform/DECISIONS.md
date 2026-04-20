# DECISIONS — game-solver-platform

> Décisions locales au repo. Numérotation D-XXXX locale.
> Conventions transverses : voir `~/.claude/CLAUDE.md`.

---

## D-0001 · Création projet — Split depuis SAT

**Date** : 2026-04-20
**Statut** : Acté
**Contexte** : Le repo `satisfactory-automated_calculator` avait historiquement une ambition multi-jeux (SAT v2). Après analyse, le scope multi-jeux s'étend bien au-delà du calcul de chaînes de production (puzzles, énigmes, trophées, leaderboard social). Garder les deux dans un même repo violerait la règle "un projet = une valeur plateforme claire".

**Décision** : Créer un nouveau projet `game-solver-platform` dédié à la plateforme IA de platinage de jeux. `satisfactory-automated_calculator` (renommé `satisfactory-factory-manager` en SAT v2) garde son scope Satisfactory-only.

**Conséquences** :
- 2 repos distincts, 2 déploiements, 2 URL publiques
- Interop via API interne (game-solver-platform consomme les blueprints exportés par SAT v2)
- Budget effort x2 mais chaque projet reste shippable indépendamment
- Cohérence forte avec la règle 1+2 (les deux restent Opportunistes P2)

**Alternative rejetée** : Monorepo Turborepo avec packages `@chrysa/solver` + `@chrysa/factory` — écartée car les deux produits visent des audiences et cadences de release différentes.

---

## D-0002 · Stack backend = FastAPI (pas Django)

**Date** : 2026-04-20
**Statut** : Proposé
**Contexte** : Plateforme stack chrysa = FastAPI ≥0.115 par défaut. Besoin d'orchestration agents IA (LangGraph) qui joue mieux avec async FastAPI.

**Décision** : FastAPI + SQLAlchemy 2.0 async + Alembic.

**Conséquences** : cohérence stack avec `ai-aggregator`, `chrysa-lib`, `dev-nexus`. Pas de Django admin — un front React custom pour l'admin (surcoût accepté).

---

## D-0003 · Hint system à 3 niveaux gradués

**Date** : 2026-04-20
**Statut** : Proposé
**Contexte** : Différenciation vs wikis/cheat sites. Le produit doit aider sans tuer la découverte.

**Décision** : 3 niveaux de hint progressifs par puzzle/énigme :
1. **Nudge** (indice minimal, orienté méthode, jamais solution)
2. **Hint** (indice concret sur l'étape bloquante)
3. **Full** (solution complète, avec explication pédagogique)

Compteur public "% joueurs ayant demandé hint X" = signal de difficulté.

**Conséquences** : chaque puzzle doit être accompagné de 3 textes par l'auteur (communauté ou IA) avant publication. UX = 3 clics explicites pour éviter spoil accidentel.

---

## D-0004 · Source metadata jeux = IGDB (pas Giant Bomb)

**Date** : 2026-04-20
**Statut** : Proposé
**Contexte** : Besoin d'un catalogue de jeux fiable avec artwork, genres, plateformes, trophées. Options : IGDB (Twitch) gratuit, Giant Bomb API, RAWG API.

**Décision** : IGDB API (Twitch). Rate limit 4 req/s suffisant pour V1. Qualité metadata supérieure à RAWG sur les trophées.

**Conséquences** : dépendance à un compte Twitch + secret rotation. Fallback RAWG documenté si IGDB devient payant.

---

## D-0005 · Import blueprints Satisfactory via SAT v2

**Date** : 2026-04-20
**Statut** : Acté (conséquence de D-0001)
**Contexte** : Satisfactory a un format de blueprint binaire complexe. Ré-implémenter dans game-solver-platform serait redondant.

**Décision** : Game-solver-platform consomme l'API REST de `satisfactory-factory-manager` (SAT v2) pour l'import/export blueprints. Endpoint `/api/v1/blueprints/import` côté SAT v2.

**Conséquences** : SAT v2 devient dépendance runtime de game-solver-platform pour les features Satisfactory. Documenter le contrat d'API dans `satisfactory-factory-manager/docs/API.md`.
