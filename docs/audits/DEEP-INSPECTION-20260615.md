# Deep inspection — 56 repos status:dev

_Scan: hygiène git · sécurité · CI · dépendances. 55 repos._

## Synthèse

- **Activité** : tous actifs (dernier commit médian 1j, max 9j) — aucun repo abandonné.
- **Working trees sales** : 10 repos avec >20 fichiers non commités (sprawl).
- **Branches stale** : 28 repos avec >15 branches locales.
- **Actions CI non pinnées (@main/@master)** : 274 occurrences sur 55 repos.
- **Sécurité** : 0 secret live committé (hits = placeholders). 2 repos trackent un vrai `.env` : my-resume, usefull-containers.
- **.secrets.baseline manquant** : 17 repos (D-D, dev-nexus, diy-stream-deck, django-app-forge, django-autoload, django-pytest, django-query-optimizer, django-traceid, feedback-gateway, floating-agent, gestureOS, github-actions, linkendin-resume, mirrador, my-resume, pre-commit-hooks-changelog, windows-docker-state-notification).
- **Python ≠ 3.14** : django-traceid(3.12), feedback-gateway(3.12).
- **Pas de lockfile (repos Python)** : 11 repos.
- **Pas de sonar.yml** : 15 · **pas de release.yml** : 10 · **CI sans chrysa actions** : 0.

## Hygiène git — working trees les plus sales
| repo | non commités | branches | branche courante |
|---|---|---|---|
| chrysa-skills | 294 | 13 | chore/remove-reliquats |
| server | 105 | 27 | chore/remove-reliquats |
| catalog | 98 | 18 | feat/sport-hub-deploy |
| dev-nexus | 64 | 77 | chore/remove-playwright-reliquat |
| PO-GO-DEX | 43 | 17 | chore/adopt-lean-ci |
| discord-bot-back | 29 | 16 | chore/adopt-lean-ci |
| ai-aggregator | 26 | 26 | main |
| discordium | 25 | 47 | chore/remove-reliquats |
| gaming-os | 24 | 30 | chore/adopt-lean-ci |
| floating-agent | 23 | 20 | chore/remove-reliquats |

## Branches stale (sprawl)
| repo | branches |
|---|---|
| dev-nexus | 77 |
| discordium | 47 |
| doc-gen | 46 |
| mirrador | 41 |
| satisfactory-factory-manager | 41 |
| sport-intelligence-hub | 38 |
| shared-standards | 32 |
| gaming-os | 30 |

## Actions CI non pinnées (supply-chain)
| repo | occurrences |
|---|---|
| pre-commit-tools | 18 |
| linkendin-resume | 15 |
| doc-gen | 11 |
| floating-agent | 10 |
| guideline-checker | 10 |
| ai-aggregator | 9 |
| cdn-explorer | 8 |
| container-webview | 8 |
| discordium | 7 |
| link-reader-bot | 7 |

## Dette inline (TODO/FIXME/HACK)
| repo | count |
|---|---|
| shared-standards | 141 |
| project-init | 132 |
| discordium | 131 |
| django-app-forge | 125 |
| automations | 24 |
| guideline-checker | 24 |
| server | 14 |
| agent-config | 12 |

## Gros fichiers trackés (>2 MB)
| repo | nb |
|---|---|
| server | 16 |
| chrysa-portfolio-viz | 9 |
| dev-nexus | 9 |
| ai-aggregator | 7 |
| chrysa-skills | 5 |
| container-webview | 5 |
| django-pytest | 5 |
| floating-agent | 5 |

## Dépendances

- Python sans lockfile : chrysa-portfolio-viz, coach, django-app-forge, django-autoload, django-pytest, django-traceid, doc-gen, feedback-gateway, gestureOS, lifeos, quality-gatekeeper
- Python ≠ 3.14 : django-traceid (3.12), feedback-gateway (3.12)

## Sécurité — à corriger

- **Vrai `.env` tracké** (risque fuite) : my-resume, usefull-containers → `git rm --cached .env` + ajouter au .gitignore.
- `.secrets.baseline` absent : D-D, dev-nexus, diy-stream-deck, django-app-forge, django-autoload, django-pytest, django-query-optimizer, django-traceid, feedback-gateway, floating-agent, gestureOS, github-actions, linkendin-resume, mirrador, my-resume, pre-commit-hooks-changelog, windows-docker-state-notification
