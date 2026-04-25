# chrysa/media-tracker

> Tracker films + séries centralisé · Simkl API primaire · self-host option via Yamtrack · remplacement BetaSeries.

**Rôle** : Opportuniste P2
**Status** : V0 (repo à créer)
**Public** : oui (instance cloud) · self-host Yamtrack option
**Stack** : Python 3.14 · FastAPI ≥0.115 · React 19 + Vite 6 · PostgreSQL 16 · Simkl API + TMDB fallback
**Auth** : `@chrysa/auth` (dépend chrysa-lib Sprint 1)

## Contexte · pourquoi remplacer BetaSeries

BetaSeries a longtemps été le meilleur tracker FR mais en 2026 l'écosystème a bougé. Le vrai besoin utilisateur chrysa : **suivre Netflix + Prime Video + Disney+ + Crunchyroll** (4 services actifs).

### Matrix couverture scrobbling 2026

| Service | BetaSeries | Simkl ext | Trakt Streaming Scrobbler | Yamtrack |
|---------|:----------:|:---------:|:--------------------------:|:--------:|
| Netflix | limité | ✅ ext | ✅ **officiel** | ❌ |
| Prime Video | — | ⚠️ manual | ✅ **officiel** | ❌ |
| Disney+ | — | ❌ | ✅ **officiel** | ❌ |
| Crunchyroll | — | ✅ **natif** | ⚠️ ext | ❌ |
| Apple TV+ / Hulu / Max / Paramount+ | — | ❌ | ✅ officiel | ❌ |
| Plex / Jellyfin self-host | ❌ | ✅ | ✅ | ✅ natif |
| Watchlist gratuite | illimitée | illimitée | 100 items (VIP 30€/an) | illimitée |
| Anime-first design | ❌ | ✅ | partiel | ✅ |
| Self-host | ❌ | ❌ cloud-only | ❌ | ✅ **Docker** |

### Décision D-0001 · Trakt VIP primary + Jellyfin source locale + Yamtrack mirror

**Architecture à 3 sources convergentes** :

```
┌────────────────────┐     ┌────────────────────┐     ┌────────────────────┐
│  Jellyfin Kimsufi  │     │  Trakt Streaming   │     │  Simkl Chrome ext  │
│  (bibliothèque     │     │  Scrobbler + Univ. │     │  (Crunchyroll      │
│   perso local)     │     │  Trakt Scrobbler   │     │   natif anime)     │
└─────────┬──────────┘     └─────────┬──────────┘     └─────────┬──────────┘
          │ plugin Jellyfin-Trakt    │ Netflix/Prime/Disney+/HBO │
          └──────────────┬───────────┴───────────────────────────┘
                         ▼
                ┌─────────────────┐
                │  Trakt (cloud)  │
                │  single source  │
                └────────┬────────┘
                         │ nightly sync
                         ▼
            ┌─────────────────────────┐
            │  Yamtrack self-host     │
            │  (mirror · souveraineté)│
            │  sur Kimsufi            │
            └─────────────────────────┘
```

**Pourquoi Trakt primary** : seule API 2026 avec **Streaming Scrobbler officiel** couvrant Netflix/Prime/Disney+/Apple TV+/Hulu/Max/Paramount+.

**Pourquoi Jellyfin comme source locale** : plugin natif `Jellyfin.Plugin.Trakt` scrobble en temps réel tout ce que tu regardes dans ta bibliothèque perso (FireTV/iPhone/Apple TV/browser compris). Zéro dépendance aux extensions browser pour ce contenu.

**Pourquoi Yamtrack mirror** : souveraineté des données · si Trakt disparaît ou change de modèle, tu as tout ton historique en local.

**Coût** : 30€/an Trakt VIP (watchlist illimitée) · 0€ Jellyfin (déjà sur Kimsufi) · 0€ Yamtrack.

**Alternative si Crunchyroll ≥ 60% du temps** : bascule sur Simkl-primary (voir Appendix A).

## Architecture V1

```
chrysa/media-tracker/
  api/                       FastAPI
    apps/
      auth/                  @chrysa/auth wrapper
      providers/
        trakt.py             Trakt OAuth2 PRIMARY · scrobbling Netflix/Prime/Disney+
        simkl.py             Simkl OAuth2 fallback Crunchyroll (anime)
        yamtrack.py          Yamtrack REST self-host mirror (souveraineté)
        tmdb.py              Metadata enrichment (posters · casting)
      tracker/
        models.py            Movie · Episode · WatchEvent · Watchlist
        services.py          Unified API au-dessus des providers
        sync.py              Scrobbling + sync Trakt → Yamtrack nightly
      recommendation/        V2 : scoring + suggestions soir
  web/                       React 19 + Vite + shadcn/ui
    src/
      features/
        watchlist/           vues watchlist + to-watch
        history/             historique + notes
        discover/            catalogue TMDB
        settings/            OAuth provider switching
  infra/
    docker-compose.yml       Postgres + API + web + Yamtrack sidecar
```

## Scrobbling · comment ça marche concrètement

Trakt ne peut PAS savoir ce que tu regardes sur Netflix/Prime/Disney+ sans ton aide. 3 options actives à activer côté utilisateur :

1. **Trakt Streaming Scrobbler officiel** (dans le site Trakt, Settings → Streaming) → Trakt poll les APIs internes de ces services pour détecter ta dernière vue. Fonctionne sur les services avec un compte Trakt connecté en amont.
2. **Universal Trakt Scrobbler (extension Chrome/Firefox)** · https://github.com/trakt-tools/universal-trakt-scrobbler · détecte ce que tu regardes dans ton browser en temps réel et scrobble.
3. **Apps mobiles tierces** (wako) · wrappent les services et scrobble au play.

Pour Crunchyroll spécifiquement, 2 options :
- Trakt universal extension (moins fiable pour anime)
- **Simkl Chrome extension** (natif Crunchyroll · recommandé en complément si tu fais beaucoup d'anime)

## Migration BetaSeries

**Via Simkl (natif)** :
1. Login Simkl → Settings → Import → "Betaseries"
2. Saisir ton username BetaSeries
3. Simkl crawl + sync historique (5-10 min)
4. Verify watchlist + historique + notes préservés

**Via script (Trakt)** :
- https://github.com/tuxity/betaseries-to-trakt (Python, peut nécessiter update 2026)

**Export CSV manuel** :
- BetaSeries → Profil → Export CSV (historique + watchlist)
- Import Simkl/Yamtrack CSV (format standard MediaTracker)

## Features V1 (Q3 2026, après chrysa-lib/auth)

- [ ] OAuth2 Simkl + stockage refresh_token (chrysa-lib/auth)
- [ ] Sync historique + watchlist (pull Simkl → Postgres local)
- [ ] UI React : watchlist avec posters TMDB + filters (genre, statut)
- [ ] UI React : historique chronologique + notes
- [ ] Scrobbling manuel (mark as watched via UI)
- [ ] Widget dev-nexus embed : "dernière série vue · prochains épisodes"
- [ ] Scheduled task weekly-recap (nouveaux épisodes dispo · séries abandonnées · suggestions)

## Features V2

- [ ] Scrobbling auto via Jellyfin webhook (si Jellyfin sur server Kimsufi)
- [ ] Agent lifeos "suggestion soirée" (genre préféré + dispo + humeur)
- [ ] Recommendations ML (similar shows via TMDB knn)
- [ ] Watch party multi-user (notes partagées, vote suivant)
- [ ] Export CSV backup (redondance Simkl)
- [ ] Migration 1-clic Simkl → Yamtrack (pour souveraineté future)

## Interactions portefeuille

- **Dépend de** : `chrysa-lib/auth` (Sprint 1) · `server` (DB Postgres shared)
- **Exporte** : widget `dev-nexus` (embed "last watched") · hook `lifeos` (suggestions planning soir)
- **Option** : si self-host Yamtrack choisi → déployé sur `server/docker-compose.yml` avec Nginx reverse proxy

## Secrets requis

Collectés par `chrysa-master.sh --init-secrets` (stage 15) :
- `SIMKL_CLIENT_ID` + `SIMKL_CLIENT_SECRET`
- `TRAKT_CLIENT_ID` + `TRAKT_CLIENT_SECRET` (optionnel · alternative)
- `TMDB_API_KEY` (enrichissement metadata · gratuit illimité)

## Budget

- Effort V1 : 60h (Simkl OAuth + UI watchlist + history + scheduled sync)
- Effort V2 : 80h (scrobbling + recommandations + agents)
- Infra : 0€ (Simkl cloud gratuit · TMDB gratuit · DB sur Postgres server Kimsufi existant)
- SaaS : 0€ si Simkl · 30€/an si Trakt VIP (non recommandé)
- Auto-hébergé Yamtrack : +1Go RAM sur server Kimsufi

## Décisions à acter (D-XXXX à créer)

- D-0001 : Provider primaire = Simkl (vs Trakt vs BetaSeries)
- D-0002 : Architecture = API dédiée vs extension lifeos agent
- D-0003 : Scope V1 = tracker-only (pas recommandations ni scrobbling auto)
- D-0004 : Migration BetaSeries via Simkl native import (pas script custom)
- D-0005 : Yamtrack self-host = V2 optionnel, pas bloquant V1

## Sources

- [Simkl docs](https://docs.simkl.org/)
- [Simkl vs Trakt comparison](https://docs.simkl.org/how-to-use-simkl/faq/frequently-asked-questions/simkl-alternatives/simkl-vs-trakt)
- [Yamtrack GitHub](https://github.com/FuzzyGrim/Yamtrack)
- [Migration BetaSeries → Simkl](https://docs.simkl.org/how-to-use-simkl/advanced-usage/import-export-data/importing-to-simkl/supported-platforms/betaseries)
- [TMDB API docs](https://developer.themoviedb.org/reference/intro/getting-started)
