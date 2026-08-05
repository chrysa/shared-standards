# Annexe AR — Architecture: project profiles & proportionate DDD

> **Normative annexe.** Authority: `standards/STANDARDS.chrysa.md`. Rule ids (`AR-nnn`) are
> stable. Canonical decision: projects use a DDD/hexagonal architecture **proportionate to
> their business complexity**. The domain stays independent of frameworks and infrastructure,
> but small tools are not over-architected.

## 1. Profiles & DDD level

### AR-000 — Every repo declares a profile

| Profile          | What it is                                                          |
| ---------------- | ------------------------------------------------------------------- |
| `library`        | published package — minimal public API, semver, compatibility policy |
| `service`        | standalone API or network service                                    |
| `frontend`       | TypeScript/React app consuming published contracts                   |
| `worker`         | async processing, scheduler, or independent consumer                 |
| `cli`            | command-line tool                                                    |
| `game`           | C#/Unity (or equivalent engine) with domain/runtime separation       |
| `infrastructure` | chart, manifests, operator, platform component                       |

### AR-001 — Every repo declares a DDD level

| Level   | Use                                          | Requirement                                                    |
| ------- | -------------------------------------------- | -------------------------------------------------------------- |
| `DDD-0` | scripts, migrations, small technical tools    | simple structure, testable functions, no imposed ceremony       |
| `DDD-1` | CRUD with limited rules                       | domain/application/adapters split where it clarifies ownership  |
| `DDD-2` | significant business domain                   | entities, value objects, aggregates, invariants, domain events  |
| `DDD-3` | complex or distributed domain                 | bounded contexts, ACLs, integration events, targeted CQRS       |

### AR-002 — Declaration file

Declared once per repo, machine-readable:

```yaml
project_profile: service
architecture_style: ddd-hexagonal
ddd_level: 2
bounded_context: task-management
standards_version: "1"
```

______________________________________________________________________

## 2. Common architecture (all languages)

```text
Entrypoints / Presentation
          ↓
      Application
          ↓
        Domain
          ↑
Infrastructure / Adapters
```

### AR-010 — Domain

- Holds the business language, rules, and invariants.
- Depends on **no** web framework, ORM, filesystem, network transport, or vendor SDK.
- Never depends on API DTOs or persistence models.
- Protects state transitions behind explicit business methods.
- Uses value objects when identity, unit, validation, or immutability carry business meaning.

### AR-011 — Application

- Orchestrates use cases and transactions; coordinates ports.
- Owns application-level authorisation, idempotency, and units of work.
- Does **not** hold core invariants.
- Introduces commands/handlers/CQRS only when complexity justifies it.

### AR-012 — Infrastructure

- Implements the persistence, transport, file, cache, broker, and external-service ports.
- Translates technical errors into application errors.
- Never leaks into the domain; stays replaceable behind local interfaces/adapters.

### AR-013 — Aggregates

- One root per aggregate; the root protects the invariants.
- Public setters and uncontrolled mutation are forbidden.
- A business transaction ideally modifies a single aggregate.
- Aggregates reference each other by **identifier**, not by full persisted graphs.
- Aggregates stay small and coherent.

______________________________________________________________________

## 3. Boundaries between projects & bounded contexts

### AR-020 — Nothing internal crosses a project boundary

Entities, aggregates, business repositories, and ORM models are **never shared** between
projects. Two bounded contexts may hold same-named concepts with different models.

### AR-021 — Contracts only

Exchanges use versioned SDK / API / WebSocket contracts with dedicated contract DTOs.
Each consumer owns an Anti-Corruption Layer (or local adapter) translating the external
contract into its own domain. Detail: [`PROJECT-DECOUPLING.md`](PROJECT-DECOUPLING.md).

### AR-022 — Events

Domain events stay internal. Only **versioned integration events** cross a boundary.

______________________________________________________________________

## 4. Python

### AR-030 — Structure for DDD-2 / DDD-3

```text
src/<package>/
├── domain/          # entities/ value_objects/ aggregates/ events/ services/
├── application/     # use_cases/ commands/ queries/ ports/
├── infrastructure/  # persistence/ messaging/ external/
└── interfaces/      # api/ cli/ workers/
```

### AR-031 — Rules

- `pyproject.toml` is the canonical source (see the socle's packaging rule).
- `[project]` for runtime deps; dependency groups for test, lint, docs, dev.
- One canonical lockfile is committed for applications and services; published libraries
  declare compatible constraints without imposing their own resolution on consumers.
- Ruff does format + lint; pick **one** reference type checker (mypy or Pyright) per repo.
- `import-linter` guards layers and forbidden imports; `deptry` guards dependency declaration.
- Pydantic is for boundaries and DTOs — not a systematic replacement for domain objects.
- No FastAPI, Django ORM, SQLAlchemy, HTTP client, or broker import inside `domain/`.
- Time, UUID, randomness, and external effects are injectable.
- `Any` outside an adapter must be justified.

### AR-032 — FastAPI async correctness

`async def` is used when the execution path is genuinely non-blocking and awaitable;
blocking libraries use `def` (or explicit offloading). An `async def` route hiding a
significant blocking call is a defect.

### AR-033 — Minimum Python gate

```text
ruff format --check
ruff check
mypy | pyright
lint-imports
deptry .
pytest
lockfile check
```

______________________________________________________________________

## 5. C# / .NET

### AR-040 — Canonical files

`Directory.Build.props` · `Directory.Packages.props` (central NuGet versions) ·
`.editorconfig` · `global.json` when the SDK version must be pinned · `.slnx`/`.sln`
depending on toolchain support.

### AR-041 — Build baseline

Nullable reference types on · warnings as errors in CI · .NET analyzers at the recommended
level · style enforced during build · deterministic builds · centrally versioned packages ·
`dotnet format --verify-no-changes`, build, tests, and analyzers in CI.

### AR-042 — Structure

```text
src/    Product.Domain/ Product.Application/ Product.Infrastructure/ Product.Contracts/ Product.Api/
tests/  Product.Domain.Tests/ Product.Application.Tests/ Product.Infrastructure.Tests/
        Product.Contract.Tests/ Product.Architecture.Tests/
```

### AR-043 — Rules

- `Domain` references neither EF Core nor ASP.NET Core.
- Immutable value objects; invariants protected; no public setters on aggregates.
- `DbContext` confined to infrastructure; API DTOs distinct from entities.
- `CancellationToken` propagated through async operations.
- Typed configuration, validated at startup; DI scopes validated.
- Boundaries covered by architecture tests.

### AR-044 — Unity / games

- Separate domain and simulation rules from the Unity runtime where possible.
- Limit direct `MonoBehaviour` dependencies in the business core.
- `ScriptableObject` = data/configuration, not a global mutable logic container.
- Game loop, rendering, input, and Unity services are adapters around the domain.
- Critical systems are deterministic and testable outside a scene.

### AR-045 — A game is DRM-free and fully playable solo offline

The single-player experience is **complete without a network, an account, or a licence
check**. Unplug the machine and the game still starts, saves, loads, and can be finished.

- **No DRM of any kind** — no licence server, no phone-home activation, no online
  entitlement check, no always-on requirement, no third-party wrapper (Denuvo and
  equivalents) that gates launch. A copy someone owns keeps working when the servers are
  gone, the company is gone, or the network is down. A build that will not start offline is
  a defect, not an anti-piracy measure.
- **Saves are local, open, and portable** — a readable format (JSON/SQLite) under the
  platform's standard user directory, copyable to another machine, not tied to an account or
  encrypted against its owner. This is the strategic pillar *portable personalisation data*
  applied to a save file.
- **Online is additive, never load-bearing.** Multiplayer, leaderboards, cloud sync,
  telemetry and stores are opt-in layers over a complete offline game. Losing any of them
  degrades a feature; it never blocks the campaign, the progression, or the ability to launch.
- **No content behind a live service in a single-player game** — assets, levels and unlocks
  ship in the build. A "day-one download" that gates the game itself, or content streamed
  from a server that will one day be switched off, breaks the guarantee.
- **The offline path is tested, not assumed** — a build is validated with the network
  disabled, on a machine that has never signed in. An offline mode nobody exercises is an
  offline mode that has already stopped working.

This applies to any repo declaring the `game` profile, whatever the engine.
