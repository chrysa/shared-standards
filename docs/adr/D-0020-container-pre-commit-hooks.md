# D-0020: Allow container pre-commit hooks (`language: docker` / `docker_image`)

- **Status:** Accepted
- **Date:** 2026-11-08
- **Deciders:** chrysa
- **Pillars touched:** none
- **Supersedes / Superseded by:** replaces the ban on `language: docker` / `language: docker_image`
  in *Pre-commit & git hooks* (canon, "The gate is host-native" and "The shared hook package")

## Context

The canon made the commit gate strictly host-native: local hooks had to be `language: system` /
`python`, and `language: docker` / `language: docker_image` were **forbidden**, in repo hooks and
in `chrysa/pre-commit-tools`. The reason was sound: a commit must never depend on the project's
image or a running stack, and the fleet gate must install with `pipx install pre-commit` alone.

The owner decided on 2026-08-29 to stop forbidding Docker in pre-commit hooks and to record it in
an ADR and in the standard. The decision stayed unapplied: the canon still said "forbidden", and
no repo used a container hook (0 of 90 `.pre-commit-config.yaml` read on 2026-11-04). Repos that
want their hooks in containers were therefore in breach of the canon. The owner
confirmed the choice on 2026-11-08: allowed, not required.

Two different things were bundled under the ban:

1. **pre-commit's own container languages.** `language: docker_image` runs a pinned image with
   `docker run --rm -u <uid>:<gid> -v <work tree>:/src --workdir /src`; `language: docker` does the
   same with an image built from the hook repository's `Dockerfile`. No compose file, no project
   service, no state outside the run.
2. **Driving the project's stack from a hook** (`docker compose run`, the dev image, a database).
   That is the real coupling the ban protected against.

Docker is already one of the three sanctioned host tools (container-runtime policy), next to git
and pre-commit.

## Decision

- Hooks stay **native by default**.
- `language: docker_image` and `language: docker` are **allowed, not required**, for a check
  whose toolchain is better pinned in an image than installed on the host. The image is pinned
  (explicit tag, digest where available, never `:latest`); the hook runs only through
  pre-commit's own `docker run`; its CI counterpart is mandatory (`CI-036`).
- Driving the project's stack from a hook stays **forbidden**: no `docker compose run`, no dev
  image, no running service or database in a hook. A check that needs the project image still
  degrades on the host and runs for real in CI.
- A repo that adopts a container hook needs the Docker daemon to commit and says so in its
  `CONTRIBUTING.md`.
- In `chrysa/pre-commit-tools`, the **default set** stays native. A container hook is published
  under its own id, opt-in per repo, never added to the default set and never the only form of a
  check that has a native one. A `docker` / `docker compose` call inside a hook entrypoint stays
  forbidden.

## Fatal hypothesis

A container hook costs a developer less than installing and pinning the same tool on every host:
the image start-up and the daemon dependency stay small next to the drift they remove.

## Kill-test

Checked at each quarterly standards review, on the repos that use at least one container hook.
The hypothesis is false if either holds for two consecutive reviews:

- the median `pre-commit run` time on a typical commit of those repos is more than twice the
  time of the same repos before the container hook was added; or
- "Docker daemon not running" or an image pull failure is the most frequent cause of a blocked
  commit reported in their issues.

On breach, the container hooks of the affected repos move to CI-only jobs, and a superseding ADR
restores the native-only rule or narrows this one.

## Validation gate

The rule is validated when at least two repos run a container hook for one quarter, each with its
CI counterpart green and its `CONTRIBUTING.md` stating the Docker requirement, without a
kill-test signal.

## Options considered

| Option | Why not |
| ------ | ------- |
| Keep the ban | Contradicts the owner's decision of 2026-08-29 and 2026-11-08; keeps the repos that want a pinned toolchain in breach or installing tools on the host. |
| Make container hooks mandatory | The fleet gate would need the daemon on every machine and in every hosted runner; native hooks work today and cost nothing to keep. |
| Allow `docker compose run` too | Brings back the coupling to the project's stack that the ban was right to forbid. |

## Consequences

- The canon (*Pre-commit & git hooks*) and its generated view `standards/rules/ci-cd.md` state
  the new rule; nothing changes for repos that keep native hooks.
- Reviewers check a container hook for: pinned image, no compose, CI counterpart, Docker
  requirement documented.
- `chrysa/pre-commit-tools` may publish opt-in container hooks; its default set and the fleet
  distribution are unchanged.
- Rollback: revert this ADR and the canon change; repos that adopted a container hook move it to
  a CI job.
