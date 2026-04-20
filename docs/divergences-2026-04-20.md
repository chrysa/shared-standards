# Divergences convo ↔ Notion — audit 2026-04-20

> Relecture intégrale session 2026-04-20 + recherche Notion ciblée.
> Objectif : identifier les incohérences, doublons, manques.

---

## 1 · Doublons Notion (à consolider)

### 1.1 · Pages audit/session redondantes

Plusieurs pages audit pour la **même période 19-20 avril** :

| Page Notion | ID | Statut proposé |
|---|---|---|
| 🔍 Audit session 2026-04-19 | `34759293-e35e-8145-904a-f5a0003d947e` | KEEP (synthèse) |
| ✅ Décisions appliquées session 2026-04-19 | `34759293-e35e-8196-b3ce-fd29f16cda70` | ARCHIVE (fusionner dans Audit session) |
| 📋 Audit structure Notion 2026-04-19 | `34759293-e35e-81a5-8f58-c33b2568a333` | KEEP (spécialisé Notion) |
| 🔍 Veille XDA + HowToGeek — actionnable pour chrysa (2026-04-19) | `34759293-e35e-81d5-a179-ec31fb9c9460` | KEEP (source veille) |
| chrysa docs sync — audit 2026-04-19 | `34759293-e35e-81f0-b239-e2dcc57d8ee5` | ARCHIVE (obsolète, migration DECISIONS faite) |
| Repo Config Normalization — chrysa ecosystem 2026-04-19 | `34759293-e35e-81dc-ab84-f4619e5fd2d0` | ARCHIVE (remplacé par apply-standards.sh) |
| 🧹 Vider Corbeille Phase 0 (11+ pages doublons) | `34759293-e35e-81c9-857c-cc06860a9973` | EXECUTE (action manuelle à faire dans Notion) |

### 1.2 · Pages `[github-state-sync] FAILED` — bruit

Pages générées automatiquement par un scheduled task :
- `34859293-e35e-81da-b02b-cae0ad771190` (2026-04-20 12:00)
- `34759293-e35e-8110-a994-e9f30f096f22` (2026-04-19T10:04Z)

→ **Action** : corriger le scheduled task `github-state-sync` (gh auth) OU le désactiver temporairement. Ces pages repollueront Notion tant que le fix n'est pas fait.

### 1.3 · Pages `Configuration Claude Desktop` × 2

- `34659293-e35e-812d-866d-c3d8fa1ad3d2` · « Configuration Claude Desktop — référence »
- `34659293-e35e-818d-a9d7-e12b16e6d3e8` · « Configuration Claude Desktop — source de vérité »

→ Deux titres différents, probablement même sujet. **Action** : garder "source de vérité", archiver "référence".

### 1.4 · Pages `Sync Notion ↔ GitHub Issues` × 2

- `34359293-e35e-810f-92ff-e3d5c25d9d6d`
- `34359293-e35e-815a-9c6f-c31d14104ded`

→ **Action** : dédupliquer, garder la plus récente.

---

## 2 · Divergences contenu (Notion a plus d'info que mes fichiers, ou l'inverse)

### 2.1 · Projets absents de `portfolio-metadata.yml`

Pages Notion visibles, non listées dans mon metadata :

- **FabForge** — "📐 FabForge — GDD complet" (page `34859293-e35e-8171-bb39-f50d9216a31c`) → projet jeu/build, à ajouter
- **Glossaire mécaniques jeu** — `34759293-e35e-810a-9d7c-fe8a6edbf61e` → probablement référence transverse jeux, pas un repo mais une page
- **DEV Nexus SaaS AI Extension** — `34759293-e35e-814c-b970-d6133715a7cf` → scope V2 de DEV Nexus déjà documenté côté Notion mais pas reflet dans metadata
- **KPIs consommation outils externes** — `34759293-e35e-81ea-93e9-d7656aadbcc4` → doit être lié à budget `portfolio-metadata.yml`
- **Guardrails — DevSecOps + LLM** — `34759293-e35e-81a1-96b5-ce56b4f17fc2` → ADR-0016 existant côté disque, à aligner
- **Tools additionnels DEV Nexus — priorisation** — `34759293-e35e-81ff-bd55-c07581a55bb2` → extension roadmap dev-nexus

### 2.2 · Scheduled tasks — catalogue Notion ≠ CLAUDE.md global

Page Notion : **📋 Documentation — Agents & Tâches Schedulées** (`34359293-e35e-8120-aa75-ccd4f6bdb8ce`)
Page Notion : **🤖 Agent Scheduler — Catalogue complet** (`34359293-e35e-8178-b9cf-dc38b41f500a`)

CLAUDE.md global liste 7 scheduled tasks · Notion en aurait d'autres (dep-audit hebdo, github-state-sync, rapport santé semaine 16). **Action** : cross-check + MAJ CLAUDE.md.

### 2.3 · Rapport santé Semaine 16

Page `34759293-e35e-8148-8a8d-c296794bc399` · "📋 Rapport santé — Semaine 16 (19/04/2026)"

→ Vue synthétique du portefeuille, à cross-check avec `portfolio.html` généré cette session. **Action** : unifier les 2 vues ou choisir une source vérité.

### 2.4 · "Carte projets + interdépendances"

Page `34759293-e35e-819c-a393-cafc21a8eb15`

→ Doublon potentiel avec ma page « 🔗 Cross-project dependencies » (`34859293-e35e-81a0-878e-ec63c159e873`) créée aujourd'hui. **Action** : comparer les deux, garder la plus récente + plus complète (ma nouvelle) et archiver l'ancienne.

---

## 3 · Manques Notion (contenu de la session non remonté)

| Contenu session | Emplacement disque | Action Notion |
|---|---|---|
| Framework 4 couches | `shared-standards/docs/FRAMEWORK-chrysa.md` | ✅ déjà créé en Notion (page `34859293-e35e-8181-9a9e-f4a1bea9730f`) |
| Veille sources catégorisées | `shared-standards/docs/veille-sources.md` | MANQUE — à créer page "Veille sources 2026-04-20" |
| Ideas not in Notion | `shared-standards/docs/ideas-not-in-notion-2026-04-20.md` | Lui-même référence les manques à remonter |
| Convention DECISIONS.md par repo | `shared-standards/docs/DECISIONS-MIGRATION-MAP.md` | MANQUE — page Wiki Engineering à créer |
| Issue #83 diagnostic | `pre-commit-tools/ISSUE-83-DIAGNOSTIC.md` | MANQUE — à remonter dans issue comment + page Wiki |
| Hooks validate-prompt + dev-run | `shared-standards/scripts/README-hooks.md` | MANQUE — page Wiki Engineering |

---

## 4 · Contradictions directes

### 4.1 · Priorités portfolio-metadata.yml (patché cette session)

Convo : **server = P0 Couche 1** (nouvelle priorisation 2026-04-20).
Notion : page "Rapport santé Semaine 16" peut encore référencer `chrysa-lib = P0`.
→ **Action** : MAJ rapport hebdo + règle 1+2 vérifiée.

### 4.2 · ADR-0014 révoqué

Convo : ADR-0014 → révoqué par ADR-0026 (fusion chrysa-workstation annulée).
Notion : page [MIGRÉ 2026-04-20] ADR-0026 ✅ OK
Mais : CLAUDE.md global référence encore chrysa-workstation dans plusieurs lignes → à auditer.

### 4.3 · Règle « issue ↔ PR »

Convo : nouvelle règle (point 3 de cette requête).
Notion : pas de règle explicite formulée. CLAUDE.md global : "1 PR par issue" (implicite).
→ **Action** : formaliser dans CLAUDE.md + template PR.

---

## 5 · Synthèse actions manuelles Notion

1. Exécuter "🧹 Vider Corbeille Phase 0" (action explicite déjà présente dans Notion)
2. Archiver pages doublons section 1.1 (6 pages)
3. Dédupliquer Config Claude Desktop + Sync Notion↔GH
4. Fixer ou désactiver scheduled task `github-state-sync`
5. Créer page "Veille sources 2026-04-20" (Wiki Engineering)
6. Créer page "Convention DECISIONS.md par repo" (Wiki Engineering)
7. Ajouter FabForge + mises à jour DEV Nexus V2 dans DB Projets
8. Vérifier catalogue scheduled tasks Notion vs CLAUDE.md global
