<!-- GENERATED from standards/STANDARDS.chrysa.md by scripts/gen_agent_views.py — do not edit.
Canonical source of truth is the canon; edit there, then run `make gen-agent-views` to regenerate every view.
-->
# Observability & operations

> Detail for the slim core in `CLAUDE.md`. **Generated** from `standards/STANDARDS.chrysa.md` — do not edit here; edit the canon and regenerate.

- **Observability & production readiness follow the `STD-OPS-001` contract.** A deployable
  service exposes startup/liveness/readiness probes, emits structured logs + metrics + traces
  correlated through a common id via **OpenTelemetry with a replaceable backend**, and ships an
  actionable alert + owner + runbook per principal incident. Resource limits and saturation
  behaviour are explicit; graceful shutdown, restart recovery and dependency-loss are tested;
  backup/restore/rollback/degraded mode are documented before the first prod deploy; and the
  service publishes `/version`. Full rules and the Production-Ready gate: annexe
  [`OBSERVABILITY-OPS.md`](https://github.com/chrysa/shared-standards/blob/main/standards/annexes/OBSERVABILITY-OPS.md)
  (`OP-nnn`).

- **The container is versioned separately from the application it hosts, and an admin can see
  what is actually deployed.** An image and an app are two artefacts with two lifecycles: a
  rebuild that only picks up a new base image, a patched OS library or a changed entrypoint
  produces a **new image version carrying the same application version** — and a redeploy of
  the same app on a fresh image is exactly the change an incident review needs to see. So the
  two versions are recorded and surfaced side by side; conflating them turns "we redeployed"
  into an untraceable event.
  1. **Both identities travel with the image.** Every image carries OCI labels — at minimum
     `org.opencontainers.image.version` (the image's own version),
     `org.opencontainers.image.revision` (git SHA), `org.opencontainers.image.created`, plus
     the application version it packages. They are build arguments injected by CI, never
     hand-edited.
  2. **Deployments pin a digest, never a moving tag.** `:latest` is not a version; a
     manifest or compose file references `image@sha256:…` (or an immutable tag) so what runs
     is exactly what was tested — see *build once, promote the artefact* (`CI-046`).
  3. **The service publishes what it is** — a small, unauthenticated-safe endpoint
     (`/version` or the health payload) returning the **application version**, the **image
     tag and digest**, the git SHA, the build timestamp and the environment name. No secret,
     no dependency inventory: enough to answer "which build is this?" and nothing more.
  4. **The frontend shows it to admins, and knows its own.** The admin surface (config panel,
     about screen, footer of an admin page) displays the **frontend build version** — embedded
     at build time, not read at runtime — next to the backend's application version, image
     digest and environment. A support conversation that starts with "which version are you
     on?" and cannot be answered from the interface is a defect.
  5. **A version mismatch is surfaced, not silently tolerated.** When the frontend detects
     that the backend's version changed under it, or that its own build no longer matches the
     API it is talking to, it tells the user and offers a reload rather than failing in
     obscure ways. Deployed versions per environment are also visible from the platform side
     (release notes, deployment log), so "what is in production" never requires a shell.

## Observability — error-tracking → GitHub issues (norm)

Every status:dev repo ships an error-tracking project, and every new error-tracking issue ends
up as exactly one tracked work item. Use the error-tracking service's **native** features first;
what is native depends on the service plan, so check the plan before building anything.

On the plan in use (Sentry Developer, verified 2026-11-09), alert actions are **email only**:
no GitHub, chat, tracker or webhook action, and linking an issue to GitHub or the tracker needs
a paid plan. The mechanism is therefore:

1. The error-tracking alert emails the owner (default alert rules are enough).
2. A mail filter routes those emails to the action label (e.g. `1 Action/Dev`), never to spam.
3. The owner opens the work item by hand when the error matters (tracker story, or GitHub issue
   labelled `sentry`, `bug`).
4. Releases and commits are sent to the error-tracking service from CI, so that a commit message
   `fixes <ISSUE-ID>` resolves the error natively when the release is deployed.

When the plan allows integration alert actions (Sentry Business for automatic GitHub issue
creation, Team for manual linking and chat alerts), switch to the native action — no relay and no
custom provisioning script. Decision record: owner decision DEC-V14-134 (2026-11-09).

Per-project activation checklist:

1. Org GitHub integration installed once in the error-tracking service (Settings → Integrations
   → GitHub) with access to the chrysa repos (needed for suspect commits and releases).
2. The repo has an error-tracking project whose slug matches the repo name.
3. CI sends releases and commits for every deployment.
4. The GitHub repo has a `sentry` label (CI label sync provides it).
