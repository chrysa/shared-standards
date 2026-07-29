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
- dependency on an unversioned API or one with no deprecation policy.

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
