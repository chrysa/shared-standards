# ROADMAP — game-solver-platform

> Plateforme IA de résolution de jeux · platinage rapide · leaderboard social.

## Now (Q2 2026 — après chrysa-lib/auth)

- [ ] Créer repo `chrysa/game-solver-platform`
- [ ] Rédiger PRD V1 complet (sections : user stories, flows, architecture, API spec)
- [ ] Scaffold via `chrysa-init.sh` (FastAPI backend + React frontend)
- [ ] Intégrer `@chrysa/auth` Sprint 1 (Google OAuth + local)
- [ ] Endpoint `/api/v1/puzzles/solve` avec LangGraph + Claude API

## Next (Q3 2026)

- [ ] Catalogue 20+ puzzles génériques (Taquin, Sokoban, énigmes logiques, mini Rubik)
- [ ] Leaderboard global + filtres (par jeu, période, amis)
- [ ] Social : invitations, groupes privés, notifs ntfy
- [ ] Hint system 3 niveaux (nudge/hint/full) avec UX 3 clics explicites
- [ ] Intégration `ai-aggregator` pour fallback Ollama (réduire coûts Claude)

## Later (Q4 2026 — V2)

- [ ] Import trophées Steam API (auth Steam OAuth)
- [ ] Auto-détection puzzle via upload screenshot (Claude Vision)
- [ ] Import blueprints Satisfactory (consomme API SAT v2)
- [ ] Communauté : éditeur puzzles contributeurs
- [ ] Widget leaderboard embed sur dev-nexus (perso)

## Parking lot

- PSN trophies (scraping · légal flou, V3)
- Xbox/GOG/Epic (V3)
- Mobile app (React Native · dépend adoption)
- Twitch extension (overlay hints pour streamers)

## Metrics de succès

- V1 shippé avant fin Q3 2026
- 5 amis actifs sur leaderboard privé au lancement
- 50+ puzzles catalogués
- P50 temps résolution IA < 5s
- Coût API Claude mensuel < 30€ (grâce fallback Ollama via ai-aggregator)
