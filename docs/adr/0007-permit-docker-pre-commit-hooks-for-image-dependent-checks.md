# ADR 0007 — Permit `language: docker` pre-commit hooks for image-dependent checks

- **Status:** Proposed
- **Date:** 2026-08-29
- **Deciders:** chrysa
- **Pillars touched:** none (internal DevEx / commit-gate architecture)
- **Supersedes / Superseded by:** relaxes the blanket ban stated in the *gate is host-native* rule (STANDARDS.chrysa.md); that rule stands, this ADR narrows its prohibition.

## Context

The standard forbids `language: docker` / `docker compose run` in every pre-commit hook: the
commit gate is host-native, installable with `pipx install pre-commit` alone, and never
depends on the Docker daemon. The rationale is real and unchanged: a `git commit` must not be
blockable by a stopped daemon, and the shared hook package must install fleet-wide with one
command.

But the ban has a cost. A check that genuinely needs the project image — a query against a real
database, framework settings that only load inside the app image, a compiled tool — cannot run
as a hook at all. Today it *degrades to a host skip* and is enforced only in CI. That is sound
when CI is fast and green, but it means a class of defects is never caught at commit time even
on a developer machine where Docker *is* running. The blanket ban optimises for the
daemon-less case at the cost of the (common) daemon-present case.

## Decision

Permit `language: docker` / `docker compose run` pre-commit hooks **for image-dependent checks**,
lifting the blanket ban — **provided** the core gate stays installable and runnable with
`pipx install pre-commit` alone (simple/fast hooks remain host-native), and every docker hook
**degrades to a skip when the Docker daemon is unavailable**, so a routine `git commit` is never
hard-blocked by the daemon being down. The shared `chrysa/pre-commit-tools` package itself stays
Docker-free (its published hooks remain `language: python`/`system`); docker hooks are a
repo-local, opt-in layer for checks that truly need the image.

## Fatal hypothesis

A docker pre-commit hook can be added to a repo's gate **without making a routine `git commit`
depend on the Docker daemon or materially slower** — because docker hooks are opt-in, scoped to
image-dependent checks, and skip (not block) when the daemon is absent.

## Kill-test

On the reference machine with the Docker daemon **stopped**, `git commit` on a one-line change
still **succeeds** (exit 0) and completes in **< 5 s** — the docker hook prints a skip message
instead of blocking. Mechanised as a smoke test in the standards console / a consumer's CI:
run `pre-commit run` with the daemon unreachable and assert exit 0 + a skip line for the docker
hook, and assert p50 commit time on a trivial change stays < 5 s. **On breach** (a docker hook
hard-blocks a daemon-less commit, or p50 trivial-commit time ≥ 5 s), this ADR is **Killed** and
the blanket host-native ban is restored.

## Validation gate

Before any docker hook is recommended to the fleet: a reference repo demonstrates a docker hook
(e.g. a DB-dependent check) that (a) **passes** when run in its container, (b) **skips cleanly**
on a daemon-less host with a message, and (c) leaves `pipx install pre-commit && pre-commit run`
(no docker) passing every non-docker hook. All three observed before rollout.

## Options considered

| Option | Why not |
| ------ | ------- |
| Keep host-native only (status quo) | Heavy, image-dependent checks are silently skipped locally even when Docker is running; a real class of defects is caught only in CI. |
| Require containers for all hooks (local included) | Breaks the daemon-free `git commit` guarantee and the one-command `pipx install pre-commit` install; every commit hostage to the daemon. Rejected by the owner. |
| **Permit docker hooks, opt-in, with graceful daemon-less degradation (chosen)** | Keeps the daemon-free floor and the pipx-only install, while letting a repo enforce an image-dependent check at commit time when Docker is present. |

## Consequences

- Docker hooks become a legitimate, documented option for image-dependent checks — no longer a
  standards violation.
- Added complexity for repos that adopt them: each docker hook must implement the daemon-less
  skip, and is slower when it runs. That cost is opt-in and local to the adopting repo.
- The daemon-free floor is preserved: `pipx install pre-commit` still runs the full non-docker
  gate; `chrysa/pre-commit-tools` stays Docker-free by construction so the fleet install is
  unchanged.
- The CI-side obligation is unchanged and still mandatory: an image-dependent check has a
  blocking containerised counterpart in CI (STANDARDS.chrysa.md, reinforced with `CI-032`).
- **Blast radius if Killed:** revert the standard's *gate is host-native* wording to the blanket
  ban, remove any adopted docker hooks, and fall back to CI-only enforcement of image-dependent
  checks.
