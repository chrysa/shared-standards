# Audit — "Docker → rien en local" (2026-08-07)

Standard source: `standards/STANDARDS.chrysa.md` §"External dependencies are installed in
containers, never on the host" + "No virtualenv in a repo — ever". Rule already canonical;
this audit measures fleet conformance. Scope: Docker-using chrysa repos (read-only).

Method: registry `repos.yml` `runtime:` join × Makefile host-install detection ×
in-container-wrapper check (`docker compose run` / `run_cmd` / `sh -c` inside a service).
Positive control: `git ls-files` returns 327/112/94 on samples (detector live).

## A. Real host-install violations — full-standard repos (`runtime: container`/`full`)

Bare `install:` recipe runs pip/npm on the host. Fix: route install through the image /
`make docker-*`; delete the host target. Docker path already exists in each.

| repo | line | severity |
| --- | --- | --- |
| ai-aggregator | `pip install -e ".[dev]"` | host-install |
| audit-platform | `.venv/bin/pip install --upgrade pip` | **host-install + venv-in-repo** |
| cdn-explorer | `pip install -e ".[dev]"` | host-install |
| chrysa-portfolio-viz | `@$(PYTHON) -m pip install -e .` | host-install |
| discordium | `cd backend && pip install -e ".[dev]"` | host-install |
| doc-gen | `@pip install -e .` | host-install |
| feedback-gateway | `pip install -e ".[dev]"` | host-install |
| link-reader-bot | `pip install -e ".[dev]"` | host-install |
| mirrador | `pip install -e ".[dev]"` (+e2e) | host-install |
| satisfactory-factory-manager | `pip install -e ".[dev]"` | host-install |
| wsmqtt-monitor | `pip install -e ".[dev]"` | host-install |

## B. Unregistered + host-install (register in repos.yml + fix)

- daedalus-document-factory — `pip install -e .`
- fastapi-app-forge — `pip install -e ".[dev]"`

## C. False alarms — pip/npm run INSIDE container (COMPLIANT)

- D-D, PO-GO-DEX — `run_cmd service_name=*-dev cmd="npm install …"`
- studioverse — `DOCKER_COMPOSE run --rm backend-test sh -c "pip install …"`
- sport-intelligence-hub — `DC … run` + `pip install --user` in test service

## D. Tolerated — `exempt:lib` / `exempt:native` editable-install (low priority)

debian-guardian, django-app-forge, django-autoload, django-pytest, django-query-optimizer,
django-traceid, fastapi-autoload, fastapi-pytest, fastapi-query-optimizer, fastapi-traceid,
gestureOS, lifeos, my-assistant, pre-commit-hooks-changelog, pre-commit-tools.
Distributed libs / host-bound tools — editable install is the documented exception. Note only.

## E. Clean

- Full-standard clean (8): container-webview, dev-nexus, devtool, discord-bot-back,
  floating-knowledge-architect-offline, gaming-os, genealogy-validator, linkendin-resume
- Exempt clean (10): chrysa-lib, diy-stream-deck, django-migration-analyzer, epub-sorter,
  floating-agent, guideline-checker, project-init, shared-standards, usefull-containers,
  windows-docker-state-notification

## Enforcement gap

Rule is prose, unenforced. No write-time hook detects `venv-in-repo` or a bare host
`pip install` recipe. Candidate: a `verifiable-thresholds`-style PostToolUse warn +
CI check (grep Makefile recipes for un-wrapped pip/npm install). ~11+2 remediation PRs.
