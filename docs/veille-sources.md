# Sources de veille — chrysa

> À intégrer dans la scheduled task "veille-technique" (Notion + MCP)
> Format : catégorie · URL · cadence · signal/bruit attendu

---

## Dev (Python · React · DevOps · Claude)

| Source | URL | Cadence | Note |
|--------|-----|---------|------|
| **XDA Developers** | https://www.xda-developers.com/ | daily | déjà utilisé, signal élevé sur Claude/desktop/VSCode |
| **HowToGeek** | https://www.howtogeek.com/ | daily | idem, angle productivité |
| **HN front page** | https://news.ycombinator.com/ | daily | filtrer par score > 200 |
| **Changelog.com** | https://changelog.com/news | hebdo | newsletter dev, qualité haute |
| **Anthropic blog** | https://www.anthropic.com/news | hebdo | Claude updates, MCP, Agent SDK |
| **FastAPI releases** | https://github.com/fastapi/fastapi/releases | mensuel | stack lock, rester à jour |
| **Astral (Ruff/uv)** | https://astral.sh/blog | mensuel | tooling Python |
| **Turborepo changelog** | https://turbo.build/blog | mensuel | monorepo actualité |
| **Docker blog** | https://www.docker.com/blog/ | hebdo | containers, best practices |
| **GitHub changelog** | https://github.blog/changelog/ | hebdo | Actions, Dependabot, Free tier |

## Domotique

| Source | URL | Cadence |
|--------|-----|---------|
| **Home Assistant release notes** | https://www.home-assistant.io/blog/ | mensuel |
| **HA Community — What's New** | https://community.home-assistant.io/c/announcements | hebdo |
| **Zigbee2MQTT releases** | https://github.com/Koenkk/zigbee2mqtt/releases | mensuel |
| **r/homeautomation** | https://www.reddit.com/r/homeautomation/ | hebdo |
| **ESPHome blog** | https://esphome.io/changelog/current.html | mensuel |
| **Frigate NVR** | https://frigate.video/blog | mensuel |

## Jeux vidéo (outils + dev)

| Source | URL | Cadence |
|--------|-----|---------|
| **Godot engine blog** | https://godotengine.org/news/ | mensuel |
| **Unity blog** | https://unity.com/blog | hebdo |
| **r/gamedev** | https://www.reddit.com/r/gamedev/ | hebdo |
| **Gamasutra / GameDeveloper.com** | https://www.gamedeveloper.com/ | hebdo |
| **Satisfactory patch notes** | https://www.satisfactorygame.com/news | mensuel |
| **WoW patch notes** | https://worldofwarcraft.blizzard.com/news | mensuel |

## Automatisation (agents IA, scheduled, scripts)

| Source | URL | Cadence |
|--------|-----|---------|
| **MCP announcements** | https://www.modelcontextprotocol.io/blog | mensuel |
| **LangGraph / LangChain blog** | https://blog.langchain.dev/ | hebdo |
| **Pydantic AI** | https://ai.pydantic.dev/ | mensuel |
| **n8n newsletter** | https://n8n.io/blog/ | hebdo (si tu veux comparer) |
| **Awesome Agents GitHub** | https://github.com/e2b-dev/awesome-ai-agents | mensuel |

## Sources transverses proposées (non encore utilisées)

- **GitHub Trending Weekly** → https://github.com/trending?since=weekly
- **Product Hunt daily** → https://www.producthunt.com/ (via RSS filtré)
- **Sourcehut announcements** → https://sourcehut.org/blog/ (alternative GitHub, souveraineté)
- **Rust blog** → https://blog.rust-lang.org/ (si Rust devient pertinent)
- **Fly.io blog** → https://fly.io/blog/ (infra/platform patterns, même si on reste Kimsufi)
- **Dave Farley YouTube** → https://www.youtube.com/@ContinuousDelivery (principes, pas daily)

---

## Format "veille journalière"

### Prompt scheduled agent (quotidien 07h00)

```
Tu es un veille-technique agent pour chrysa.

Contexte : solo dev multi-stack (Python 3.14, React 19, Docker, Claude, Notion).
Objectif : produire un digest quotidien des sources listées dans
`shared-standards/docs/veille-sources.md`, catégorie "daily" uniquement.

Critères d'inclusion :
- Pertinent pour au moins 1 des thématiques : dev Python/React, domotique, jeux, automatisation IA
- Actionnable dans les 7 jours (pas juste "intéressant en soi")
- Pas déjà mentionné dans les 30 derniers digests

Format de sortie :
# Veille {date}

## 🔥 Top 3 (action immédiate)
1. [Titre] — Source — Pourquoi ça compte pour chrysa (1 phrase) + action suggérée

## 📌 À suivre (pas urgent)
- [Titre] — Source — 1 phrase

## 💡 Inspiration / idées
- [Titre] — Source — 1 phrase

## 🆕 Propositions de nouvelles sources
(1 à 3 nouvelles sources détectées via citations/backlinks pertinents)

## 🗑️ Anti-signaux (à ne PAS suivre)
- [Titre] — Source — raison rapide

Post dans DB Notion "Veille tech" + résumé en 3 bullets dans briefing 08h.
```

### Scheduled task à configurer

```
Nom : daily-veille-technique
Cadence : quotidien 07h00 Europe/Paris
Prompt : cf. ci-dessus
Connecteurs : WebFetch · Notion (DB Veille tech à créer si absente)
Budget tokens : ~15k/run (filtrage + résumé)
Sortie : 1 page Notion/jour dans DB Veille, 3 bullets dans briefing-agent (09h05)
```

### Pattern "propose-more-sources"

À chaque run, l'agent inclut une section `🆕 Propositions de nouvelles sources` (1-3 nouvelles URL détectées via :
- Citations/backlinks répétés dans les articles lus
- Communautés qui mentionnent souvent les sources existantes
- Blogs d'auteurs dont les posts sont cités plusieurs fois

→ **Tu valides ou rejettes chaque proposition en commentaire Notion hebdo**. Les validées sont ajoutées automatiquement à `veille-sources.md` le dimanche (via scheduled task `sources-sync`).

---

## Résumé articles XDA analysés cette session (à reporter Notion)

### Article 1 — Claude Code desktop control (1 semaine)
**Signaux actionnables pour chrysa** :
- Dispatch feature (phone → PC command) = pattern à répliquer pour lifeos via Tailscale
- Claude préfère Python libs à l'UI manipulation (Pillow > Paint) → contourne limitations souris
- Email filter + digest hebdo = déjà dans notre scheduled task `email-triage`

### Article 2 — Obsidian self-organizing vault
**Signaux actionnables** :
- Pattern `QuickAdd` + `Auto Note Mover` → transposable à **lifeos D-0003** (visu Notion ergonomique) pour auto-classer les notes reçues par Claude
- Tags case-sensitive = levier multi-niveau (`#design` déplace, `#Design` filtre)
- **Idée** : `lifeos` pourrait exposer une vue style "vault auto-organisé" par-dessus Notion pour les repos (auto-classer nouveaux repos dans DB Projets selon README)

### Article 3 — VSCode non-dev usage
**Signaux** :
- Markdown All in One + SVG Previewer confirment notre stack dev
- Pattern split-view édition/preview → réplicable dans lifeos V2

### Article 4 — VSCode + Notion pairing
**Signaux actionnables forts** :
- Extension `Notion ToDo` pour VSCode → cocher tasks sans quitter éditeur
- Flow : brainstorm Notion → rédaction VSCode → publication → tracking Notion = exactement notre setup !
- **Action concrète** : documenter ce flow dans `shared-standards/docs/workflow-chrysa.md` (à créer)

---

## Actions concrètes post-analyse XDA

1. **Créer page Notion "Patterns XDA 2026-04-20"** avec les 4 articles synthétisés
2. **Ajouter D-0004 dans lifeos/DECISIONS.md** : "Vue vault auto-organisée (inspiré Obsidian QuickAdd + Auto Note Mover)"
3. **Ajouter ligne dans veille-sources.md** : XDA et HowToGeek en daily (déjà fait)
4. **Évaluer Dispatch pattern** : lifeos pourrait exposer un endpoint phone → PC via Tailscale pour lancer des actions dev
