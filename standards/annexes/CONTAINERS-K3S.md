# Annexe CT — Containers, images & k3s

> **Normative annexe.** Authority: `standards/STANDARDS.chrysa.md`. Rule ids (`CT-nnn`) are
> stable. The socle states the **minimum** (multi-stage with a `production` and a `dev`
> target, hot-reloading `dev`, mandatory `.dockerignore`/`HEALTHCHECK`/pinned base, no
> reverse proxy in an app container). This annexe details the reference shape and the
> platform side. Where the two disagree, the socle wins.

## 1. Image build

### CT-000 — Reference stage shape

The socle requires `production` + `dev`. Beyond that minimum, the reference shape is:

```dockerfile
FROM python:3.14-slim AS base
FROM base         AS dependencies
FROM dependencies AS development
FROM dependencies AS test
FROM dependencies AS build
FROM base         AS runtime
FROM runtime      AS production
```

Exact names may vary; **responsibilities must stay explicit**, and `production` and `dev`
must exist under those names (socle requirement).

### CT-001 — Stage rules

- Share common setup in `base`.
- Isolate dependency install/build in dedicated stages **and in their own layers** to exploit
  the Docker cache: copy the manifests alone (`pyproject.toml` + lockfile, `package.json` +
  lockfile), install, **then** copy the source. Copying sources before installing rebuilds
  every dependency on each code change and is a defect.
- `development` may carry debug, quality, and test tooling.
- `test` must run the suite reproducibly.
- `build` produces only the runtime artifacts.
- `production` is minimal, non-root, with no compilers, caches, sources, or dev tooling.
- Targeted `COPY` so dependency layers are not invalidated needlessly.
- Build secrets are never persisted in a layer — BuildKit secrets or pipeline injection only.
- Each target is buildable explicitly with `--target`.

### CT-002 — Image hygiene

Pinned base images · mandatory `.dockerignore` · correct signal handling and graceful
shutdown · read-only filesystem where possible · OCI labels, SBOM, vulnerability scan ·
**no `latest` tag for a deployment**.

### CT-003 — Image build CI checks

Named stages present · a distinct production target exists · non-root runtime user unless
documented otherwise · no build/dev tooling in the final image · vulnerability, size, and
content analysis · required targets built and tested before publish.

______________________________________________________________________

## 2. Container responsibility

### CT-010 — One coherent concern per container

An application container holds the application and the processes strictly required for its
own concern. It may spawn child processes serving that same concern; it does not host a
second product.

### CT-011 — No embedded reverse proxy

No Traefik, Nginx, Caddy, Apache, or HAProxy inside an application container. The container
exposes its internal application port and handles **no** public certificate, TLS
termination, multi-domain routing, or global service discovery.

### CT-012 — Sidecars are justified or absent

A sidecar is allowed only for a narrowly related technical responsibility, explicitly
justified. It must not be used to bypass project separation or to smuggle in a reverse proxy.

### CT-013 — Separate workloads

Workers, schedulers, and async processing are deployed as separate workloads when they have
a distinct lifecycle, scaling, or resource profile. Databases, brokers, and observability
components are never folded into the application image.

### CT-014 — Addresses come from deployment

External addresses, ports, domains, and certificates are supplied by deployment
configuration, never baked into the image.

### CT-015 — Only a publicly useful port is published; everything else stays on the network

A container port is **published to the host only when a human or an external system outside
the stack genuinely consumes it** — in practice the public entry point of the product, and
nothing else. Every other port stays inside the container network, where services reach each
other by service name over the shared network.

Published by default: **nothing**. Reachable from outside: the app's own HTTP port fronted by
the platform layer (see CT-011), or the platform's own front.

**Stays internal — publishing it is a defect:** databases and their admin ports, caches,
brokers and their management UIs, search engines, object storage, internal APIs and gRPC
services, metrics/`/debug` endpoints, mail catchers, dev tooling, and the app's own port when
a reverse proxy already fronts it.

```yaml
services:
    api:                       # the one public surface
        ports:
            - "8000:8000"      # published on purpose
    database:
        image: postgres:16
        expose:
            - "5432"           # reachable as `database:5432` on the network — not published
    redis:
        image: redis:7         # no ports:, no expose: needed — service DNS is enough
```

Three consequences that make this a rule and not a preference:

1. **`ports:` is a firewall hole.** On a Docker host, a published port is inserted straight
   into `nftables`/`iptables` *ahead of* `ufw`/`firewalld` — the host firewall does not filter
   it. `ports: "5432:5432"` puts the database on the public internet even on a machine whose
   firewall denies everything.
2. **A port published to `0.0.0.0` binds every interface**, including the ones you forgot.
   When a host-side tool genuinely needs access (a migration run from the host, a debugger),
   bind the loopback explicitly — `127.0.0.1:5432:5432` — and treat it as a local development
   affordance, never a deployment default.
3. **Two stacks publishing the same port collide.** Internal-only services can keep their
   canonical port in every project; publishing forces per-project port arithmetic that nobody
   documents and everybody re-derives.

Kubernetes states the same rule with its own vocabulary: every `Service` is `ClusterIP`
unless it is the ingress-fronted entry point. `NodePort`, `LoadBalancer`, and
`hostPort`/`hostNetwork` are exposures of last resort, each requiring an ADR — a `hostPort`
also silently bypasses `NetworkPolicy` (CT-023).

Development compose files follow the same rule; a port opened "just to look at it" is opened
on the loopback, in an override file, never in the committed base stack.

### CT-016 — The image version and the application version are two different things

An image and the application it packages have separate lifecycles: rebuilding on a patched
base image, a new OS library or a changed entrypoint yields a **new image version carrying
the same application version**. Both are recorded, and neither is inferred from the other.

Every image carries OCI labels, injected as build arguments by CI and never hand-edited:

```dockerfile
ARG APP_VERSION
ARG IMAGE_VERSION
ARG GIT_SHA
ARG BUILD_DATE
LABEL org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="https://github.com/chrysa/<repo>" \
      chrysa.application.version="${APP_VERSION}"
```

Deployments reference an **immutable digest** (`image@sha256:…`), never `:latest` — a moving
tag makes "what is running" unanswerable and breaks *build once, promote the artefact*
(`CI-046`). A rollback is then a digest change, not a rebuild.

### CT-017 — A running workload states which build it is

Every service exposes its identity on a lightweight endpoint (`/version`, or the health
payload): application version, image tag **and digest**, git SHA, build timestamp,
environment name. It carries no secret and no dependency inventory — enough to answer
"which build is this?", nothing more, so it stays safe behind the same exposure rules as the
rest of the API.

The value is read from the environment injected at deploy time (`APP_VERSION`, `IMAGE_DIGEST`,
`GIT_SHA`), never hardcoded and never derived from a file inside the image that a rebuild
would not update.

### CT-018 — Deployed versions are visible to an operator without a shell

The admin surface of the product shows the **frontend build version** — embedded at build
time — alongside the backend's application version, image digest and environment. `kubectl`
or `docker inspect` is a fallback for a debugging session, not the primary way to answer
"what is deployed right now".

When the frontend detects that the backend version changed under it, or that its build no
longer matches the API it talks to, it says so and offers a reload instead of failing in
obscure ways.

______________________________________________________________________

## 3. Expected k3s topology

```text
Internet / network
        ↓
cluster Traefik (k3s)
        ↓
Ingress / IngressRoute / Service
        ↓
scoped application pod
        ↓
application process only
```

Forbidden anti-pattern:

```text
application pod/container
├── application
├── embedded reverse proxy
├── public TLS management
└── routing to other projects
```

______________________________________________________________________

## 4. k3s workload baseline

### CT-020 — Probes

`readinessProbe` mandatory · `startupProbe` for slow starts · `livenessProbe` only when it
provides useful recovery.

### CT-021 — Resources

CPU/memory `requests` mandatory; `limits` set deliberately.

### CT-022 — Security context

`runAsNonRoot: true` · `allowPrivilegeEscalation: false` · all capabilities dropped by
default · read-only root filesystem where compatible · dedicated service account, token not
mounted when unnecessary.

### CT-023 — Network & secrets

`NetworkPolicy` matching the allowed flows · secrets injected by the platform, never in the
image · external exposure exclusively via `Service` + the cluster Traefik.

### CT-024 — Deployment CI checks

Reverse-proxy install/config detected in an app image · number of responsibilities embedded ·
Kubernetes exposure goes through a Service + a Traefik-compatible routing resource · no
private certificates or public TLS config in images · no hardcoded infrastructure domains,
IPs, or ports · probes, resource limits, and security policies present · **published ports
counted per compose file (CT-015): a `ports:` on a database, cache, broker, or metrics
endpoint fails the check, and a `0.0.0.0` publish outside the public entry point is
flagged** · **OCI version labels present and non-empty, and deployment manifests referencing
a digest rather than a moving tag (CT-016)**.

______________________________________________________________________

## 5. Exception

A genuinely standalone distribution outside k3s may need a different topology. It ships as a
**separate profile or artifact**, with an explicit ADR — it never modifies the canonical
application image nor imposes that coupling on portfolio deployments.
