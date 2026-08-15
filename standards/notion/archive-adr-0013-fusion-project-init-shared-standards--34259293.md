---
fka_managed: true
source: notion
notion_id: 34259293-e35e-8143-8e2e-d2cd11f446c8
notion_url: https://app.notion.com/p/Archive-ADR-0013-fusion-project-init-shared-standards-34259293e35e81438e2ed2cd11f446c8
notion_last_edited_time: 2026-07-31T12:59:00.000Z
---
# Archive — ADR-0013 fusion project-init → shared-standards

<callout icon="🗄️" color="gray_bg">
	**Tâche archivée — décision supersédée le 29 juillet 2026.** La fusion physique est annulée. `project-init` reste autonome et applique les standards de `shared-standards` par contrat versionné. Les critères ci-dessous sont conservés uniquement comme historique de l’ancienne option.
</callout>
## Critères d’acceptation
- [ ] Historique et éléments utiles du repo autonome inventoriés.
- [ ] Code utile déplacé dans `shared-standards/packages/project-init`.
- [ ] Tests du package exécutés depuis le monorepo `shared-standards`.
- [ ] Templates consommés depuis une seule source canonique.
- [ ] Le repo autonome ne reçoit plus de développement fonctionnel.
- [ ] Redirections, documentation et stratégie de release mises à jour.
- [ ] Un projet pilote est créé ou rénové avec le package fusionné et passe sa CI au premier commit.
