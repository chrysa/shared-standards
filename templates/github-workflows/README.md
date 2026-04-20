# GitHub Workflows — templates chrysa

## Objectifs

1. **Rester sous les 2000 min CI/mois** du plan GitHub Free (repos privés)
2. **Automatiser** Dependabot (auto-merge si patch/minor + tests verts)
3. **Minimiser PRs ouvertes simultanées** (quota visuel + revue)

## Workflows fournis

| Fichier | Déclencheur | Impact budget CI |
|---------|-------------|------------------|
| `ci-python.yml` | push + PR | ~2-5 min/run |
| `ci-node.yml` | push + PR | ~2-4 min/run |
| `dependabot-auto-merge.yml` | PR dependabot | ~30 sec/run |
| `branch-auto-update.yml` | push sur main | ~20 sec/run |

## Patterns de réduction consommation

### 1. `concurrency` (gratuit, immédiat)
Ajouter en top de **chaque** workflow :
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### 2. `paths-ignore` vs `paths` (avec prudence)
Pour exclure les changes purement doc :
```yaml
on:
  push:
    paths-ignore:
      - '**.md'
      - 'docs/**'
```
⚠️ Piège connu : si utilisé sur un workflow release, voir issue #83 pre-commit-tools pour le contournement.

### 3. Matrix minimale
CI matrix `python-version: ["3.12", "3.14"]` = 2× runtime. Si acceptable, passer à single `["3.14"]` pour les feature branches et garder matrix complète uniquement sur `develop`/`main`.

### 4. Dependabot grouping
Le template `dependabot.yml` groupe les patch/minor → 1 PR au lieu de N, donc 1 run CI au lieu de N.

### 5. Cache agressif
```yaml
- uses: actions/setup-python@v5
  with:
    python-version: "3.14"
    cache: "pip"
```
Chaque cache hit épargne ~1-2 min par run.

## Application via `apply-standards.sh`

```bash
bash shared-standards/scripts/apply-standards.sh --repo=<repo>
# Applique dependabot.yml + workflows + pre-commit depuis templates
```

## Budget prévisionnel (estimation)

Pour 10 repos actifs, 4 semaines × 5 jours actifs :
- CI push/PR : ~3 min/run × 30 runs/sem/repo × 10 repos = **900 min/sem**
- Dependabot : 1 batch mensuel ~5 runs × 1 min = **5 min/mois**
- Auto-merge : trivial, <30 sec/PR

**Total estimé mensuel** : ~3600 min pour 10 repos actifs → **au-dessus de 2000 min free tier**.

### Leviers pour rester sous 2000 min/mois
1. Limiter repos avec CI à 5-6 (pas les 30) → Socle + Actifs uniquement
2. Désactiver CI sur repos Gelés (déjà archivé → workflow disabled)
3. Skip CI sur doc-only changes (paths-ignore bien configuré)
4. Matrix Python 3.14 uniquement sur main/develop, pas sur feature
5. Dependabot monthly au lieu de weekly pour projets stables

Avec ces leviers : ~1500-1800 min/mois → **OK free tier**.

## À faire ensuite

- [ ] Activer `branch-auto-update.yml` sur les repos actifs (1 seule fois)
- [ ] Ajouter `concurrency` snippet au top des 30 workflows existants (grep + patch)
- [ ] Monitorer conso : `gh api /orgs/chrysa/settings/billing/actions` (à configurer en tâche planifiée si souhaité)
