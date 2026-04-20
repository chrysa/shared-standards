# Framework chrysa — observation + cadre opératoire

> État : proposition basée sur l'observation du portefeuille 2026-04-20
> Objectif : cadre reproductible solo dev qui encadre les 30+ repos et les écosystèmes (dev, travaux, jeux, aménagement)

---

## 1 · Observation — ce qui émerge de ton portefeuille

### Pattern 1 — Stack verrouillée (tu ne remets pas en question)
Python 3.14 · FastAPI · Pydantic v2 · SQLAlchemy 2 async · React 19 + Vite 6 + shadcn/ui + Tailwind · Postgres 16 · Redis 7 · Turborepo + pnpm · GitVersion · SonarCloud · Docker Compose (local-first, k3s en perspective). **C'est ton squelette.**

### Pattern 2 — Rôles explicites (règle 1+2)
Socle · Actif (max 2) · Opportuniste · Gelé · Vision. Protège du YAGNI massif.

### Pattern 3 — Outil-par-domaine
Tu as des "hubs" thématiques :
- **Dev** : chrysa-lib (auth/config/logging) · shared-standards · dev-nexus · doc-gen · ai-aggregator
- **Vie perso** : lifeos · my-fridge · coach · resume
- **Jeux** : D-D · PO-GO-DEX · satisfactory-automated_calculator · discordium (Vision)
- **Infra** : server · windows-autonome · agent-config
- **Automatisation** : notion-automation · drive-cleanup · ecosystem-reorg · skills
- **Travaux maison** : (pages Notion uniquement, pas de repo)

### Pattern 4 — Tu centralises par shared-standards, pas par copier-coller
`shared-standards/` héberge les templates, scripts, conventions. Chaque repo tire.

### Pattern 5 — Documentation par couches
- **`CLAUDE.md` global** (~/.claude/) : conventions transverses, ne bouge pas
- **`<repo>/CLAUDE.md`** : overrides locaux
- **`<repo>/DECISIONS.md`** : décisions D-XXXX locales
- **`<repo>/ROADMAP.md`** : Now/Next/Later local
- **Notion** : source vérité humaine (éditable), agrégation, diffusion externe

---

## 2 · Framework opératoire "Chrysa Flow"

### 2.1 · Pyramide des 4 couches

```
  ┌─────────────────────────────────────────┐
  │  Couche 4 · PROJETS (30+ repos)          │
  │  Actifs · Opportunistes · Socle           │
  ├─────────────────────────────────────────┤
  │  Couche 3 · FOUNDATIONS (Socle)          │
  │  chrysa-lib · server · shared-standards  │
  ├─────────────────────────────────────────┤
  │  Couche 2 · ÉCOSYSTÈME (outillage)       │
  │  CI/CD · dependabot · hooks · skills     │
  ├─────────────────────────────────────────┤
  │  Couche 1 · PLATEFORME (infra)           │
  │  Kimsufi · Tailscale · Docker · Nginx    │
  │  Monitoring (Prometheus+Grafana+Loki+Qdrant) │
  └─────────────────────────────────────────┘
```

**Règle** : on ne démarre jamais une couche au-dessus tant que celle du dessous n'est pas solide.

### 2.2 · Séquence actuelle (revue 2026-04-20) — SERVER P0 AVANT TOUT

#### Phase 0 — Stabiliser la plateforme (Couche 1) · NOW
**Bloquant absolu** : jusqu'à ce que tout ça soit en place, pas de reprise dev projets applicatifs.

- [ ] Kimsufi à jour · renouvellement + DNS OVH
- [ ] Docker Compose prod stable
- [ ] Nginx + Let's Encrypt
- [ ] Tailscale mesh opérationnel
- [ ] **Monitoring stack** : Prometheus + Grafana + Loki + Qdrant (D-0001 server)
- [ ] Sentry self-hosted opérationnel
- [ ] Backup DB quotidien

#### Phase 1 — Écosystème dev (Couche 2) · NEXT
- [ ] apply-standards.sh sur tous les repos Socle + Actifs
- [ ] Dependabot auto-merge activé (template shared-standards)
- [ ] Pre-commit hooks sur chaque repo
- [ ] CI qui passe sur chaque repo Actif
- [ ] Portfolio HTML généré (interne + public)

#### Phase 2 — Socles (Couche 3) · NEXT+1
- [ ] `chrysa-lib` Sprint 1 · @chrysa/auth 4 modes
- [ ] `chrysa-lib` @chrysa/config + @chrysa/logging
- [ ] `doc-gen` PR #1 mergée

#### Phase 3 — Reprise Actifs (Couche 4) · LATER
- [ ] dev-nexus V1 (avec auth)
- [ ] my-fridge V1 MVP
- [ ] lifeos V1 (avec visu Notion D-0003)
- [ ] ai-aggregator V0

#### Phase 4 — Opportunistes + Vision · quand règle 1+2 le permet
À ne démarrer que quand Phase 3 a libéré un slot Actif.

### 2.3 · Rituels hebdomadaires

| Rituel | Fréquence | Durée | Livrable |
|--------|-----------|-------|----------|
| **Daily briefing** (agent) | quotidien 08h | auto | Notion digest |
| **Push pending** | quotidien fin journée | 5 min | `fix-all.sh` → push actifs |
| **Sprint review** | lundi matin | 30 min | MAJ ROADMAP + portefeuille |
| **Portfolio regen** | lundi soir | auto | portfolio.html + -public.html |
| **Veille tech** | lundi soir auto | auto | agrégée Notion |
| **Health check** | dimanche soir | 15 min | Règle 1+2 respectée ? |
| **Mensuel hygiène** | 1er du mois | 1h | Issues ménagées, décisions archivées, Notion reclassé |

### 2.4 · Frontières claires (anti-dispersion)

Pour **chaque nouvelle idée** qui arrive :
1. **Quelle couche ?** (4 → OK nouveau repo · 3 → Socle, attention bloquant · 2 → shared-standards · 1 → server)
2. **Quel rôle ?** (règle 1+2 : pas d'Actif sans libérer un slot)
3. **Quel écosystème ?** (dev · vie perso · jeux · travaux · …)
4. **Notion créé immédiatement** (page DB Projets dès l'idée)
5. **PRD requis ?** (oui si Actif ou Opportuniste qui devient candidat Actif)

---

## 3 · Repriorisation concrète aujourd'hui

La matrice actuelle (portfolio-metadata.yml) avait `chrysa-lib = Socle P0` + 4 Actifs bloqués. **On reprioritise** :

| Repo | Ancienne priorité | Nouvelle priorité | Justification |
|------|-------------------|-------------------|---------------|
| `server` | Socle (non urgent) | **Socle P0 — bloquant** | Couche 1 plateforme, tout repose dessus |
| `chrysa-lib` | Socle P0 | **Socle P1** (après server) | Bloque couche 4, mais dépend de couche 1 stable |
| `shared-standards` | Socle | Actif outillage | Ne bloque pas (templates déjà utilisables) |
| `doc-gen` | Actif | Actif bloqué (attend server + chrysa-lib) | Ordre respecté |
| `dev-nexus`, `my-fridge`, `lifeos` | Actif | Actif en attente | idem |

### Action immédiate : éditer `portfolio-metadata.yml`

```yaml
server:
  role: Socle
  status: V1
  priority: P0  # ← ajouté
  valeur_plateforme: "Infra Kimsufi Docker+Nginx+Tailscale + monitoring local-first"
  bloqueurs:
    - "Stack Prometheus/Grafana/Loki/Qdrant à déployer (~4 Go RAM)"
    - "Backup DB quotidien à configurer"
    - "Tailscale auth keys à régénérer"
  budget_annuel_eur: { infra: 180, saas: 0, effort_h: 40 }
  public: false

chrysa-lib:
  role: Socle
  priority: P1  # ← ajouté (avant c'était P0)
  # ...
```

Je peux patcher ça dans le fichier maintenant.

---

## 4 · Parallélisation possible (ton point 10)

Même en solo dev, tu peux paralléliser **sans conflit** :

### Parallèles safes
- **Infra** (server) ↔ **doc-gen PR #1** : totalement indépendant, 2 branches/2 repos
- **DECISIONS.md d'un repo** ↔ **CI workflow d'un autre** : 0 interférence
- **Veille tech** (scheduled task) ↔ **coding actif** : l'agent tourne en background
- **Apply-standards --repo=X** ↔ **coding repo Y** : 2 repos disjoints

### Parallèles risqués
- Éviter 2 features sur le même repo en parallèle (rebase hell solo dev)
- Ne pas paralléliser Sprint 1 chrysa-lib + utilisation chrysa-lib ailleurs

### Pattern recommandé
**1 "feature de fond" (chrysa-lib ou server) + 1 "tâche outillage" légère (apply-standards, issues ménagées, veille, docs).** C'est jouable mentalement.

---

## 5 · Ouverture — nouveaux écosystèmes

En regardant ton mix actuel (dev + jeux + vie + travaux), le framework pourrait s'étendre vers :

- **Domotique** (si travaux + smart home) → nouveau hub `home-automation/` (Home Assistant + Zigbee2MQTT)
- **Apprentissages perso** → `learning-tracker/` avec lifeos intégration
- **Health & Fitness** → déjà amorcé dans `coach`
- **Finances perso** → rien encore, potentiel opportuniste

→ Tous auraient leur DB Notion dédiée + dossier repos + ROADMAP aggregée par écosystème.
