# Audit conformité standards chrysa

_56 repos status:dev · 32 non conformes · 24 conformes_

## Adoption des nouveaux standards (distribution pas encore lancée)

- `.chrysa/STANDARDS.md` présent : **0 / 56**
- import `@.chrysa/STANDARDS.md` dans CLAUDE.md : **0 / 56**

## Violations par fréquence

| Violation | Repos |
|---|---|
| pre-commit drift/absent | 18 |
| manque AGENTS.md | 10 |
| manque opencode.json | 10 |
| manque .gitattributes | 9 |
| CI sans chrysa actions | 9 |
| manque CONTRIBUTING | 8 |
| manque CHANGELOG | 7 |
| manque cliff.toml | 7 |
| manque GitVersion.yml | 7 |
| manque CODEOWNERS | 6 |
| python sans tests | 5 |
| manque .editorconfig | 4 |
| pyver!=3.14 (cible 3.14) | 2 |
| manque CLAUDE.md | 2 |
| absent du scan local | 1 |
| public sans LICENSE | 1 |

## Pires contrevenants (≥5 violations)

- **django-traceid** (10) — manque CHANGELOG, manque cliff.toml, manque GitVersion.yml, manque opencode.json, manque AGENTS.md, pre-commit drift/absent, manque .editorconfig, manque .gitattributes, manque CONTRIBUTING, pyver=3.12 (cible 3.14)
- **feedback-gateway** (8) — manque CHANGELOG, manque cliff.toml, manque GitVersion.yml, manque opencode.json, manque AGENTS.md, pre-commit drift/absent, manque CODEOWNERS, pyver=3.12 (cible 3.14)
- **pre-commit-hooks-changelog** (8) — manque CLAUDE.md, manque CHANGELOG, manque cliff.toml, manque GitVersion.yml, manque AGENTS.md, CI sans chrysa actions, pre-commit drift/absent, manque CODEOWNERS
- **django-autoload** (7) — manque CHANGELOG, manque cliff.toml, manque GitVersion.yml, manque opencode.json, manque AGENTS.md, pre-commit drift/absent, manque CODEOWNERS
- **game-solver-platform** (7) — manque CLAUDE.md, manque CHANGELOG, manque cliff.toml, manque GitVersion.yml, CI sans chrysa actions, pre-commit drift/absent, manque CODEOWNERS
- **paperclip** (6) — manque opencode.json, CI sans chrysa actions, pre-commit drift/absent, manque .editorconfig, manque .gitattributes, manque CONTRIBUTING
- **claude-config** (5) — CI sans chrysa actions, pre-commit drift/absent, manque .editorconfig, manque .gitattributes, manque CONTRIBUTING
- **django-app-forge** (5) — manque CHANGELOG, manque cliff.toml, manque GitVersion.yml, manque opencode.json, manque AGENTS.md
- **django-query-optimizer** (5) — manque opencode.json, pre-commit drift/absent, manque .editorconfig, manque .gitattributes, manque CONTRIBUTING
- **quality-gatekeeper** (5) — CI sans chrysa actions, pre-commit drift/absent, manque .gitattributes, manque CONTRIBUTING, python sans tests

## Détail par repo non conforme

- **automations** : pre-commit drift/absent; manque .gitattributes; manque CONTRIBUTING
- **catalog** : manque AGENTS.md; CI sans chrysa actions; manque CODEOWNERS
- **chrysa-lib** : python sans tests
- **chrysa-skills** : manque opencode.json
- **claude-config** : CI sans chrysa actions; pre-commit drift/absent; manque .editorconfig; manque .gitattributes; manque CONTRIBUTING
- **coach** : python sans tests
- **container-webview** : pre-commit drift/absent
- **devtool** : manque AGENTS.md; CI sans chrysa actions
- **discordium** : manque AGENTS.md
- **django-app-forge** : manque CHANGELOG; manque cliff.toml; manque GitVersion.yml; manque opencode.json; manque AGENTS.md
- **django-autoload** : manque CHANGELOG; manque cliff.toml; manque GitVersion.yml; manque opencode.json; manque AGENTS.md; pre-commit drift/absent; manque CODEOWNERS
- **django-pytest** : manque CHANGELOG; manque cliff.toml; manque GitVersion.yml; manque opencode.json
- **django-query-optimizer** : manque opencode.json; pre-commit drift/absent; manque .editorconfig; manque .gitattributes; manque CONTRIBUTING
- **django-query-optimizer-vscode** : manque opencode.json; manque AGENTS.md; CI sans chrysa actions; pre-commit drift/absent
- **django-traceid** : manque CHANGELOG; manque cliff.toml; manque GitVersion.yml; manque opencode.json; manque AGENTS.md; pre-commit drift/absent; manque .editorconfig; manque .gitattributes; manque CONTRIBUTING; pyver=3.12 (cible 3.14)
- **epub-sorter** : absent du scan local
- **feedback-gateway** : manque CHANGELOG; manque cliff.toml; manque GitVersion.yml; manque opencode.json; manque AGENTS.md; pre-commit drift/absent; manque CODEOWNERS; pyver=3.12 (cible 3.14)
- **game-solver-platform** : manque CLAUDE.md; manque CHANGELOG; manque cliff.toml; manque GitVersion.yml; CI sans chrysa actions; pre-commit drift/absent; manque CODEOWNERS
- **gaming-os** : pre-commit drift/absent
- **genealogy-validator** : pre-commit drift/absent
- **gestureOS** : manque opencode.json; manque CODEOWNERS
- **linkendin-resume** : python sans tests
- **mediavault** : pre-commit drift/absent
- **my-resume** : pre-commit drift/absent; manque .gitattributes; manque CONTRIBUTING
- **orchestrator** : pre-commit drift/absent; manque .gitattributes
- **paperclip** : manque opencode.json; CI sans chrysa actions; pre-commit drift/absent; manque .editorconfig; manque .gitattributes; manque CONTRIBUTING
- **pre-commit-hooks-changelog** : manque CLAUDE.md; manque CHANGELOG; manque cliff.toml; manque GitVersion.yml; manque AGENTS.md; CI sans chrysa actions; pre-commit drift/absent; manque CODEOWNERS
- **quality-gatekeeper** : CI sans chrysa actions; pre-commit drift/absent; manque .gitattributes; manque CONTRIBUTING; python sans tests
- **server** : CI sans chrysa actions; python sans tests
- **shared-standards** : manque .gitattributes; manque CONTRIBUTING; public sans LICENSE
- **sport-intelligence-hub** : manque AGENTS.md
- **usefull-containers** : pre-commit drift/absent