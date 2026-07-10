---
name: standards-mcp
status: approved
author: chrysa <greau.anthony@gmail.com>
created: 2026-07-09
---

# Spec — Standards MCP server

## Context / problem

The chrysa fleet's norms and standards live in `shared-standards` as static files
(`standards/STANDARDS.chrysa.md`, `.chrysa/STANDARDS.md`, `.claude/thresholds.json`,
`repos.yml`) and as generated compliance snapshots (`compliance/*-conformance.json`).

Today these are consumed three ways, each lossy:

- **Duplicated** into each repo's `CLAUDE.md` / `.claude/rules/`, drifting out of sync
  and inflating static context on every session.
- **Read by hand** when someone needs "what's the current threshold / naming rule / stack".
- **Invisible cross-repo**: no single answer to "which repos deviate, and how", short of
  opening four JSON files and cross-referencing `repos.yml`.

Enforcement is already solved deterministically (hooks + CI). What is missing is a
**queryable, fleet-wide read surface**: a way for any agent, in any repo, to ask the
standards on demand instead of carrying a stale copy. This is the "norms" counterpart to
what CodeGraph/GitNexus already provide for code structure.

## Goals

- Expose the fleet standards as a small set of **read-only** MCP tools, callable from any
  repo over stdio (local, git-clone based — no server to operate to get started).
- Make `shared-standards` the **single source of truth**: tools read the existing files;
  no data is duplicated or re-parsed with new logic.
- Provide the **cross-repo compliance view** that no hook or skill can produce, in a shape
  the chrysa cockpit can consume.
- Reduce static context in downstream repos by letting agents fetch rules on demand.

## Non-goals

- **No enforcement.** The server never blocks, edits, or writes. Gating stays in
  hooks + CI (`verifiable-thresholds`, ruff/mypy/pytest). A read tool is non-deterministic
  by nature (called only if the model chooses to) and must never be a guardrail.
- **No new measurement.** The server surfaces compliance that is *already generated*
  (`compliance/*.json`, and optionally the hosted guideline-checker); it does not compute
  coverage, run linters, or scan repos itself.
- **No write/mutation tools** (e.g. editing `repos.yml`). If ever needed, that is a
  separate server with its own auth surface — not this one.
- **No hosted/HTTP deployment** in this iteration (stdio-local only; HTTP is a later step).

## Functional requirements

- FR1: Ship an MCP server entrypoint, runnable over **stdio**, exposed as a console script
  (`standards-mcp`) within the existing `standards-console` package.
- FR2: `standards_get(section?: str)` returns the fleet rules. Without `section`, returns
  all; with a section key (e.g. `thresholds`, `stack`, `naming`, `commits`,
  `class-design`) returns that subset. Sourced from `.claude/thresholds.json`,
  `.chrysa/STANDARDS.md`, and `standards/STANDARDS.chrysa.md`.
- FR3: `standards_audit_status(filter?: {section?, min_severity?})` returns per-repo
  compliance aggregated across the local `compliance/*-conformance.json` dimensions
  (makefile, docker, cliff, gitversion), sorted by non-compliance descending. Each entry:
  `{repo, score, deviations[]}`.
- FR4: `standards_diff(repo: str)` returns the deviations for a single repo:
  `[{dimension, gate, expected, actual}]`, plus its `repos.yml` classification
  (`status`, `runtime`) via `manifest.parse`.
- FR5: `standards_list_rules()` returns an introspectable catalogue of what the server
  knows: rule ids, their section, and source file — so an agent can discover what to ask.
- FR6: All file paths and tunables come from **Pydantic Settings** (extend the existing
  `config.py`), never hardcoded literals.
- FR7: Missing/unreadable source files degrade loudly (explicit error in the tool result),
  never silently return an empty/"all compliant" result.

## Acceptance criteria

- [ ] `standards-mcp` starts over stdio and lists exactly the 4 tools.
- [ ] `standards_get()` returns thresholds matching `.claude/thresholds.json`;
      `standards_get("thresholds")` returns only that subset.
- [ ] `standards_audit_status()` returns one entry per repo present in the compliance
      files, sorted with the most-deviating repo first, and a repo with a `FAIL` gate
      shows a non-empty `deviations` list.
- [ ] `standards_diff("<repo-with-known-FAIL>")` lists that failing dimension and includes
      the repo's `status`/`runtime` from `repos.yml`.
- [ ] `standards_list_rules()` enumerates every threshold key and every compliance
      dimension with its source file.
- [ ] A missing `compliance/` file surfaces an explicit error, not an empty table (FR7).
- [ ] Coverage on the new module **>= 85%**; ruff + mypy clean; no hardcoded paths.
- [ ] An example `.mcp.json` snippet documents the stdio-local wiring for a consumer repo.

## Constraints & dependencies

- **Reuse, do not reimplement**: `console/standards_console/manifest.py` (`parse`),
  `config.py` (`Settings`/`constants`). Add the `mcp` dependency to `console/pyproject.toml`.
- **Compliance source (stdio-local)**: primary = local `compliance/*-conformance.json`
  (offline, deterministic). The existing `compliance.py::ComplianceClient` targets the
  *hosted* guideline-checker server and is **out of scope as the primary source** here; it
  may later hydrate live data when a central URL is configured (see open questions).
- Python 3.12+ (3.14 target), Pydantic v2, ruff + mypy, hatchling — same toolchain as the
  `standards-console` package it lives in.
- Conventional Commits; branch `feature/standards-mcp`; base `develop`; squash merge.
- Repo is indexed by **GitNexus**: run `gitnexus_detect_changes()` before committing.
  This feature *adds* modules (no existing-symbol edits), so blast radius is expected null.

## Risks / open questions

- **Single vs hybrid compliance source.** Start with local JSON only (matches stdio-local).
  Open question: should `audit_status` optionally merge the hosted guideline-checker
  snapshot when `CENTRAL_BASE_URL` is set, and how to reconcile the two (dimension-based
  local vs errors/warnings hosted)? Defer to a follow-up unless trivial.
- **Freshness of local compliance files.** `compliance/*.json` are generated snapshots and
  can lag. The tool must report their staleness (e.g. file mtime / embedded timestamp) so a
  consumer never mistakes a stale snapshot for live truth.
- **Section taxonomy for `standards_get`.** The rules live in prose (`STANDARDS.chrysa.md`)
  plus structured JSON (`thresholds.json`). Prose sections may need light structuring (or a
  small index) to return clean subsets — to be settled in `/plan`.
- **Cockpit contract.** The exact JSON shape `audit_status` must emit for the chrysa
  cockpit should be pinned before implementation to avoid a second pass.
