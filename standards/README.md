# standards

**Role.** The canonical chrysa standards corpus. `STANDARDS.chrysa.md` is the socle
distributed to every repo; `annexes/` holds the normative detail that is referenced, not
inlined.

## Structure

| Path                   | Purpose                                                              |
| ---------------------- | -------------------------------------------------------------------- |
| `STANDARDS.chrysa.md`  | the **only** distributed artifact — inlined into each repo's `CLAUDE.md` managed `chrysa:standards` block by `scripts/distribute-standards.sh` |
| `annexes/`             | normative annexes, referenced by URL from the socle, never inlined    |
| `README.md`            | this file                                                             |

## Should contain

- Rules that apply to **every** chrysa repo, or to a declared project profile.
- Adopted rules only (`GOVERNANCE.md` maturity ladder) — suggestions and open arbitrations
  belong in a *Deferred* section or in Notion.

## Should NOT contain

- Repo-specific rules — they live in that repo's `CLAUDE.md`.
- Audit reports, session notes, or migration plans — `docs/audits/`, `docs/plans/`.
- Numeric thresholds restated as prose — they come from the machine-readable contract
  (`GOVERNANCE.md` GV-030).

## Rules

- **No ghost rules.** A rule living only in an annexe, with no anchor in the socle, governs
  nothing. Every annexe is listed in the socle's *Normative annexes* section, and every
  annexe rule has a short anchor in the socle.
- **Stable ids.** Each annexe rule carries a unique id (`FE-010`, `AR-031`, …); ids are never
  reused, even after a rule is retired.
- **English only**, like the rest of the corpus.
- Editing the socle changes 68 repos on the next `distribute-standards` run — scope the diff
  and state the blast radius in the PR.
- `chrysa/standards` is deprecated and archived: never add there.
