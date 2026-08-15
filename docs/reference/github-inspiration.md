# Deep-dive technique — `chrysa/shared-standards`

**Repo local :** `/home/anthony/Documents/perso/projects/chrysa/shared-standards`
**Licence du repo :** MIT
**But (1 phrase) :** Monorepo de standards partagés de l'écosystème chrysa — instructions GitHub Copilot, hooks Claude Code (DevEx), templates de workflows CI/CD "copy-to-use", quality gates, scan PII (Presidio) et scripts de distribution/audit de conformité vers ~70 repos.

## Nature du projet & choix des références

C'est un **repo interne de gouvernance/DevEx** (config-as-code + distribution de standards), pas une lib produit. Il n'a pas d'équivalent OSS 1:1, mais chaque **brique** a un projet de référence externe mûr :

- Distribution/enforcement de standards multi-repos → **super-linter**, **Backstage** (scaffolder/soundcheck).
- Hooks write-time / pré-commit → **pre-commit**.
- Bibliothèque d'instructions Copilot/skills → **awesome-copilot**.
- Scan PII/GDPR → **microsoft/presidio** (déjà une dépendance — sert de validation d'architecture).

5 références retenues (pas de forçage à 10). Toutes **permissives (MIT/Apache-2.0)** → copiables. Aucune source copyleft/restrictive.

---

## super-linter/super-linter
- **owner/repo :** super-linter/super-linter · ~10.5k ⭐ · actif (5 441 commits, 19 PR ouvertes) · **MIT** (permissive → copiable) · langage Shell
- **Fichier/module du pattern :** conteneur agrégateur + `.github/linters/` (config par langage) ; parallélisation des linters (depuis v6) ; principe « lean codebase » = orchestrer des outils existants plutôt que réimplémenter.
- **Mécanisme réel :** un seul point d'entrée (GitHub Action ou Docker standalone) détecte les fichiers changés et dispatche vers 50+ linters, chacun lisant sa config depuis un dossier centralisé, avec exécution parallèle et auto-fix optionnel.
- **Snippet portable (orchestration lean, transposé à ce repo) :**
  ```yaml
  # workflows/ci-python.yml — pattern "detect changed files → dispatch"
  - name: Lint changed files only
    run: |
      changed=$(git diff --name-only origin/main...HEAD -- '*.py')
      [ -z "$changed" ] && echo "no python change" && exit 0
      ruff check $changed
      python -m scripts.pii_scan $changed   # PR-scoped = rapide
  ```
- **Intégration dans shared-standards :** le repo fait déjà du « scoped scan » (PII sur fichiers changés en PR + audit hebdo full-repo). Adopter le modèle super-linter d'**un seul conteneur d'orchestration** pour unifier `ruff` + `pii_scan` + `quality_gate.py` réduirait la dérive entre les nombreux `scripts/audit-*.sh`.
- **Gotchas :** l'image super-linter est lourde (multi-runtime) ; ne pas l'importer telle quelle — reprendre le *principe* (config centralisée + parallélisme + fichiers-changés-only), pas le conteneur.

## pre-commit/pre-commit
- **owner/repo :** pre-commit/pre-commit · ~15.5k ⭐ · très actif (2 855 commits) · **MIT** (permissive → copiable) · Python
- **Fichier/module du pattern :** modèle `.pre-commit-config.yaml` + `additional_dependencies` (hooks hermétiques à versions épinglées) — exactement ce qu'utilise déjà ce repo pour le hook `pii-scan` (Presidio + wheels spaCy fr/en épinglés).
- **Mécanisme réel :** chaque hook déclare son runtime isolé et ses deps épinglées ; pre-commit crée un venv/env hermétique par hook, garantissant la reproductibilité indépendamment de l'environnement du dev.
- **Snippet portable :**
  ```yaml
  # .pre-commit-config.yaml — hook hermétique à deps épinglées
  - repo: local
    hooks:
      - id: pii-scan
        name: PII scan (Presidio, hermetic)
        entry: python -m scripts.pii_scan
        language: python
        additional_dependencies:
          - presidio-analyzer==2.2.x
          - https://.../fr_core_news_sm-3.x.x-py3-none-any.whl
  ```
- **Intégration :** déjà appliqué. Extension possible : convertir les hooks Claude Code `.cjs` (write-time WARN) en miroir `pre-commit` bloquant, pour que les mêmes seuils (`thresholds.json`) soient enforcés en Node ET en pré-commit.
- **Gotchas :** `additional_dependencies` doit tout épingler (y compris les modèles spaCy en wheel) sinon la reproductibilité casse ; le repo l'a bien compris (cf. README « hermetic »).

## backstage/backstage
- **owner/repo :** backstage/backstage · ~34.1k ⭐ · très actif (CNCF Incubation, ex-Spotify) · **Apache-2.0** (permissive → copiable) · TypeScript
- **Fichier/module du pattern :** **Software Templates (Scaffolder)** — génération de projets à partir des « organizational best practices » ; **TechDocs** (docs-like-code) ; catalogue logiciel.
- **Mécanisme réel :** un template Scaffolder = un `template.yaml` paramétré + skeleton de fichiers ; l'utilisateur remplit un formulaire, le moteur applique le skeleton et enregistre le composant au catalogue. C'est le pendant industriel du dossier `templates/` de ce repo (CLAUDE.md, CODEOWNERS, .gitignore, tasks.json, e2e scaffold).
- **Snippet portable (structure de manifeste de template) :**
  ```yaml
  # apiVersion backstage — inspiration pour un manifest templates/manifest.yaml
  parameters:
    - title: Stack
      properties:
        stack: { type: string, enum: [fastapi, django, react19, python-library] }
  steps:
    - id: fetch
      action: fetch:template
      input: { url: ./skeleton, values: { stack: ${{ parameters.stack }} } }
  ```
- **Intégration :** les templates de shared-standards sont "copy-to-use" manuels. Un manifeste type Scaffolder (même juste déclaratif, consommé par `distribute-standards.sh`) rendrait le choix de stack (fastapi/django/react19/python-library/monorepo/gas) piloté par données plutôt que par copie manuelle + suppression des tâches non pertinentes.
- **Gotchas :** Backstage complet est lourd (portail + backend + DB) — hors sujet à déployer ici. Ne reprendre QUE le format déclaratif de template + la philosophie TechDocs, pas la plateforme.

## github/awesome-copilot
- **owner/repo :** github/awesome-copilot · ~37.9k ⭐ · actif (2 224 commits) · **MIT** (permissive → copiable) · multi-langage (contenu)
- **Fichier/module du pattern :** dossier `instructions/` (« coding standards applied automatically by file pattern »), `skills/`, et surtout **`llms.txt`** — index machine-readable de tous les agents/instructions/skills pour consommation par agents IA.
- **Mécanisme réel :** les instructions sont appliquées par *glob de fichiers* (applyTo front-matter), et un `llms.txt` généré expose un catalogue structuré → un agent peut découvrir/charger les customizations programmatiquement.
- **Snippet portable (index llms.txt) :**
  ```
  # llms.txt — à générer pour copilot-instructions/ + standards/
  ## Instructions
  - [FastAPI](copilot-instructions/fastapi.md): applyTo=**/*.py backend
  - [React19](copilot-instructions/react19.md): applyTo=**/*.tsx
  ## Skills
  - [council](.claude/skills/council): decision arbitration
  ```
- **Intégration :** shared-standards a déjà `base.md` + guides par-stack (fastapi/django/react19/python-library/monorepo/gas) qui "extends & override base". Ajouter un **`llms.txt` généré** (comme awesome-copilot) rendrait le catalogue découvrable par les agents Claude/Copilot de tout l'écosystème, et documenterait la relation extends/override de façon machine-lisible.
- **Gotchas :** contenu communautaire tiers → awesome-copilot recommande d'inspecter avant install ; ici le contenu est first-party, mais garder la discipline « un fichier = un applyTo clair » évite les collisions d'instructions.

## microsoft/presidio
- **owner/repo :** microsoft/presidio · ~10.5k ⭐ · actif (1 627 commits, OpenSSF Best Practices) · **MIT** (permissive → copiable ; **déjà une dépendance**) · Python
- **Fichier/module du pattern :** `presidio-analyzer` — recognizers (NER + regex + logique + checksum) ; exactement ce que `scripts/pii_scan.py` orchestre (emails, IBAN, tél, CB, IP, NIR FR avec validation clé de contrôle).
- **Mécanisme réel :** pipeline Analyzer = plusieurs recognizers scorent chaque entité ; seuil de score configurable ; possibilité de custom recognizer (ici NIR FR avec control-key). Le repo a bien exclu `PERSON`/`FR_CNI` par défaut (NER trop bruyant sur du code, pattern 12-chiffres trop large — cf. DECISIONS.md D-0006).
- **Snippet portable (custom recognizer à checksum, pattern NIR) :**
  ```python
  from presidio_analyzer import PatternRecognizer, Pattern
  nir = PatternRecognizer(
      supported_entity="FR_NIR",
      patterns=[Pattern("nir", r"\b[12]\d{2}(0[1-9]|1[0-2])\d{9}\b", 0.5)],
      # validation clé de contrôle en post-hook → score boosté / rejeté
  )
  ```
- **Intégration :** déjà en place et bien conçu (seuil de score dans `.pii-scan.toml`, allowlist par fingerprint dans `.pii-allowlist.json`, hook hermétique). Presidio sert ici de **validation** : l'architecture PII du repo suit les bonnes pratiques upstream.
- **Gotchas :** disclaimer upstream — détection automatique ≠ exhaustive ; garder l'audit hebdo full-repo non-bloquant + revue humaine des allowlists. spaCy `PERSON` volontairement désactivé = bon choix documenté.

---

## Synthèse licences
Toutes permissives : **super-linter (MIT), pre-commit (MIT), Backstage (Apache-2.0), awesome-copilot (MIT), presidio (MIT)** → copiables sans contrainte copyleft. Aucune source GPL/AGPL/BSL/Elastic/fair-code à réimplémenter.

## Takeaways prioritaires
1. **Un seul orchestrateur "fichiers-changés-only"** (modèle super-linter) pour unifier ruff + pii_scan + quality_gate et réduire la dérive des ~15 scripts `audit-*.sh`.
2. **Générer un `llms.txt`** (modèle awesome-copilot) pour rendre `copilot-instructions/` + `standards/` + skills découvrables par les agents de l'écosystème.
3. **Manifeste de template déclaratif** (modèle Backstage Scaffolder) pour piloter `distribute-standards.sh` par données (stack) au lieu de copie manuelle ; pre-commit + Presidio déjà exemplaires (hermétiques, épinglés).
