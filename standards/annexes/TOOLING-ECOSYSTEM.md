# Annexe TE — Tooling ecosystem coherence

> **Normative annexe.** Authority: `standards/STANDARDS.chrysa.md`. Rule ids (`TE-nnn`) are
> stable. This annexe governs how the operating tools of the fleet — Shortcut, Sentry,
> GitHub, Notion, Slack — fit together: one source of truth per kind of information, native
> integrations before custom glue, and a single cross-tool identifier. It complements
> `SCM.md` (issues/PR shape) and `OBSERVABILITY-OPS.md` (Sentry → GitHub norm); where those
> and this annexe overlap, the more specific rule wins.

## 1. One truth per kind of information

### TE-000 — Each tool owns exactly one kind of information

A fact lives in exactly one system of record. The others reference it; they never re-hold it.

| Information | System of record | Role of the others | Forbidden inside |
| --- | --- | --- | --- |
| Code + technical history | **GitHub** | read-only reference | long specs in commits |
| Executable work (stories, epics, sprint state) | **Shortcut** | link to, never copy | canonical docs, secrets |
| Runtime errors | **Sentry** | opens issues/stories | manual triage elsewhere |
| Project state, decisions, durable knowledge | **Notion** | governance view | day-to-day dev tasks |
| Notifications + discussion | **Slack** | mirror only | being a source of truth |

### TE-001 — Slack is transport, never memory

Anything that exists only in a Slack thread is lost. A decision taken in Slack is written to
Notion; work discovered in Slack becomes a Shortcut story. A surface whose only record of a
decision is a chat message is a defect.

## 2. Native before custom

### TE-010 — Integrations are native first, custom only where no native exists

Inter-tool wiring uses the vendors' own included integrations (config in the UI, no code)
before any webhook, GitHub Action, or bespoke sync. A hand-rolled relay that duplicates a
native integration is a defect — it drifts, breaks silently, and costs every repo to
maintain. Custom glue is allowed only for a flow no plan provides natively, and is documented
as such.

| Flow | Mechanism | Native | Priority |
| --- | --- | --- | --- |
| PR merged → Shortcut state | Shortcut GitHub integration (event handlers) | yes | P0 |
| Sentry new issue → GitHub issue | Sentry GitHub integration | yes | P0 |
| Sentry issue → Shortcut story | Sentry Shortcut integration | yes (Team plan) | P1 |
| Shortcut events → Slack | Shortcut Slack integration | yes | P0 |
| GitHub PR/CI → Slack | GitHub Slack app | yes | P0 |
| Sentry alert → Slack | Sentry Slack integration | yes | P0 |
| Notion ↔ Shortcut link | Shortcut Notion integration | yes | P1 |
| Shortcut Objective → Notion state | API / webhook | custom | P2 |
| Deploy → version in Notion | webhook | custom | P3 |

A feature greyed out in a vendor UI means the current plan tier does not include it; the
fallback is a documented webhook, never a silent gap.

## 3. The cross-tool identifier

### TE-020 — `sc-<id>` is the single thread across all five tools

Every unit of work carries its Shortcut story id, and that id is the join key everywhere:

- Story: `sc-1234`.
- Branch: `feature/sc-1234-slug` (SCM branch model unchanged).
- Commit / PR: Conventional Commits + `Fixes sc-1234` (+ `Fixes SENTRY-XYZ` for an incident).
- Sentry: the fix is tagged `sc-1234`.
- Notion: a page tracing to an epic is titled `[EPIC sc-ep-42] Title`.

A PR without an `sc-<id>`, or a commit without a `Fixes` trailer, breaks the thread and kills
traceability — it is a defect, not a shortcut.

## 4. Native flows (canonical journeys)

### TE-030 — The four journeys are wired end to end

- **Idea → Spec.** Notion idea page (value validated) → Shortcut Epic (native Notion link) →
  stories.
- **Code → Review → Deploy.** Story `sc-1234` → branch → PR `Fixes sc-1234` → automatic state
  transitions (PR opened → *In Review*, PR merged → *Done*) → deploy. Nothing is clicked twice.
- **Incident → Fix.** Sentry new issue → GitHub issue (native, one-to-one, no duplicate) →
  Shortcut Bug story (native link) → PR → Done → Sentry auto-resolves on deploy via
  `Fixes SENTRY-XYZ`.
- **Reporting / state.** Shortcut Objectives/Epics are the live progress; Notion is the
  governance view. Sync happens at Objective granularity, not per story.

## 5. Anti-patterns

### TE-040 — Named and rejected in review

- **Double entry** — re-creating by hand a Shortcut story for a Sentry bug; let the native
  chain do it.
- **Two truths** — sprint state held in both Notion and Shortcut. Notion points, it does not
  copy.
- **Slack as source** — a decision never written outside a thread.
- **Slack noise** — every story event posted to a channel until no one reads it. Only key
  transitions (Done, blocked, deploy) and alerts are posted.
- **Orphan ids** — a PR or commit with no `sc-<id>`.
- **Redundant notifications** — the same deploy announced three times. One channel owns each
  event kind.

## 6. Rollout order

1. P0 native integrations (GitHub↔Shortcut state event handlers, Sentry→GitHub, Slack apps).
2. `sc-<id>` convention everywhere (branch / commit / PR).
3. Slack channel filtering — one role per channel.
4. P1 (Sentry↔Shortcut, Notion↔Shortcut).
5. P2/P3 custom glue only where a real need has no native path.
