# Annexe SC — Source control collaboration (issues & pull requests)

> **Normative annexe.** Authority: `standards/STANDARDS.chrysa.md`. Domain: `STD-SCM-001`.
> Rule ids (`SC-nnn`) are stable — never reuse an id for a different rule. This annexe details
> the **content shape of issues and pull requests by type**; the surrounding git conventions
> (Conventional Commits, the `main`/`develop` branch model, squash-merge, one-PR-per-issue,
> `enforce-issue-link`) are stated in the socle and are not restated here. Where the two
> disagree, the socle wins. Applies to every repository in the fleet.

## SC-000 — Why type-driven templates

An issue or a PR whose shape depends on its **type** is reviewable in seconds: a reviewer of a
`fix` knows to look for a root cause and a regression test, a reviewer of a `feat` for acceptance
criteria and a UI proof. A free-text issue or a one-line PR forces every reviewer to reconstruct
the same missing context by hand, and the important field (the reproduction, the rollback, the
measurement) is the one that gets skipped. The type is not decoration — it selects a **committed
template** whose required fields are exactly what that kind of change needs, and it is the single
label a triage or an automation keys off. A repo where issues and PRs are unstructured free text
is a defect, not a lighter process.

## SC-010 — The issue-type taxonomy is fixed and label-carried

Every issue declares **exactly one type**, expressed as a canonical label from the fleet label
set (`.github/labels.yml`, synced by `sync-labels`). The type set is closed — a new type is a
change to this annexe, not an ad-hoc label:

| Type          | Label           | For                                                        |
| ------------- | --------------- | ---------------------------------------------------------- |
| Bug           | `bug`           | Something is broken vs. its intended behaviour             |
| Feature       | `feature`       | New user-visible capability                                |
| Enhancement   | `enhancement`   | Improve an existing capability (no new surface)            |
| Chore         | `chore`         | Maintenance with no behaviour change (deps, config, tidy)  |
| Documentation | `documentation` | Docs / ADR / standards content only                        |
| CI/CD         | `ci`            | Pipeline, gates, release plumbing                          |
| Security      | (security form) | Vulnerability / hardening — handled privately (SC-013)     |
| Research      | `research`      | A time-boxed spike answering an open question              |
| Epic          | (epic form)     | A tracking parent decomposed into typed child issues       |

Cross-cutting labels (`priority: {high,medium,low}`, `blocked`, `wip`, `deferred`, `dependencies`,
`automated`, `sentry`, `sonar`) **stack on top of** the one type label; they never replace it.
Two type labels on one issue, or a type invented outside this table, is a triage defect.

## SC-011 — Each issue type has a committed structured template

Issue creation is driven by a **structured form** per type, committed under
`.github/ISSUE_TEMPLATE/*.yml` (GitHub issue-forms) and distributed/kept in sync by
`project-init`. Each form applies its type label automatically and requires the fields that type
needs:

| Type          | Required fields (beyond a title)                                             |
| ------------- | --------------------------------------------------------------------------- |
| Bug           | expected vs. actual, **reproduction steps**, environment/version, evidence  |
| Feature       | problem/user need, proposed behaviour, **acceptance criteria**, out-of-scope |
| Enhancement   | current behaviour, desired behaviour, acceptance criteria                   |
| Chore         | what, why now, risk/rollback if any                                         |
| Documentation | what is wrong/missing, where it lives                                       |
| CI/CD         | what the change proves or unblocks, affected gate(s)                        |
| Security      | impact, affected surface, disclosure handling (SC-013)                      |
| Research      | the question, the **time box**, the decision it unblocks, done-when          |
| Epic          | goal, the typed child issues, done-when                                     |

A `blank`/free-text issue is disabled (`blank_issues_enabled: false`) except where a repo
documents a reason; the default path is a typed form.

## SC-012 — A PR's type is its Conventional Commit type, and the title carries it

A pull request has exactly one type, and it is the **Conventional Commit type of its squash
title** (`feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`, `perf`, `build`). The type
matches the change — a PR whose title says `fix` but adds a feature is mistyped, not a shortcut.
The title is the merge commit (squash-merge only, per the socle), so it is written for the
changelog: `type(scope): imperative summary`. The PR references its issue (`Closes/Fixes/Refs #N`,
per the socle's one-PR-per-issue) and carries the same type label as that issue where a label
applies.

## SC-013 — The PR body is type-shaped

A single committed `PULL_REQUEST_TEMPLATE.md` carries a common spine — **what changed, why, how
verified, blast radius, `Closes #N`** — plus a type checklist. The required emphasis by type:

| PR type    | The body must additionally carry                                              |
| ---------- | ----------------------------------------------------------------------------- |
| `feat`     | the acceptance criteria met, the tests added, a UI proof (screenshot/clip) for a visible surface, docs updated |
| `fix`      | the **root cause**, how it was reproduced, and the **regression test** that now fails without the fix |
| `refactor` | an explicit **no-behaviour-change** attestation and how that was verified (tests unchanged & green) |
| `perf`     | a **before/after measurement** against the declared budget (socle perf budgets) |
| `docs`     | the reader served and where the content lives; no code-behaviour claims       |
| `chore`    | what was maintained and the rollback if the change is not trivially reversible |
| `ci`       | what the gate now proves, and that a skipped job reports as skipped not passed |
| `test`     | what behaviour is now covered and why it was uncovered                        |
| `build`    | the artefact/toolchain change and its reproducibility impact                  |

Security fixes follow a **private disclosure** path (a security advisory / private issue form),
never a public issue or PR that describes the vulnerability before a fix is available; the public
PR that lands the fix is typed `fix` and omits the exploit detail.

## SC-014 — Templates are managed artefacts, not per-repo inventions

The issue forms, the label set, and the PR template are **socle-distributed files** owned by
`project-init` / `distribute-standards` and kept in sync — a repo does not hand-edit its taxonomy
or invent a private type. A drifted or missing template is repaired by re-running distribution,
the same way the standards block and shared skills are (socle *repo provenance* rule). Adding or
renaming a type is a change to SC-010 here, which then flows to every repo.

## SC-015 — The shape is machine-checked, info-first

The type discipline is mechanised and, per GV-020, introduced at `info` before any promotion to
`warning`/`error`:

- **PR title is Conventional** and its type is one of SC-012's set (a commit-lint / title-lint
  status check).
- **Every PR links an issue** (`enforce-issue-link`, already a blocking check per the socle) —
  the `hotfix` label is the one exception.
- **Every issue carries exactly one type label** from SC-010 (a triage check; the forms apply it,
  the check catches manual issues that skipped a form).
- **Labels come from the canonical set** (`labels.yml` + `sync-labels`); an out-of-canon label is
  reported, not silently accepted.

A finding here is a defect to fix (add the missing section, correct the type), not a warning to
carry once the gate is promoted.
