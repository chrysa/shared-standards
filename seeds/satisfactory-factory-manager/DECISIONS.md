# DECISIONS — satisfactory-automated_calculator (SAT v2)

> Décisions locales au repo. Numérotation D-XXXX locale.
> Conventions transverses : voir `~/.claude/CLAUDE.md`.

---

## D-0001 · Historique : calculateur Satisfactory simple

**Date** : origine (2024)
**Statut** : Obsolète (remplacé par D-0020)
**Contexte** : Projet initial = calculateur de chaînes de production Satisfactory, CLI Python.
**Décision** : Outil monofonction.

---

## D-0020 · Split SAT v2 — scope Satisfactory-only

**Date** : 2026-04-20
**Statut** : Acté
**Contexte** : L'ambition "SAT v2 multi-jeu" s'étendait à bien plus que le calcul de chaînes — puzzles, énigmes, trophées, leaderboard social. Garder tout dans ce repo violerait la règle "un projet = une valeur plateforme claire".

**Décision** :
1. Ce repo reste scopé **Satisfactory uniquement** sous le nom `satisfactory-factory-manager` (rename prévu).
2. Le scope multi-jeux / game solver / leaderboard social part dans un nouveau repo `chrysa/game-solver-platform`.
3. SAT v2 expose une API REST `/api/v1/blueprints/{import,export}` consommée par game-solver-platform pour les features Satisfactory.

**Conséquences** :
- Rename repo : à planifier (gh renames + update 20+ liens internes)
- README et ROADMAP à réécrire avec scope réduit/précisé
- Effort budget passe de 30h → 60h (features V2 plus ambitieuses : import save binaire, layout planner, optimizer)
- Bloqueur "Extension multi-jeu PRD" → supprimé (délégué)

**Alternative rejetée** : monorepo Turborepo — écartée (D-0001 game-solver-platform).

---

## D-0021 · SAT v2 — Scope Satisfactory-only précisé

**Date** : 2026-04-20
**Statut** : Proposé
**Contexte** : Après D-0020, il faut définir ce que SAT v2 couvre.

**Décision** : V2 = 5 features majeures :
1. **Import save Satisfactory** — parser format binaire .sav
2. **Layout planner 3D** — placer bâtiments sur grille, prévisualiser usines
3. **Production chains optimizer** — reprise du calculateur existant, enrichi (alternatives, purete gisements)
4. **Blueprints library** — partage import/export format SCIM entre joueurs
5. **API REST** pour intégration externe (game-solver-platform)

**Conséquences** : stack frontend React 19 + Three.js (layout 3D) · backend FastAPI pour parsing + API · PostgreSQL pour blueprints partagés. Budget 60h effort.
