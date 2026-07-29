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
IPs, or ports · probes, resource limits, and security policies present.

______________________________________________________________________

## 5. Exception

A genuinely standalone distribution outside k3s may need a different topology. It ships as a
**separate profile or artifact**, with an explicit ADR — it never modifies the canonical
application image nor imposes that coupling on portfolio deployments.
