# game-solver-platform

> Plateforme IA de résolution de jeux · platinage rapide · partage entre amis · leaderboard global.

**Rôle** : Opportuniste P2
**Status** : V0 (repo à créer)
**Public** : oui
**Stack** : Python 3.14 · FastAPI ≥0.115 · React 19 + Vite 6 · TypeScript · PostgreSQL 16 · Redis 7 · LangGraph · PydanticAI
**IA** : Claude API (primary) · Ollama self-hosted (fallback)
**Auth** : `@chrysa/auth` (4 modes — dépend du Sprint 1 chrysa-lib)

## Valeur plateforme

Plateforme multi-jeux qui aide les joueurs à **platiner leurs jeux rapidement** en leur donnant :

1. **Solveur IA adaptatif** — énigmes, puzzles, séquences de trophées complexes. Hints progressifs (nudge → indice → solution) pour préserver le plaisir.
2. **Import trophées** — Steam API + PSN via scraping (V2) pour auto-détecter ce qu'il reste à débloquer.
3. **Partage entre amis** — groupes privés, solutions commentées, compare progress.
4. **Leaderboard global** — classement par jeu (vitesse platine, % complété, entraide donnée).
5. **Blueprint library** — pour les jeux de gestion/craft (Satisfactory, Factorio, Dyson Sphere), import blueprints partagés.

## Différenciation vs concurrence

- **Pas un wiki statique** (vs PowerPyx, TrueAchievements) : IA contextuelle + interactive.
- **Pas un cheat** : hint system gradué, focus "aide respectueuse de la découverte".
- **Social-first** : leaderboard entre amis > leaderboard public anonyme.

## Scope V1 (Q3 2026 après chrysa-lib/auth)

| Feature | V1 | V2 | V3 |
|---------|----|----|----|
| Solver puzzles génériques (Taquin, Sokoban, énigmes logiques) | ✅ | | |
| Auth Google OAuth + local via @chrysa/auth | ✅ | | |
| Leaderboard global (vitesse résolution) | ✅ | | |
| Partage amis (groupes privés) | ✅ | | |
| Hint system 3 niveaux (nudge/hint/full) | ✅ | | |
| Import trophées Steam API | | ✅ | |
| Auto-détection puzzle via screenshot (vision) | | ✅ | |
| Support Satisfactory/Factorio (import saves via SAT v2) | | ✅ | |
| PSN trophies (scraping) | | | ✅ |
| Achievements Xbox/GOG/Epic | | | ✅ |
| Communauté forum intégré | | | ✅ |

## Architecture V1

```
game-solver-platform/
  api/                      FastAPI
    apps/
      auth/                 @chrysa/auth wrapper
      solver/               Moteur solver (LangGraph)
      leaderboard/          PostgreSQL + Redis cache
      social/               Amis + groupes + partage
      games/                Catalogue jeux + metadata
    services/
      claude_agent.py       Agent IA primaire
      ollama_agent.py       Fallback local
  web/                      React 19 + Vite
    src/
      features/
        solver/             UI solveur interactif
        leaderboard/        Classements
        friends/            Social
        puzzle-editor/      Éditeur communauté (V2)
  infra/
    docker-compose.yml      PostgreSQL + Redis + API + web
```

## Interactions portfolio

- **Dépend de** : `chrysa-lib/auth` (Sprint 1) · `ai-aggregator` (Ollama fallback + prompt-optimizer) · `server` (hébergement infra)
- **Consomme** : `satisfactory-automated_calculator` (imports blueprints Satisfactory) via API interne
- **Exporte** : `dev-nexus` embed (widget leaderboard perso)

## Bloqueurs P0 avant démarrage

1. Créer repo `chrysa/game-solver-platform` via `gh repo create`
2. Rédiger PRD V1 (scope puzzles + auth + leaderboard + social)
3. chrysa-lib Sprint 1 @chrysa/auth livré
4. Décider packaging monorepo (Turborepo) ou split API+web

## Budget annuel

- Effort : 180h (réparti sur 2 trimestres post-auth)
- Infra : ~40€ (DB + Redis sur server Kimsufi existant)
- SaaS : 0 (Claude API consommée via `ai-aggregator` shared)

## Décisions attendues

- D-0001 : Stack API = FastAPI (alignement plateforme)
- D-0002 : Leaderboard = cache Redis + persist PostgreSQL (pas de Timestream)
- D-0003 : Hint system = 3 niveaux gradués (nudge/hint/full) pour respecter découverte
- D-0004 : Game metadata source = IGDB API (gratuit, complet) vs Giant Bomb
- D-0005 : Partage blueprints Satisfactory = import/export format SCIM de SAT v2
