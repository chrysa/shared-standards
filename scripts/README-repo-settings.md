# Standardisation settings GitHub · chrysa portfolio

**Script** · `standardize-repo-settings.sh`
**Date** · 2026-04-19
**Source de vérité** · shared-standards (ADR-0013)

---

## Ce que le script applique

### Tous les repos (public ET privé)

| Setting | Valeur | Raison |
|---|---|---|
| `has_wiki` | `true` | Wiki activé |
| `has_issues` | `true` | Issues activées |
| `allow_merge_commit` | `true` | Merge commit autorisé |
| `merge_commit_title` | `PR_TITLE` | Titre merge commit = titre PR |
| `merge_commit_message` | `PR_BODY` | Body merge commit = description PR |
| `allow_squash_merge` | `true` | Squash merge autorisé (méthode préférée chrysa) |
| `squash_merge_commit_title` | `PR_TITLE` | Titre squash = titre PR |
| `squash_merge_commit_message` | `PR_BODY` | Body squash = description PR |
| `allow_rebase_merge` | `false` | Pas de rebase merge (choix chrysa) |
| `allow_update_branch` | `true` | Suggère update PR branch |
| `allow_auto_merge` | `true` | Auto-merge activé |
| `delete_branch_on_merge` | `true` | Suppression auto des branches après merge |
| `web_commit_signoff_required` | `false` | Pas de signature obligatoire via web UI |

### Repos PUBLIC uniquement (open source)

| Setting | Valeur | Raison |
|---|---|---|
| `allow_forking` | `true` | Fork autorisé |
| `has_discussions` | `true` | Discussions activées |
| Sponsoring | Signalé | Nécessite `.github/FUNDING.yml` manuel (template fourni) |

### Branch protection (master · main · develop)

| Règle | Valeur |
|---|---|
| Required approving reviews | 1 |
| Dismiss stale reviews on new commits | ✅ |
| Require conversation resolution | ✅ |
| Allow force push | ❌ |
| Allow branch deletion | ❌ |
| Enforce admins | ❌ (permet override exceptionnel) |
| Required status checks | ❌ (laissé libre, à customiser par repo) |

**Note** · le script tente de protéger `master`, `main` **et** `develop`. Si une branche n'existe pas, skip silencieux.

### Commentaires sur commits individuels

Toujours activé par défaut sur GitHub — pas besoin de le configurer explicitement. Le script n'ajoute pas cette config (redondante).

### Everyone can open pull request

**Public repos** · activé par défaut (fork + PR accessible à tous).
**Private repos** · activé automatiquement pour les membres du repo (via les droits d'accès). Pas de config API supplémentaire nécessaire.

---

## Usage

### Un repo
```bash
cd /chemin/vers/shared-standards
./scripts/standardize-repo-settings.sh chrysa/dev-nexus
```

### Plusieurs repos
```bash
./scripts/standardize-repo-settings.sh chrysa/dev-nexus chrysa/fridgeai chrysa/doc-gen
```

### Tous les repos du org chrysa
```bash
./scripts/standardize-repo-settings.sh --all
```

### Mode dry-run (affiche sans appliquer)
```bash
./scripts/standardize-repo-settings.sh --all --dry-run
```

---

## Prérequis

- `gh` CLI installé et authentifié · `gh auth status`
- Permissions · admin sur chaque repo cible (pour branch protection + settings)
- `jq` installé

---

## Recurring sync recommandé

Une fois appliqué en one-shot, 2 options pour maintenir la cohérence ·

### Option A · Hook pre-push (local)

Ajouter à `.git/hooks/pre-push` ou via pre-commit ·

```yaml
# .pre-commit-config.yaml (dans chaque repo)
- repo: local
  hooks:
    - id: check-repo-settings
      name: Check repo settings drift
      entry: bash -c 'cd shared-standards && ./scripts/check-repo-settings-drift.sh'
      language: system
      pass_filenames: false
      stages: [pre-push]
```

### Option B · GitHub Action scheduled (recommandé)

Créer dans shared-standards · `.github/workflows/repo-settings-sync.yml` ·

```yaml
name: Repo settings sync
on:
  schedule:
    - cron: '0 3 * * 1'  # Lundi 3h
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Apply standard settings to all chrysa repos
        env:
          GH_TOKEN: ${{ secrets.CHRYSA_BOT_TOKEN }}
        run: ./scripts/standardize-repo-settings.sh --all
```

---

## Prochaines étapes

1. **Tester en dry-run** · `./scripts/standardize-repo-settings.sh chrysa/dev-nexus --dry-run`
2. **Appliquer sur 1 repo test** · `./scripts/standardize-repo-settings.sh chrysa/dev-nexus`
3. **Valider le résultat** sur GitHub UI · settings corrects
4. **Rollout batch** · `./scripts/standardize-repo-settings.sh --all`
5. **Option B** · déployer le workflow scheduled pour éviter la dérive future
6. **Pour chaque repo public** · créer `.github/FUNDING.yml` manuellement à partir du template `templates/FUNDING.yml`

---

## Ce que le script ne fait PAS (décisions chrysa)

- **Pas de `required_status_checks`** appliqué par défaut · chaque repo customise ses checks requis (CI Python vs Node vs TS diffèrent).
- **Pas de rebase merge activé** · choix portfolio = squash-only + merge commit optionnel.
- **Pas de suppression de branche distante automatique via script** · `delete_branch_on_merge` est l'équivalent côté GitHub, s'applique au merge uniquement.
- **Pas de `require_code_owner_reviews`** · pas de CODEOWNERS généralisé dans chrysa.
- **FUNDING.yml non auto-créé** · le script ne peut pas deviner quelles plateformes tu utilises (GitHub Sponsors · Patreon · etc.).

---

## Troubleshooting

| Erreur | Cause | Fix |
|---|---|---|
| `gh: not authenticated` | token manquant | `gh auth login` |
| `403 Forbidden` sur PATCH | pas admin du repo | vérifier droits org |
| `404 Not Found` sur branch protection | branche n'existe pas | normal, skip silencieux |
| `422 Unprocessable Entity` sur has_discussions | discussions non éligibles (compte perso gratuit ?) | option public uniquement, vérifier repo public |
| Settings ne s'appliquent pas sur repo fork | GitHub restreint certaines options sur forks | migrer vers repo non-fork |
