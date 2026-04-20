# ROADMAP — SAT v2 (satisfactory-factory-manager)

> Gestion d'usine Satisfactory · import save · layout 3D · optimizer · blueprints.

## Now (Q2 2026)

- [ ] Rename repo `satisfactory-automated_calculator` → `satisfactory-factory-manager`
- [ ] Update 20+ liens internes + CI badges
- [ ] Rédiger PRD SAT v2 (D-0021 scope)
- [ ] Parser save binaire .sav (POC Python `ficsit-save-parser`)

## Next (Q3 2026)

- [ ] Layout planner 2D (MVP avant 3D)
- [ ] Optimizer chaînes production enrichi (alternatives recipes + purete gisements)
- [ ] UI React 19 + Vite (remplace CLI Python)

## Later (Q4 2026+)

- [ ] Layout planner 3D avec Three.js
- [ ] Blueprints library (partage format SCIM)
- [ ] API REST `/api/v1/blueprints/{import,export}` pour game-solver-platform
- [ ] Import auto depuis save (mapping bâtiments → chaînes)

## Metrics de succès

- Parser save binaire fonctionnel sur 95% des saves recentes
- Optimizer produit chaînes au moins aussi efficientes que planner communautaire Satisfactory-Calculator.com
- 3+ joueurs amis utilisant blueprints library au lancement
