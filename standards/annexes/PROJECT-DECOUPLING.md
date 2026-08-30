# Annexe DC — Project independence & decoupling

> **Normative annexe.** Authority: `standards/STANDARDS.chrysa.md`. Rule ids (`DC-nnn`) are
> stable.
>
> **Mandatory rule:** every project stays autonomous, replaceable, and independently
> distributable. No project may depend on another project's internal organisation, files,
> database, or source code.

## 1. Principles

### DC-000 — Own lifecycle

Each project owns its versioning, deployment, documentation, data, and licence policy.

### DC-001 — Contracts only

Inter-project communication goes exclusively through **versioned public contracts**: a
published SDK, a documented API, or a documented WebSocket.

### DC-002 — No hard linkage

Forbidden: direct imports from a sibling repo, path dependencies, submodules used as runtime
links, and cross-project code copies.

### DC-003 — No private access

No direct access to another project's database, internal files, tables, or private models.

### DC-004 — A shared SDK is a product

Minimal public API, changelog, declared compatibility, deprecation policy. It does **not**
expose the provider's internals.

### DC-005 — Consumers wrap the contract

Each consumer wraps the external contract in a local adapter, so the provider can be
replaced, disabled, or removed without a global business rewrite.

### DC-006 — Contracts are complete

A contract states: input/output schemas, errors, authentication, timeouts, limits,
compatibility, recovery, and behaviour on unavailability.

### DC-007 — Network dependency ≠ structural dependency

Network dependencies are declared explicitly and must not be confused with a structural
dependency on the provider's code.

### DC-008 — Degrade cleanly

When a service becomes unavailable or deprecated, the consumer fails cleanly, disables the
affected capability, or switches to an alternative adapter — without compromising its core
function.

### DC-009 — Interchangeable external integrations go through a validated registry

When a product integrates **several interchangeable external systems of the same kind** — payment
providers, LLM providers (the `chrysa-LLM` gateway is the fleet instance of this), map/telemetry
vendors, notification channels, identity providers — the set is a **registry**, not a switch
statement. Each integration is:

- an **isolated module** (one per provider), never a branch in shared code — adding a provider
  adds a file, it never edits the dispatch logic (the socle *prefer a lookup table to a state
  machine* rule applied to integrations);
- configured by a **schema-validated** settings object, validated at load (external config is
  validated at runtime even when typed — socle rule), never trusted raw;
- **registered declaratively** (a registration decorator / a registry entry) and found by
  **autodiscovery** — there is no hand-maintained list of providers to edit when one is added
  or removed;
- reached only through a **single abstract contract** (the port, in the domain's language, per
  pillar 5) with **mandatory methods and explicit optional hooks** (a provider that does not
  support a capability overrides it as a documented no-op, rather than the caller special-casing
  that provider);
- **resolved at runtime per context** (per tenant / per territory / per environment) from
  configuration, through a proxy — the consumer names the capability, the registry binds the
  provider.

This is DC-005 (consumers wrap the contract) made concrete for the many-providers case: the
business code depends on the port and the registry, never on a provider's name. A hard-coded
`if provider == "X"` ladder, or a provider list the dispatcher must edit, is the defect this rule
removes.

### DC-010 — Library vs API: state ownership decides

DC-001 allows either a versioned SDK or a documented API as the contract form. The choice
is not performance — it is whether the shared object carries mutable state or an external
system of record:

- **No mutable state of its own** (pure logic, schemas, contracts, cross-cutting utilities):
  ship a **versioned library** (a package published from a GitHub release). In-process, no
  network cost, no separate deployment to keep alive.
- **Owns mutable state or an external system of record** (a database, a third-party service,
  a canonical registry another project also reads or writes): route through the **owner's
  API**, never a library that re-implements read/write access to it. A library here
  duplicates the owner's validation and mapping logic in every consumer and produces
  divergent state — two systems independently reading/writing the same external source is
  exactly the failure a canonical-owner API exists to prevent.

Network cost on the API path is a caching problem (a read-through cache at the consumer,
keyed on the queried identity), not a reason to bypass the owner. Extract shared logic into
a `DC-004` SDK once **two or more consumers** need the same non-stateful piece (a parser, a
mapper, an adapter) — extracting on the first consumer is premature.

______________________________________________________________________

## 2. Why

The rule protects a project's ability to be deprecated or replaced, open-sourced, sold
separately, deployed at a third party, maintained on a different cadence or stack, or
extracted from the portfolio without breaking the others.

______________________________________________________________________

## 3. CI checks (progressive rollout)

- imports from a sibling repo or an unpublished internal namespace;
- path dependencies, symlinks, or code mounts between projects in production;
- direct access to another project's database or private storage;
- hardcoded service URLs, ports, paths, or identifiers;
- copy of another project's business model without a compatibility contract;
- dependency on an unversioned API or one with no deprecation policy;
- a library that reads or writes a stateful external source another project already owns
  through a canonical API (DC-009) — including a local cache used to justify the bypass.

______________________________________________________________________

## 4. Minimum requirements for an inter-project contract

Identified owner and consumers · contract version · documentation and examples · contract
tests on **both** provider and consumer sides · a local mock/fake for offline development ·
migration strategy and compatibility window · licence policy with a clear OSS/commercial
split.

______________________________________________________________________

## 5. Architectural consequence

Relations documented in Notion represent **contract or consumption** relations. They are
never an authorisation to create a hard link between codebases.
