# D-0015: Freeze the Python version policy (runtime 3.14 · ruff target py313)

- **Status:** Accepted
- **Date:** 2026-09-21
- **Deciders:** chrysa
- **Pillars touched:** portability, quality-gate consistency
- **Supersedes / Superseded by:** —

## Context

The canon already targets Python 3.14 (`STACK.chrysa.md`: "3.14 target, CI matrix
3.12 + 3.14"), but the fleet has drifted with no single authoritative statement to
point at. A sample of real repos found every combination live at once:

| Repo | `requires-python` | ruff `target-version` |
| ---- | ----------------- | --------------------- |
| `eka` | `>=3.11` | `py311` |
| `server` | `>=3.11` | *(unset)* |
| `chrysa-lib` | *(unset)* | `py313` |
| `project-init` | `>=3.14` | *(unset)* |
| `pre-commit-tools` | `>=3.14` | `py313` |
| `guardian-core` | `>=3.14` | `py314` |

The packaging standard (`docs/PYTHON-PACKAGING-STANDARD.md`) shows
`target-version = "py314"  # match requires-python`, but ruff on `py314` is broken
for the fleet (a resolver/target bug), which is why the working repos quietly run
`py313`. That workaround was never written down, so each repo re-decides and CI
lint results diverge across the portfolio. There is no frozen record that fixes the
version once, product-agnostically.

## Decision

Freeze one Python version policy for every Python project:

- **Runtime / images:** Python **3.14** (`python:3.14-slim` base, per `CONTAINERS-K3S.md`).
- **`requires-python`:** `">=3.14"` for new and active projects. `">=3.12"` is the
  only permitted lower floor, reserved for legacy packages not yet migrated; it is
  a documented exception, not a default.
- **ruff `target-version`:** `"py313"` **temporarily**, because ruff on `py314` is
  broken for the fleet. This is a deliberate, single deviation from
  `requires-python`; it does not change the runtime. Revert to `"py314"` once the
  ruff bug is fixed (see kill-test).
- **mypy `python_version`:** `"3.14"` (matches the runtime, unaffected by the ruff bug).
- **CI matrix:** `3.12` + `3.14`.

`STD-*` files are updated to match: the packaging-standard template carries
`target-version = "py313"` with the reason inline, and `STACK.chrysa.md` gains a
one-line pointer to this ADR.

## Fatal hypothesis

Pinning the runtime at 3.14 while holding ruff one minor back (`py313`) keeps lint
results identical across the fleet without breaking any 3.14 runtime feature —
i.e. no code the fleet writes needs a ruff rule that only `py314` targeting enables.

## Kill-test

If, by the next ruff minor that fixes `py314` (checked **2026-12-21**), a repo on
`target-version = "py313"` produces a lint result that differs from the same code
on a fixed `py314` — or a 3.14-only syntax feature the fleet adopts is mis-linted
under `py313` — the temporary deviation is harmful: bump every repo to `py314` in
one distribution pass and mark this clause resolved. If `py314` is still broken at
that date, re-date the check and keep `py313`.

## Validation gate

The `claude-md-facts-check` Python-version check (pyproject `requires-python` vs
doc claims) stays green fleet-wide, `STACK.chrysa.md` and this ADR agree, and a
`distribute-standards --dry-run` on a consumer refreshes only the managed block
carrying the frozen `py313`/`3.14` values.

## Options considered

| Option | Why not |
| ------ | ------- |
| `target-version = "py314"` everywhere now | The stated policy; but ruff `py314` is broken for the fleet, so it fails CI — the divergence this ADR exists to end. |
| Drop the floor to `>=3.11` to match `eka`/`server` | Ratifies drift downward; loses 3.12→3.14 features and contradicts the settled 3.14 target. Those two repos migrate up instead. |
| Leave each repo to choose | The observed failure: undocumented `py313` workaround re-decided per repo, inconsistent lint across the portfolio. |

## Consequences

Accepted costs: a temporary, documented gap between `requires-python` (3.14) and
ruff `target-version` (3.13) that a reader must not "fix" without checking this
ADR; one dated recheck owed on the ruff bug. Gains: one authoritative version
statement the whole fleet references, consistent lint output, and `eka`/`server`
get a clear migration target (3.11 → 3.14). Debt: the ruff-bug workaround must be
unwound when fixed (kill-test). Blast radius if Killed: bump `target-version` to
`py314` and re-run distribution.
