---
name: standards-mcp
status: approved
spec: docs/specs/standards-mcp.md
created: 2026-07-09
---

# Plan — Standards MCP server

## Summary

Add a thin, read-only MCP server **inside the existing `standards-console` package**
(`console/standards_console/`), exposed as a `standards-mcp` console script running over
stdio. It reuses the package's existing building blocks — `config.Settings`/`constants`
for configuration and `manifest.parse` for `repos.yml` — and adds two small, pure,
I/O-free reader modules (`rules_reader`, `compliance_reader`) plus an MCP entrypoint that
wires four tools over them. No new parsing logic duplicates what already exists, and no
constant is inlined (all paths/tunables go through Pydantic Settings + `constants.yaml`).
For stdio-local the compliance source is the local `compliance/*-conformance.json` files
resolved from a new `repo_root` setting; the hosted guideline-checker (`ComplianceClient`)
stays out of the primary path (follow-up).

## Files to touch

| File | Change |
| ---- | ------ |
| `console/standards_console/config.py` | Add `repo_root: Path` setting (env `STANDARDS_REPO_ROOT`, default = repo root relative to this file) + `thresholds_path` / `compliance_dir` derived properties. |
| `console/standards_console/constants.yaml` | Add `standards.*` section: threshold section keys, compliance dimension→file map, section taxonomy for `standards_get`. |
| `console/standards_console/config.py` (Constants) | Add `StandardsConstants` model + wire into `Constants`. |
| `console/standards_console/rules_reader.py` | **New.** Pure readers: `load_thresholds()`, `load_standard_sections()`, `list_rules()` → return typed dicts from `thresholds.json` + the two standards `.md` files. |
| `console/standards_console/compliance_reader.py` | **New.** Pure readers over local `compliance/*.json`: `audit_status(filter)`, `repo_diff(repo)`; each row keyed by `repo`, deviation = any row whose `gate` is `FAIL`/`warn`; attaches source-file mtime for staleness (FR7 + freshness risk). |
| `console/standards_console/mcp_server.py` | **New.** `create_server()` registering 4 tools (`standards_get`, `standards_diff`, `standards_audit_status`, `standards_list_rules`) + `main()` stdio entrypoint. Each tool ≤ 40 lines, delegates to the readers. |
| `console/pyproject.toml` | Add `mcp>=1.6` dependency; add `[project.scripts] standards-mcp = "standards_console.mcp_server:main"`. |
| `console/tests/test_rules_reader.py` | **New.** Unit tests for rules readers. |
| `console/tests/test_compliance_reader.py` | **New.** Unit tests for audit/diff over fixture JSON. |
| `console/tests/test_mcp_server.py` | **New.** Tool-level tests calling the registered handlers directly. |
| `console/tests/fixtures/` | **New.** Minimal `compliance/*.json` + `thresholds.json` + `repos.yml` fixtures with a known `FAIL` row. |
| `console/README.md` | Document `standards-mcp`, env vars, and an example `.mcp.json` stdio-local snippet. |

## Steps

1. **Config plumbing** — extend `Settings` with `repo_root` + derived `thresholds_path`
   (`.claude/thresholds.json`), `compliance_dir` (`compliance/`), and standards `.md`
   paths. Add `StandardsConstants` (section taxonomy + dimension→file map) to
   `constants.yaml`/`Constants`. *(commit: `feat(console): repo-root + standards config)`)*
2. **`rules_reader`** — implement `load_thresholds`, `load_standard_sections`
   (light section split of the two `STANDARDS*.md`), `list_rules`. Loud errors on missing
   files. *(commit: `feat(console): standards rules reader`)*
3. **`compliance_reader`** — implement `audit_status(filter)` and `repo_diff(repo)` over
   local `compliance/*.json`, merging `manifest.parse` classification into `repo_diff`,
   sorting audit by deviation count desc, attaching per-file mtime. *(commit:
   `feat(console): local compliance reader`)*
4. **`mcp_server`** — register the 4 tools with typed args/returns, `main()` runs stdio
   transport; server `instructions` mirror the spec's non-goals (read-only). *(commit:
   `feat(console): standards MCP server (stdio)`)*
5. **Packaging** — add `mcp` dep + console script; verify `standards-mcp` launches and
   enumerates 4 tools. *(commit: `chore(console): expose standards-mcp entrypoint`)*
6. **Tests + docs** — fixtures, 3 test modules to ≥ 85 %, README + `.mcp.json` example.
   *(commit: `test(console): cover standards MCP` / `docs(console): standards-mcp usage`)*
7. **Pre-commit gate** — `gitnexus_detect_changes()` (expect additions only), ruff +
   mypy + pytest green, open PR `feature/standards-mcp` → `develop`.

## Tests

- `test_rules_reader`: `load_thresholds()` equals fixture `thresholds.json`;
  `load_standard_sections()` returns a known section; missing file raises. → AC #2, FR7.
- `test_compliance_reader`:
  - `audit_status()` returns one entry per fixture repo, most-deviating first, `FAIL`
    row yields non-empty `deviations`. → AC #3.
  - `repo_diff("<fail-repo>")` lists the failing dimension + `status`/`runtime` from
    `repos.yml`. → AC #4.
  - missing `compliance/` file raises (not empty). → AC #6, FR7.
- `test_mcp_server`: server exposes exactly the 4 tool names; `standards_get()` vs
  `standards_get("thresholds")` subset; `standards_list_rules()` enumerates every
  threshold key + dimension with source file. → AC #1, #2, #5.
- All DB-free / network-free: readers are pure over fixture files; no `ComplianceClient`
  HTTP in tests.

## Risks & rollback

- **Additive only.** New modules + new console script; no existing symbol edited, so
  GitNexus blast radius is null and rollback = delete the new files + revert the two
  `pyproject.toml`/`constants.yaml`/`config.py` hunks. No migration, no data change.
- **Stale local compliance snapshots** — mitigated by surfacing per-file mtime in tool
  output (freshness risk from spec). Hosted-live merge deferred.
- **Section taxonomy** for `standards_get` on prose `.md` — kept deliberately simple
  (heading-based split driven by `constants.yaml`); if a consumer needs finer structure,
  extend the taxonomy without touching tool signatures.
- **`repo_root` resolution** — default derived from the module location; overridable via
  `STANDARDS_REPO_ROOT` so a consumer repo cloning `shared-standards` elsewhere can point
  at it. Wrong root → loud error, never silent empty.

## Standards checklist

- [x] ≤40 lines/function, ≤300 lines/file, ≤5 args, complexity ≤10
- [x] ruff-check + ruff-format clean; mypy clean
- [x] No hardcoded constants — all paths/tunables via `Settings` + `constants.yaml`
- [x] Pure reader modules (business logic) separated from the thin MCP tool layer
- [x] Coverage ≥ 85% on new modules (98%)
- [x] Conventional Commits; branch `feature/standards-mcp`; base `main` (real default)
- [ ] `gitnexus_detect_changes()` run before commit (expect additions only)
