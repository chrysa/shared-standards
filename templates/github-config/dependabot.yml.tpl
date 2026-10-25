---
# Dependabot template chrysa · avril 2026
# Source : shared-standards/templates/github-config/dependabot.yml.tpl
#
# Schedule unifié : vendredi 04h00 UTC cron (évite PR en cours de sprint)
# Cooldown 7j sur ecosystems bruyants · groups pour réduire volume PR
# Chaque ecosystem a un groupe filet ("*") : seule une majeure ouvre une PR seule.
#
# Marqueurs {{ ... }} à remplacer par le script apply-ci-process.sh selon stack détectée.
# Ecosystems possibles : pip, npm, docker, docker-compose, github-actions, pre-commit, cargo

version: 2
updates:
    # ═══ GitHub Actions (tous repos) ═══
    - package-ecosystem: github-actions
      directory: .github/workflows/
      assignees:
          - chrysa
      reviewers:
          - chrysa
      open-pull-requests-limit: 8
      commit-message:
          prefix: "[SKIP CI] [GA] "
      labels:
          - skip-ci
          - dependencies
          - Ci
      schedule:
          interval: cron
          cronjob: "0 4 * * 5"
      groups:
          actions-official:
              patterns:
                  - actions/*
          peter-evans:
              patterns:
                  - peter-evans/*
          community-actions:
              patterns:
                  - "*"
      cooldown:
          default-days: 7

    # ═══ Pre-commit (tous repos avec .pre-commit-config.yaml) ═══
    - package-ecosystem: pre-commit
      directory: /
      assignees:
          - chrysa
      reviewers:
          - chrysa
      open-pull-requests-limit: 2
      commit-message:
          prefix: "[SKIP CI] [pre-commit] "
      labels:
          - skip-ci
          - dependencies
          - Pre-commit
      schedule:
          interval: cron
          cronjob: "0 4 * * 5"
      # Un seul PR hebdo pour tous les hooks : sans groupe, chaque hook
      # ouvrait sa propre PR (et le plafond de 2 les étalait sur des semaines).
      groups:
          pre-commit-hooks:
              patterns:
                  - "*"
      cooldown:
          default-days: 7

# {{ECOSYSTEM_PYTHON_START}}
    # ═══ Python · pip ═══
    - package-ecosystem: pip
      directory: {{PIP_DIR}}
      assignees:
          - chrysa
      reviewers:
          - chrysa
      open-pull-requests-limit: 10
      commit-message:
          prefix: "[pip] "
      labels:
          - dependencies
          - Python
      schedule:
          interval: cron
          cronjob: "0 4 * * 5"
      groups:
          testing:
              patterns:
                  - pytest*
                  - faker
                  - mock
                  - coverage*
          typing-stubs:
              patterns:
                  - mypy*
                  - types-*
          linters:
              patterns:
                  - ruff*
                  - black*
                  - flake8*
          # Filet : tout le reste en minor/patch dans une seule PR. Les groupes
          # ci-dessus gagnent (premier groupe qui matche) ; les majeures
          # restent en PR individuelles pour être relues.
          minor-and-patch:
              patterns:
                  - "*"
              update-types:
                  - minor
                  - patch
      cooldown:
          default-days: 7
# {{ECOSYSTEM_PYTHON_END}}

# {{ECOSYSTEM_NPM_START}}
    # ═══ Node / npm ═══
    - package-ecosystem: npm
      directory: {{NPM_DIR}}
      assignees:
          - chrysa
      reviewers:
          - chrysa
      open-pull-requests-limit: 10
      commit-message:
          prefix: "[npm] "
      labels:
          - dependencies
          - JavaScript
      schedule:
          interval: cron
          cronjob: "0 4 * * 5"
      groups:
          react-ecosystem:
              patterns:
                  - react
                  - react-*
                  - "@types/react*"
          testing:
              patterns:
                  - vitest
                  - "@testing-library/*"
                  - jest*
          build-tools:
              patterns:
                  - vite
                  - "@vitejs/*"
                  - typescript
                  - "@typescript-eslint/*"
                  - eslint*
          # Filet : tout le reste en minor/patch dans une seule PR. Les groupes
          # ci-dessus gagnent (premier groupe qui matche) ; les majeures
          # restent en PR individuelles pour être relues.
          minor-and-patch:
              patterns:
                  - "*"
              update-types:
                  - minor
                  - patch
      cooldown:
          default-days: 7
# {{ECOSYSTEM_NPM_END}}

# {{ECOSYSTEM_DOCKER_START}}
    # ═══ Docker ═══
    - package-ecosystem: docker
      directory: {{DOCKER_DIR}}
      assignees:
          - chrysa
      reviewers:
          - chrysa
      open-pull-requests-limit: 5
      commit-message:
          prefix: "[docker] "
      labels:
          - dependencies
          - Docker
      schedule:
          interval: cron
          cronjob: "0 4 * * 5"
# {{ECOSYSTEM_DOCKER_END}}

# {{ECOSYSTEM_DOCKER_COMPOSE_START}}
    # ═══ docker-compose ═══
    - package-ecosystem: docker-compose
      directory: /
      assignees:
          - chrysa
      reviewers:
          - chrysa
      open-pull-requests-limit: 5
      commit-message:
          prefix: "[SKIP CI] [docker-compose] "
      labels:
          - skip-ci
          - dependencies
          - Docker
      schedule:
          interval: cron
          cronjob: "0 4 * * 5"
# {{ECOSYSTEM_DOCKER_COMPOSE_END}}
