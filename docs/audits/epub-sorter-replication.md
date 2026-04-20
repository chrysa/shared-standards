# Audit epub-sorter → plan de réplication sur les 33 repos chrysa

- **Date** : 2026-04-19
- **Source** : `chrysa/epub-sorter`
- **Cible** : 33 repos chrysa (priorité ACTIFS + SOCLES + Centraux)

## Synthèse

`epub-sorter` est un petit projet Python (CLI + GUI) **exemplaire** car il applique la discipline d'automation-first sur une surface minimale. Les 33 repos chrysa gagnent à reprendre son squelette.

## Éléments exemplaires identifiés

### 1. Makefile épuré

Cibles uniques par domaine, help auto-généré via grep :

```
install, install-dev, install-pre-commit, run-gui, run-cli,
lint, format, pre-commit, clean
```

Différent de padam-av (14 fichiers `.Makefile` pour un gros Django). Pour un repo chrysa typique (lib ou petit service), le Makefile epub-sorter est la bonne dose.

### 2. `.pre-commit-config.yaml` minimal (11 hooks)

- pre-commit-hooks standards (trailing-space, file-fixer, yaml, toml)
- `chrysa/pre-commit-tools` personnalisé (python-print-detection, yaml-sorter)
- ruff + ruff-format

Note : version légère (vs. template shared-standards 68 hooks). Pour un repo petit, garder ce minimum et tirer le template complet uniquement pour les ACTIFS.

### 3. `.github/copilot-instructions.md` (3.4 KB)

- Section **Automation & Industrialization (NON-NEGOTIABLE)** : CI/CD, pre-commit, release auto obligatoires
- Références explicites aux templates (`Forge-Stack-Workshop/react-app-generator`, `base-makefile`)
- Seuils : 50 lignes fonction, 500 lignes fichier, complexité 10, zéro warnings

### 4. `.claude/` vendorisé

- 6 hooks : secret-scanner, circuit-breaker, verifiable-thresholds, frustration-detection, memory-consolidation, model-debt-inventory
- 3 skills : api-design, dockerfile-multistage, testing-pytest
- `settings.json` : autoCompact 0.85, effortLevel medium
- `secret-scanner-allowlist.json` + `thresholds.json` présents

### 5. `CLAUDE.md` contextuel

- Stack Python minimal + lien CI badge
- Règles Conventional Commits
- Documentation des skills locaux
- Référence à `chrysa/shared-standards`

### 6. Workflows CI légers

- `ci.yml` : pre-commit + ruff + Windows build PyInstaller
- `build-release.yaml` : release semver
- `sonar.yml` : SonarCloud
- Concurrence + cancel-in-progress

### 7. Particularité unique : **PyInstaller CI**

Génère `.exe` Windows en artifact. Pattern à reprendre pour les autres CLI packagés (ex. futurs outils chrysa-workstation, backup tools).

## Comparaison padam-av (gold standard client)

| Aspect            | epub-sorter    | padam-av             |
| ----------------- | -------------- | -------------------- |
| Makefiles         | 1 épuré        | 14 modulaires        |
| Pre-commit hooks  | 11             | 68                   |
| Workflows         | 3              | 33 (full-analysis)   |
| `.claude/` hooks  | 6              | 8 + commands + rules |
| Stack             | Python CLI+GUI | Django + 20 apps     |

Conclusion : **padam-av = gold standard pour ACTIFS production**, **epub-sorter = gold standard pour libs/petits services**. Les 2 cohabitent dans `shared-standards/templates/`.

## Plan de réplication

### Phase 1 — Templates manquants dans shared-standards (1 sprint)

Ajouter sous `shared-standards/templates/epub-minimal/` :

```
templates/epub-minimal/
├── Makefile                         # cibles simples
├── .pre-commit-config.yaml          # version 11 hooks
├── .github/
│   ├── copilot-instructions.md      # squelette
│   └── workflows/
│       ├── ci.yml
│       ├── build-release.yaml
│       └── sonar.yml
├── .claude/
│   ├── settings.json
│   ├── hooks/ (6 fichiers)
│   ├── skills/ (3 skills génériques)
│   ├── config/
│   │   ├── thresholds.json
│   │   └── secret-scanner-allowlist.json
└── CLAUDE.md                        # squelette
```

### Phase 2 — Script de propagation (1 h)

`shared-standards/scripts/apply-epub-minimal.sh` — copie le template dans un repo cible, diff avec existant, propose merge interactif :

```bash
./apply-epub-minimal.sh ~/chrysa/coaching-tracker --dry-run
./apply-epub-minimal.sh ~/chrysa/coaching-tracker --apply
```

### Phase 3 — Matrice repos / template

| Repo                    | Template cible | Priorité |
| ----------------------- | -------------- | -------- |
| chrysa-lib              | padam-av-like  | P0       |
| dev-nexus               | padam-av-like  | P0       |
| my-fridge (fridgeai)    | padam-av-like  | P0       |
| my-assistant (lifeos)   | padam-av-like  | P1       |
| coaching-tracker        | epub-minimal   | P1       |
| doc-gen                 | padam-av-like  | P1       |
| discord-bot-back        | epub-minimal   | P2       |
| DJango-CustomeCommands  | epub-minimal   | P2       |
| POGODEX, D-D            | epub-minimal   | P2       |
| epub-sorter             | **référence**  | —        |
| 24 autres (libs/outils) | epub-minimal   | P3       |

### Phase 4 — Audit continu (1x/mois)

Scheduled-task `monday-audit-combo` (déjà en place) lève une issue `standards-drift` si un repo ACTIF ne respecte plus le template. Épouse le plan.

## Actions immédiates (cette session)

1. Créer `shared-standards/templates/epub-minimal/` avec copie directe depuis `chrysa/epub-sorter/` (hors code source app)
2. Commit dans `shared-standards`
3. Documenter dans `shared-standards/README.md` quand utiliser `padam-av-full` vs `epub-minimal`

## Post-session

1. Tag `shared-standards v1.0.0` inclut les 2 templates
2. Sprint S2 : propagation P0 (chrysa-lib, dev-nexus, my-fridge)
3. Sprint S3 : propagation P1
4. Sprint S4+ : propagation P2-P3 en opportuniste
