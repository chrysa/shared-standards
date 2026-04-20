# Issues audit — 2026-04-20

> Généré par audit-github-issues.sh

## Par repo (issues ouvertes, triées par nombre)

| Repo | Ouvertes | Stale (>180j) | Labels top-3 |
|------|----------|---------------|--------------|
| ai-aggregator | 4 | 0 | enhancement(3) · documentation(1) · research(1) |
| coach | 3 | 0 |  |
| container-webview | 1 | 0 | documentation(1) · research(1) |
| D-D | 1 | 0 | question(1) · architecture(1) |
| dev-nexus | 12 | 0 | v2+(11) · enhancement(9) · documentation(2) |
| discord-bot-back | 1 | 0 | documentation(1) · research(1) |
| diy-stream-deck | 11 | 0 | enhancement(10) · documentation(3) |
| genealogy-validator | 8 | 0 | architecture(6) · documentation(5) · enhancement(2) |
| github-actions | 1 | 0 | enhancement(1) · chore(1) |
| my-fridge | 4 | 0 | enhancement(2) · bug(1) · documentation(1) |
| notion-automation | 7 | 0 | chore(3) · automation(2) · ci(2) |
| pre-commit-tools | 1 | 0 | bug(1) |
| project-init | 10 | 0 | enhancement(2) |
| satisfactory-automated_calculator | 10 | 0 | enhancement(7) · documentation(2) · architecture(2) |
| server | 21 | 0 | M1-Foundation(6) · M4-DevTooling(4) · M3-Security(4) |
| shared-standards | 4 | 0 |  |

## Totaux

- **Total issues ouvertes** : 99
- **Total stale (>180j)** : 0

## Recommandations

1. **Ne pas créer de nouvelles issues** sauf pour cross-project deps (cf. cross-project-issues.sh)
2. **Fermer les stale** : `bash audit-github-issues.sh --close-old` (avec `--dry-run` pour preview)
3. **Dédupliquer** : rechercher titres similaires sur les repos avec >10 issues
4. **Prioriser P0/P1** : ajouter labels `priority/p0` `priority/p1` pour les issues actionnables

## Workflow de ménage mensuel

- Jour 1 du mois : audit (ce script)
- Jour 2 : fermer stale (`--close-old` après validation dry-run)
- Jour 3 : dédupliquer + prioriser manuellement les top-3 repos avec plus d'issues
- Fin du mois : revue portfolio-metadata.yml pour ajuster bloqueurs
