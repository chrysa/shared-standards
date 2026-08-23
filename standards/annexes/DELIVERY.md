# Annexe DL — Delivery workflow (Shortcut · GitHub · Slack)

> **Proposed annexe — not yet adopted.** Authority: `standards/STANDARDS.chrysa.md`. Domain: `STD-DELIVERY-001`.
> Rule ids (`DL-nnn`) are stable — never reuse an id for a different rule. This annexe describes the
> **tracker-driven delivery loop** that ties a Shortcut story to its branch, pull request, and Slack
> notifications. It complements — does not replace — annexe `SC` (issue/PR content shape) and the
> socle git conventions (Conventional Commits, `main`/`develop`, squash-merge). Where they disagree,
> the socle wins. Adoption requires a socle anchor in *Normative annexes* and moving the
> `domains.yaml` entry from `Proposed` to `Adopted` (blast radius: every fleet repo).

## DL-000 — Why a tracker-driven loop

A change is only traceable when the plan (the story), the code (the branch and PR), and the
signal (the Slack notification) share one identifier. When they don't, status lives in three
places that drift: the board says "in progress" while the PR is merged and nobody was told. The
loop below makes the **story id the single key** — the branch carries it, the integration reads
it, and every state transition is derived from a Git event, never hand-updated. Manual status
changes are a defect, not a workflow.

## DL-010 — The story id is the delivery key

Every unit of work is a **Shortcut story** with a stable id `sc-<id>`. The branch name **must**
start with that id: `sc-<id>-<slug>`. The commit trailer **must** reference it: a Conventional
Commit subject followed by `[sc-<id>]`. This is the only hard rule of the loop — the native
GitHub↔Shortcut integration links branch, commits, and PR to the story from that prefix alone.

## DL-011 — Story titles carry no project prefix

A story title states the change in plain terms. The **project** is a label (`projet:<slug>`), the
**nature** is the story type (Feature / Bug / Chore) plus canonical labels
(`urgent`, `blocked`, `backend` / `frontend` / `ops`, `tech-debt`). A bracketed project tag in the
title (`[Foo] …`) is legacy noise and must be stripped, not added.

## DL-020 — State transitions are derived from Git events

The story workflow is `Backlog → In Progress → In Review → Done`. Transitions are driven by the
native integration's event handlers, configured once per workspace:

| Git event              | Story transition |
| ---------------------- | ---------------- |
| Branch `sc-<id>` opened | In Progress *(optional)* |
| Pull request opened     | In Review        |
| Pull request merged     | Done             |

A workspace where these handlers are not configured is non-conformant: stories will not move on
their own and DL-000 is defeated.

## DL-030 — Notifications route natively, by Team and by field

Slack routing uses the tracker's native integration, never a home-grown relay:

- **Team → channel.** Each Shortcut Team maps to one Slack channel (`Link Teams to Slack
  Channels`). One channel per Team; no per-repo fan-out.
- **Field value → channel.** High-severity work routes to the alert channel (`Link Field Values
  to Slack Channels`): `Priority` Highest/High (or `Severity` top value) → `#…-alerts`.
- An `-alerts` channel carries **red only** — broken CI, incidents, P0/P1. Routine story chatter
  never lands there.

The integration app (Shortcut) must be a member of every mapped channel.

## DL-040 — No home-grown integration workflow

The GitHub↔Shortcut and Shortcut→Slack links are the vendors' **native OAuth integrations**. A
repository must not carry a bespoke CI workflow that re-implements story moves or Slack posts
(e.g. an `ops-sync` action driven by repo secrets): it duplicates the native behaviour, drifts,
and spreads tracker tokens across every repo. Native first; a custom relay is a deferred
arbitration, not a default.

## DL-050 — Definition of Done

A story is Done when its pull request is **merged** with a passing required CI and at least one
review. Merge is the only trigger for `Done` — a story moved to Done without a merged PR, or a PR
merged without its story reaching Done, is a broken loop to be fixed, not tolerated.

## Deferred / open

- **Tracker of record.** Annexe `SC` is written around GitHub issues; this annexe is written
  around Shortcut stories. Adoption must reconcile the two (issues vs. stories as the unit of
  work) in the socle before `Adopted`.
- **Per-Team channel sprawl** for low-volume Teams — a single shared channel may be preferable;
  left to each workspace until measured.
