# Auto-maintained documentation — design

- **Date**: 2026-10-10
- **Author**: owner + Claude
- **Status**: proposed (awaiting review)
- **Canon repo**: `chrysa/shared-standards`

## Intent

Today the canon says documentation must be kept in lockstep with the code
(`standards/rules/docs.md`, rule "Documentation and Notion are maintained in lockstep").
That is a human obligation checked in review: nothing fails when a doc goes stale.

The owner wants the opposite default: **reference documentation is regenerated from the
code, and a deterministic gate fails when it has drifted.** Prose stays human-written.

### Decisions already taken with the owner

| Question | Decision |
| --- | --- |
| Scope of "automatic" | Generate reference docs from code **and** block drift. **No** LLM bot that writes prose. |
| Architecture | Extend the existing generator pattern (`gen_context_files.py` + `context-files-drift`) with a sibling generator. Not `doc-gen`, not a per-language monolith. |
| Gate severity | Block only what is deterministic. Everything heuristic is a warning. |

### Non-goals

- Writing or rewriting narrative prose (README intro, ADR rationale, runbooks).
- Replacing `doc-gen` (the docs-site generator behind `pages.yml`); this feature only
  produces the *reference* pages such a site can publish.
- Notion logging (separate rule, unchanged).
- A mass-README catch-up PR across the fleet (forbidden by the `folder-readme` rule).

## Success criteria

1. In an opted-in repo, changing a route, a data model or a component and committing
   without regenerating the reference docs **fails locally** (pre-commit), without needing
   GitHub Actions.
2. Re-running the generator twice, from different working directories and on a different
   OS, produces **byte-identical** output.
3. A new directory without a `README.md` fails the same gate.
4. A repo with no recognised stack passes the gate and generates nothing (no crash, no
   empty files).
5. No code of the target repo is imported or executed by the generator.

## Design

### 1. Components

- `templates/gen_docs.py`, distributed to each repo's `scripts/` by
  `distribute-standards.sh`, exactly like `gen_context_files.py`. It is a **sibling**, not
  an extension of that file, so each script keeps a single responsibility.
- **Extractors**, one module per concern, each exposing `detect(root) -> bool` and
  `render(root) -> str`:

  | Extractor | Source read (static) | Output |
  | --- | --- | --- |
  | `structure` | tracked files | directory tree with the folder-README coverage |
  | `routes` | FastAPI route decorators via `ast` | method, path, handler, response model |
  | `data-model` | Django `models.py` via `ast` | models, fields, relations |
  | `components` | React component files (name, exported props type) | component inventory |

  The initial set is deliberately these four. New extractors are additive.
- **Static extraction only.** Extractors parse source text (`ast`, text scanning). They
  never `import` the project, run its code, or need its dependencies installed. This keeps
  the generator machine-agnostic and safe to run in pre-commit.
- **Output**: either a fully generated file under `docs/reference/<name>.md`, or a block
  between markers inside an existing file:

  ```markdown
  <!-- chrysa:docs:<name>:start -->
  ...generated...
  <!-- chrysa:docs:<name>:end -->
  ```

  The generator writes only inside these markers or inside its own `docs/reference/` files.
  Everything outside the markers is left byte-identical.
- **Opt-in and selection**: a repo lists its extractors under a `docs:` key in
  `project-profile.yml`. If the key is absent, stack detection picks the matching
  extractors. A repo with none matching generates nothing.

### 2. Determinism contract

Same contract as `gen_context_files.py`: stable ordering, sorted lists, **no timestamps,
dates, absolute paths, hostnames or random values**. Paths are repo-relative with `/`
separators. Source files are read as UTF-8 with `\n` newlines normalised. Anything that
cannot be parsed degrades to a clearly marked `(not available)` entry, never to a crash and
never to a differing output.

### 3. The gate

- New pre-commit hook `docs-drift`: `python -m scripts.gen_docs --check`. It regenerates in
  memory and compares with the working tree. Exit 1 on any difference, printing the
  extractor and file that drifted and the command that fixes it (`python -m
  scripts.gen_docs`).
- It runs in **pre-commit** (works while GitHub Actions is unavailable), and is replayed in
  the lint gate of the canonical `release.yml`, consistent with the canon's rule that lint
  lives in pre-commit and is replayed at release.
- **Blocking checks** (deterministic): generated docs out of date; a **newly created**
  directory containing source files and no `README.md`. "Newly created" means no tracked
  file existed in that directory at the base commit, so existing directories are never
  retroactively flagged. The base commit is `HEAD` when run as a pre-commit hook (the
  directory is new in the staged change) and the merge-base with the default branch when
  replayed at release.
- **Warning only** (heuristic, never fails): source files changed under a path an extractor
  covers while no `docs/` or `README.md` file changed in the same change set.

### 4. Canon rule and decision record

- Edit the rule in `standards/STANDARDS.chrysa.md` (the canon), then run
  `make gen-agent-views` so `standards/rules/docs.md`, `CORE.chrysa.md`, `AGENTS.md` and the
  Copilot view are regenerated. These generated files are **never hand-edited**.
- The rule changes from "docs are updated in the same PR" (human duty) to: reference docs are
  generated and drift-gated; prose is human and covered by the warning; the lockstep duty
  remains for prose.
- One ADR in the chrysa refutable format:
  - **Fatal hypothesis**: static extraction is byte-stable across machines and OSes.
  - **Kill-test**: the `docs-drift` gate fires on a change that did not alter the code
    surface (a false positive) in more than a threshold of pilot repos within two weeks of
    activation. Proposed threshold: 1 repo of 4 (shared-standards + 3 pilots); the ADR fixes
    the final number and cadence.
  - **Validation gate**: dogfood on shared-standards plus the three pilots before any fleet
    distribution.

### 5. Rollout

1. Dogfood in `shared-standards` (repo #1).
2. Pilots, one per stack: `devtool` (FastAPI + React), `django-migration-analyzer`
   (Django), `logos` (library, no recognised stack, proves the empty path).
3. Distribute `gen_docs.py` and the hook with `distribute-standards.sh`. Per repo, the first
   PR generates the initial docs; the hook becomes active in that repo only once those docs
   are committed, so a repo is never blocked by a drift it has not yet had the chance to
   fix.

### 6. Tests (in `shared-standards/tests/`)

- Golden files per extractor from small fixture repos.
- Determinism test: two runs, different working directories, compare bytes.
- Robustness test: unparsable file, missing README, empty repo, file with CRLF newlines.
- Marker test: content outside the markers is byte-identical after a run.
- Gate test: `--check` exits 0 on a clean tree, 1 after a source change, 0 again after
  regeneration.
- New-directory README test using a temporary git repository.

## Risks and open points

- **GitHub Actions is currently unavailable** (billing). The design does not depend on it:
  pre-commit is the primary gate. The release replay cannot be verified until Actions runs.
- **AST extraction is incomplete by nature** (dynamic routers, `include_router` prefixes,
  generated models). The extractor must report what it could not resolve instead of guessing;
  the documented limit is part of the generated block.
- **Folder-README rule scope**: the hook flags new directories only. Whether it should also
  cover moved directories is left to the plan.
- **Which docs a repo must carry** (README, ARCHITECTURE, data model, routes, component
  inventory) comes from the canon's required-files list; this spec does not change that list.
- **Final kill-test threshold** is a proposal until the ADR is written.
- **Plan phasing**: the implementation plan may deliver this in slices (core + `structure` +
  gate first, then `routes`, `data-model`, `components`), each independently shippable and
  each gated by the dogfood before the next.
