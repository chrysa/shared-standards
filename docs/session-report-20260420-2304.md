# Session report chrysa · 2026-04-20T23:14:40+02:00

**Durée** : 607s · **Log** : `/home/anthony/Documents/perso/projects/chrysa/.chrysa-master-20260420-2304.log`
**Flags** : dry=false · parallel=false · retry=2 · cron=false

## Résultats

| Stage | Statut | Durée | Exit | Tries |
|-------|--------|-------|------|-------|
| 0-preflight | ✓ OK | 122s | 0 | 1 |
| 1-fix-terminal | ✓ OK | 0s | 0 | 1 |
| 2-fix-all | ✓ OK | 294s | 0 | 1 |
| 3-apply-standards | ✓ OK | 8s | 0 | 1 |
| 4-cross-project | ✓ OK | 15s | 0 | 1 |
| 5-audit-issues | ✓ OK | 50s | 0 | 1 |
| 6-manual | ✓ OK | 0s | 0 | 1 |
| 8-notion-wizard | ✓ OK | 115s | 0 | 1 |
| 7-cleanup | ✓ OK | 0s | 0 | 1 |
| 9-notion-apply | ✓ OK | 0s | 0 | 1 |
| 10-seed-backlog | ✓ OK | 2s | 0 | 1 |
| 11-bootstrap-projects | ✗ FAILED | 0s | 1 | 1 |
| 12-sched-cleanup | ✓ OK | 0s | 0 | 1 |
| 13-issue-83-patch | ✓ OK | 0s | 0 | 1 |

## Synthèse

- ✓ OK : 13
- ✗ Failed : 1
- ⚠ Skipped : 0

## Reprio 2026-04-20 (ordre)

1. **server Socle P0** (infra · backup DB · Let's Encrypt · stack monitoring · Tailscale keys)
2. **chrysa-lib Socle P1** (auth — débloque 8+ projets aval)
3. **dev-nexus Actif P0** (multiplicateur · scaffold sans auth)
4. **ai-aggregator Actif P1** (Ollama · sans auth)
5. Actifs P2 : doc-gen · my-fridge · lifeos

## Alertes critiques restantes

- 🔴 doc-gen PR #1 python-jose → joserfc · BLOQUANT
- 🔴 chrysa-lib Sprint 1 @chrysa/auth · non démarré
- 🟠 pre-commit-tools Issue #83 · release workflow à patcher
- 🟠 Désactiver scheduled task `github-state-sync` (obsolète)
- 🟠 Docker Desktop → Docker Engine (~156€/an)
- 🟡 GitHub MCP à configurer (PAT requis)

## Achats hardware pending

| Item | Coût | Priorité | Débloque |
|------|------|----------|----------|
| TP-Link Deco mesh | ~120€ | P0 | Travaux maison |
| Shelly 1 Plus × 3 | ~75€ | P1 | Portail auto (vs Somfy 200€) |
| Raspberry Pi 5 | ~80€ | P2 | ntfy.sh self-host |

## Split SAT (2026-04-20) — 2 projets Opportunistes P2

- **satisfactory-factory-manager** (SAT v2) · scope Satisfactory-only · rename repo + PRD scope (save parser + layout 3D + optimizer + blueprints + API REST)
- **game-solver-platform** (nouveau) · plateforme IA platinage multi-jeux · leaderboard social · partage amis · hint system 3 niveaux · stack FastAPI + React 19 + LangGraph + Claude API

Seeds : `chrysa/shared-standards/seeds/{satisfactory-factory-manager,game-solver-platform}/`
Dépendance commune : chrysa-lib/auth (Sprint 1)

## Breakdown par domaine

### 💻 Dev (priorité dégressive)

1. server (infra P0) · chrysa-lib (auth P1) · dev-nexus (Actif P0) · ai-aggregator (Actif P1)
2. doc-gen · my-fridge · lifeos (Actifs P2)
3. shared-standards · skills · project-init · pre-commit-tools · guideline-checker (Socles/outils)
4. SAT v2 · game-solver-platform · PO-GO-DEX · D-D · FabForge (Opportunistes P2-P3)

### 🏠 Maison

- Travaux P0 : TP-Link Deco mesh (~120€) · bloqueur démarrage travaux
- Domotique P1 : Shelly 1 Plus × 3 (~75€) · portail + volets (vs Somfy 200€+)
- Self-host P2 : Raspberry Pi 5 (~80€) · ntfy.sh + Home Assistant

### 🎮 Jeux (Opportunistes)

- SAT v2 → satisfactory-factory-manager (Satisfactory uniquement)
- game-solver-platform → nouveau repo · platinage multi-jeux
- D-D · FabForge · PO-GO-DEX (stables V1)
- Discordium V3 · coach (Opportunistes V0)

## Liens Notion

- 🔸 INDEX : https://www.notion.so/34859293e35e81839c77d381a2db7a16
- 🎯 Reprio : https://www.notion.so/34859293e35e81f9b015db5d9307877d
- ⚡ Ops Tasks : https://www.notion.so/0fa827fa2ef7496aa1292860a401d8ac
- 🏗️ Restructuration Teamspace : voir wizard YAML + plan d'exécution

## Sous-catégories Notion (Ops Tasks DB)

Le stage 10 `--seed-backlog` crée les tâches avec **3 propriétés structurantes** pour filtrer/grouper facilement :

| Property | Valeurs |
|----------|---------|
| **Category** | Dev · Maison · Jeux · Infra · Ops · Achat |
| **Project** | chrysa-lib · dev-nexus · doc-gen · server · ai-aggregator · pre-commit-tools · satisfactory-factory-manager · game-solver-platform · chrysa-workstation · my-resume · travaux · domotique · notion · chrysa-master |
| **Type** | Bug · Feature · Tech-debt · Purchase · Admin · Research |

Vues suggérées à créer dans Notion :
- **Par domaine** (board grouped by Category)
- **Par projet actif** (board grouped by Project, filter Status ≠ Done)
- **Achats en attente** (filter Type=Purchase, sort Priority)
- **Tech debt critique** (filter Type=Tech-debt AND Priority∈{P0,P1})

## Tokens à générer (liens directs)

| Service | URL génération | Scopes / Notes |
|---------|----------------|----------------|
| Notion (intégration) | https://www.notion.so/my-integrations | Read + Update + Insert content · connecter à DB Ops Tasks |
| GitHub PAT | https://github.com/settings/tokens/new?scopes=repo,read:org,workflow&description=chrysa-mcp | repo · read:org · workflow |
| Claude API (Anthropic) | https://console.anthropic.com/settings/keys | Create key → chrysa-ai-aggregator |
| SonarCloud | https://sonarcloud.io/account/security | Generate Tokens |
| Sentry | https://sentry.io/settings/account/api/auth-tokens/ | project:read + event:read |
| Twitch (IGDB) | https://dev.twitch.tv/console/apps/create | Category: Game Integration · game-solver-platform |
| Steam API | https://steamcommunity.com/dev/apikey | Import trophées (V2 game-solver-platform) |
| Figma | https://www.figma.com/settings/account (onglet Personal access tokens) | file_read pour dev-nexus embed |
| OpenAI (fallback) | https://platform.openai.com/api-keys | Backup si Claude API down |
| Shelly Cloud | https://control.shelly.cloud (Settings → User settings → Authorization cloud key) | Domotique portail/volets |
| Tailscale | https://login.tailscale.com/admin/settings/keys | Reusable auth key server Kimsufi |

## Prochain run

```bash
# Session standard quotidienne
bash chrysa-master.sh --yes --parallel --retry=2

# Full run tout activé (prompt du token au démarrage)
bash chrysa-master.sh --yes --parallel --all-extras

# Stages individuels (token prompté si absent)
bash chrysa-master.sh --apply-notion --only=9
bash chrysa-master.sh --seed-backlog --only=10
bash chrysa-master.sh --bootstrap-projects --only=11
bash chrysa-master.sh --sched-cleanup --only=12
bash chrysa-master.sh --issue-83-patch --only=13
```
