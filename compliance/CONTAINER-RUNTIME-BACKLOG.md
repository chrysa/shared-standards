# Container-runtime conformance backlog

Policy: **a project runs ONLY in a container unless its nature forbids it** —
`EXECUTION_STANDARD.md §6.1`. Classification lives in `repos.yml` (`runtime:` field);
state is machine-checked by `scripts/audit-docker-compliance.sh`
(baseline: `compliance/docker-conformance.json`).

Snapshot at policy introduction: **pass=22 warn=11 fail=0 exempt=20 pending=4 absent=1**.
The fleet fully conforms: every code-bearing repo either runs in a container or its nature
genuinely forbids it. Only the polish (WARN) and pre-code (PENDING) items below remain.
Remediate one repo per session (Rule 1+2).

## FAIL — true runtime-policy violations (P0)

A `container` repo that cannot run containerized (no Dockerfile **and** no compose).

**None.** ✅

> `lifeos` (= `my-assistant`) was first flagged here, then correctly reclassified `exempt:native`:
> it is a floating multi-OS desktop assistant (overlay UI, system tray, OS-level system
> monitoring) — a container cannot provide that host access. Same category as `floating-agent`.
> It keeps `Dockerfile.test` + `.devcontainer/` for CI and dev.

## PENDING — enforce at first code

Pre-code scaffolds; flip `pending`→`container` (or to the right class, e.g. `exempt:lib`) when
app code lands. Enforced at scaffold time via `project-init` / `chrysa-init` (see follow-up below)
so they start compliant.

- `coach` · `game-solver-platform` · `mediavault` · `quality-gatekeeper`

> `quality-gatekeeper` was initially eyed as a runtime violator, but it holds only an empty
> `quality_gatekeeper/__init__.py` (no app, no tests). It is pre-code like the others — classified
> `pending`, not scaffolded with a hollow container. Its eventual class is likely `exempt:lib`
> (a detector library, sibling of `guideline-checker`).

## WARN — runs in a container, missing §6 polish

Not runtime violations (they already run in containers). These are §6 / Makefile-standard gaps,
mostly the `docker-up`/`docker-down`/`docker-test` target names supplied by `base-makefile`
(overlaps `audit-makefile-conformance.sh`). Fold into the next makefile-sync sweep.

| Repo | Gap |
|---|---|
| `chrysa-portfolio-viz` | docker-up, docker-down |
| `D-D` | docker-up, docker-down |
| `dev-nexus` | docker-up, docker-down, docker-test |
| `devtool` | HEALTHCHECK, docker-test |
| `feedback-gateway` | compose, docker-up, docker-down |
| `linkendin-resume` | docker-up, docker-down, docker-test |
| `my-resume` | docker-up, docker-down |
| `PO-GO-DEX` | docker-up, docker-down |
| `satisfactory-factory-manager` | docker-up, docker-down |
| `django-autoload` (lib) | no docker-test / Dockerfile.test — tests would run on host |
| `pre-commit-hooks-changelog` (lib) | no docker-test / Dockerfile.test — tests would run on host |

## ABSENT

- `epub-sorter` — not checked out locally at audit time; re-verify on next full sync.

## Follow-up campaign — enforce at scaffold

`project-init` / `chrysa-init` should emit a runtime container (Dockerfile + compose +
docker-up/down/test) by default, and new `repos.yml` entries should default `runtime: container`
(or an explicit exemption). This keeps the policy self-sustaining instead of relying on retro-audits.
