---
fka_managed: true
source: notion
notion_id: 36859293-e35e-81fe-b63f-f4a487a28ed3
notion_url: https://app.notion.com/p/tudes-shared-standards-36859293e35e81feb63ff4a487a28ed3
notion_last_edited_time: 2026-06-05T20:17:00.000Z
---
# Études — shared-standards

<table_of_contents/>
> 📑 Études projet · type **OSS** · obligatoires : Faisabilité + Technique (toutes deux 🟢 Done). Marché / Pertinence / Financière = N/A.
## 🔬 Étude de faisabilité
**Statut : 🟢 Done** · Verdict : 🟢 Go
**Question** : peut-on centraliser toutes les conventions chrysa (CI/CD, linters, labels, bootstrap) dans une source unique propagée à tous les repos ?
**Réponse** : oui, prouvé en production — déployé sur 32 repos actifs. Les reusable workflows GitHub Actions permettent la propagation centralisée sans duplication. guideline-checker valide la conformité.
## ⚙️ Étude technique
**Statut : 🟢 Done** · Verdict : 🟢 Go
**Stack retenue** : Python 3.14 (CLI + scripts) · GitHub Actions reusable workflows · shell scripts · pre-commit framework · SemVer GitVersion + git-cliff.
**Architecture** : `packages/project-init` (bootstrapper, ADR-0013) · `templates/` · `workflows/` · `guidelines/` · `scripts/` (guideline-checker).
**Point de vigilance critique** : toute mise à jour de workflow impacte 32+ repos simultanément → casser un workflow = cascade d'échecs CI. Tests requis avant tout tag.
## 📊 Marché · 🎯 Pertinence · 💰 Financière
**Statut : 🔘 N/A** — OSS pur, usage interne/perso.
