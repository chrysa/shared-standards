# Scheduled tasks — self-update pattern (convention chrysa)

> Version : 1.0 · 2026-04-19
> Applique à : toutes les scheduled tasks Claude Cowork (`~/Documents/Claude/Scheduled/<task-id>/SKILL.md`)
> Statut : convention — à suivre pour toute nouvelle task qui modifie un état Notion ou GitHub

## Pourquoi

Sans discipline, une scheduled task qui tourne à cadence fixe produit 3 types d'écarts :

1. **Drift** : un item a changé dans la source (GitHub/Notion) depuis le dernier run → pas détecté
2. **Stale** : un item créé par la task précédente n'a plus de correspondance dans la source → pas nettoyé
3. **Duplicate** : la task re-crée un item existant parce qu'elle ne regarde pas son propre historique

Résultat : l'output de la task diverge de la réalité au fil des runs. Entropy-maker.

La convention **self-update** corrige ces 3 failure modes en 3 étapes : **snapshot pré-run → diff → reconcile**.

## Pattern

```text
┌──────────────────────────────────────────────────────────────┐
│  Execution d'une task self-updating                          │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Charger le snapshot POST du run précédent                │
│     /tmp/<task-id>-post-<previous_ts>.json                   │
│                                                              │
│  2. Collecter l'état actuel des sources (GitHub/Notion/...)  │
│                                                              │
│  3. Calculer le diff avec le snapshot précédent :            │
│     - ADDED   : nouveaux items dans la source                │
│     - MODIFIED: items qui ont changé (status, labels, …)     │
│     - DISAPPEARED: items absents de la source mais dans      │
│       le snapshot → candidats archivage                      │
│                                                              │
│  4. Reconciler l'output (Notion/fichier/DB) :                │
│     - Créer les ADDED                                        │
│     - Mettre à jour les MODIFIED                             │
│     - Marquer les DISAPPEARED comme "Closed/Stale"           │
│       (JAMAIS supprimer sans vérification)                   │
│                                                              │
│  5. Snapshot POST du run courant                             │
│     /tmp/<task-id>-post-<current_ts>.json                    │
│                                                              │
│  6. Report dans Notion Ops Tasks (silent si 0 changement)    │
└──────────────────────────────────────────────────────────────┘
```

## Règles d'or

1. **Toujours lire le snapshot précédent avant d'agir** — si absent, traiter tous les items comme ADDED (bootstrap). Ne pas paniquer.
2. **Jamais supprimer** sans vérifier la disparition dans 2 runs consécutifs. Préférer `Statut = Closed/Stale`.
3. **Idempotent** : 2 runs consécutifs sur un state identique → 0 modification.
4. **Rate limit aware** : si la source a un rate limit, pauser entre items (ex : 100 ms entre repos GitHub).
5. **withErrorHandling** : wrap tout dans try/except. En cas d'échec → `gh issue create --label claude-error,scheduled-task`.
6. **Silent if nothing changed** : ne poster dans Ops Tasks que si ≥ 1 changement. Évite le spam.

## Structure snapshot standard

```json
{
  "task_id": "github-state-sync",
  "run_timestamp": "2026-04-19T12:00:00+02:00",
  "sources": {
    "github": {
      "chrysa/dev-nexus": {
        "prs": [
          {"number": 42, "title": "…", "updated_at": "…", "state": "open"}
        ],
        "issues": [ ... ],
        "milestones": [ ... ]
      }
    }
  },
  "notion_state": {
    "dashboard_page_id": "34659293-...",
    "last_refresh": "2026-04-19T12:00:15+02:00",
    "items_touched": {
      "created": ["pr-chrysa/dev-nexus-43"],
      "modified": ["pr-chrysa/dev-nexus-42"],
      "archived": ["issue-chrysa/doc-gen-17"]
    }
  },
  "metrics": {
    "duration_ms": 18420,
    "github_api_calls": 34,
    "notion_api_calls": 12,
    "errors": []
  }
}
```

## Exemple prompt (template)

```markdown
Tu es l'agent `<task-id>`. Tu tournes selon le cron `<cron>`.

# Règle d'exclusion (à personnaliser)
[Liste repos/projets/entités à exclure explicitement]

# Sources
1. <source 1> avec ses endpoints
2. <source 2> avec ses endpoints
3. Cible Notion / DB / fichier

# Ordre d'exécution (self-update pattern chrysa v1.0)
1. **Snapshot pré-run** — lire `/tmp/<task-id>-post-<previous_ts>.json` si existe
2. **Collecte** — fetch l'état actuel des sources
3. **Diff** — ADDED / MODIFIED / DISAPPEARED vs snapshot précédent
4. **Self-reconciliation** :
   - Créer les ADDED
   - Mettre à jour les MODIFIED
   - Marquer les DISAPPEARED comme Closed/Stale (jamais supprimer)
   - Détecter les items ajoutés par la task elle-même précédemment (audit trail)
5. **Snapshot post-run** — sauver `/tmp/<task-id>-post-<current_ts>.json`
6. **Report** — Ops Tasks entry avec compteurs add/modify/archive (silent si 0)

# Règles comportementales
- Silent si 0 changement
- Rate limit aware (pauser 100 ms entre items)
- Idempotent
- Jamais supprimer sans vérification 2 runs
- withErrorHandling → issue GitHub sur échec

# Sortie attendue
1. Snapshot JSON dans /tmp/
2. Entry Ops Tasks avec summary
3. Exit non-zero si erreur (+ issue GitHub)
```

## Tasks actuelles concernées (avril 2026)

| Task ID | Pattern appliqué ? | Priorité upgrade |
|---|---|---|
| `github-state-sync` | ✅ Appliqué 2026-04-19 | — |
| `notion-restructuration-migration` | ❌ À upgrader | 🟠 Haute |
| `docs-sync-all` | ⚠️ Partiel (git diff only) | 🟡 Moyenne |
| `monday-audit-combo` | ❌ À upgrader | 🟡 Moyenne |
| `external-catalogs-sync` | ❌ À upgrader | 🟢 Faible (intake-only) |
| `relaxation-weekly-recap` | ❌ À upgrader | 🟢 Faible (nouveau) |
| `gamification-xp-engine` | ❌ À upgrader | 🟡 Moyenne |
| `daily-briefing-chrysa` | N/A (read-only) | — |
| `repo-health-weekdays` | ⚠️ Partiel | 🟡 Moyenne |
| `sprint-auto-close` | ❌ À upgrader | 🟠 Haute |
| `library-weekly-digest` | ❌ À upgrader | 🟢 Faible |
| `lifeos-*` (5 tasks) | ❌ À upgrader | 🟡 Moyenne |

## Upgrade procedure (checklist par task)

1. [ ] Lire le prompt actuel de la task (`update_scheduled_task` ou fichier SKILL.md)
2. [ ] Identifier la structure de son output (Notion pages, fichiers, etc.)
3. [ ] Définir ce qui constitue un "item" (PR, issue, habit, session, ...)
4. [ ] Ajouter les 6 étapes self-update dans le prompt
5. [ ] Ajouter la règle `silent si 0 changement`
6. [ ] Wrap dans `withErrorHandling`
7. [ ] Run manuellement 2 fois consécutives pour vérifier idempotence
8. [ ] Monitorer le premier vrai run (via notification)

## Anti-patterns à éviter

- ❌ `supprimer item si absent de la source` → risque perte data
- ❌ `re-créer items à chaque run` → duplicates + API spam
- ❌ `ignorer les MODIFIED` → drift silencieux
- ❌ `sauvegarder snapshot dans le repo git` → leak secrets/tokens
- ❌ `faire le snapshot avant la collecte` → ne capture pas le vrai état post-run

## Anti-patterns autorisés (documentés)

- ✅ Skipper le snapshot en mode dry-run (flag `--dry-run`)
- ✅ Forcer un full-resync (`--force-rebuild`) — efface snapshot et reconstruit from scratch
- ✅ Limiter la rétention du snapshot à 30 jours (purge /tmp)

## Liens

- Pattern appliqué concrètement dans [github-state-sync](../scheduled-tasks/github-state-sync-pattern.md) (à créer)
- withErrorHandling : voir CLAUDE.md global § Error handling
- Rate limits : voir DEV Nexus spec `EXTERNAL_TOOLS_KPIS_SPEC_2026-04-19.md`
