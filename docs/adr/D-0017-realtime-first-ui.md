# D-0017: Real-time by default for any project with a UI

- **Status:** Accepted
- **Date:** 2026-09-27
- **Deciders:** chrysa
- **Pillars touched:** none
- **Supersedes / Superseded by:** records the posture already carried by FE-080 / CORE

## Context

The frontend annexe (FE-080) and the slim core already state that a chrysa UI is
"reactive and real-time by default", and the Notion standards card carries the 27 Sept 2026
decision — *temps réel par défaut pour tout projet doté d'une interface* — flagged
explicitly as **"à porter en ADR + PR dans le dépôt, qui fait foi"**. The posture was
therefore live in the canon but had no ADR trace: no recorded decision, no fatal hypothesis,
no kill-test. The earlier wording it replaces — "reactive interfaces where relevant" — left
real-time as a per-feature judgement call, which in practice defaulted surfaces to
poll-or-reload and made a stale screen look like a design choice rather than a bug.

## Decision

Any project that ships a user interface is **real-time by default**: task progress, status,
logs, notifications, collaboration, operational data, backend events and other clients'
changes propagate without a manual refresh, over a push transport (WebSocket / SSE /
subscription) with polling as a bounded fallback. Front-end computation is allowed (optimistic
UI, derived state, local projections) but the **backend stays the source of authority** and
reconciles on structuring actions, at a per-app interval, and on every reconnect / refocus.
Rights, amounts, security and authoritative business rules are never computed on the client
alone. This is the frontend contract of FE-080; the transport, reconnection and zero-loss
persistence details remain per-product choices expressed at the eventing seam (EVENTING annexe),
and the durable-bus tooling question (NATS JetStream vs. others) is **left open** — this ADR
does not decide it.

## Fatal hypothesis

A push-first default across every UI project is worth its cost: the reconnection, resync,
dedup and reconciliation machinery it forces is cheaper over a project's life than the bugs,
stale views and manual-refresh workarounds that a poll-or-reload default produces.

## Kill-test

Reviewed at each quarterly standards review. Signal that the hypothesis is false: on the UI
projects adopting the default, real-time infrastructure (channel drops, resync loops,
reconciliation conflicts) becomes the **top recurring source of UI defects** for two
consecutive quarters while no equivalent class of stale-data bugs is displaced — i.e. the
default trades a cheap bug class for a more expensive one. On breach, downgrade the rule back
to "real-time where it earns its place" and record it in a superseding ADR.

## Validation gate

The default is considered validated when at least three UI projects run it in production with
their `architecture.md` declaring the push channel, the reconciliation triggers and the
conflict strategy, and `guideline-checker` verifies that section is present — without the
real-time layer being the dominant defect source over the first two quarters.

## Options considered

| Option | Why not |
| ------ | ------- |
| Keep "reactive where relevant" | Left real-time optional per feature; surfaces defaulted to poll/reload and stale screens read as intended, not as bugs. |
| Real-time only for explicitly collaborative apps | Draws an arbitrary line — status, logs and cross-client changes want push in ordinary single-user apps too. |
| Mandate a specific durable bus now (NATS JetStream) | Couples the UI-posture decision to an unsettled infra choice still flagged "à trancher"; kept separate. |

## Consequences

- Every UI project owes the FE-080 posture: push transport, bounded-fallback polling,
  reconnection banner, resync on recovery, cross-tab/focus propagation, optimistic UI with
  visible rollback. A screen needing a manual refresh to be correct is a defect.
- `architecture.md` must document the push channel, reconciliation triggers and conflict
  strategy; `guideline-checker` gates the presence of that section.
- Accepted cost: more moving parts (transport, backpressure, dedup, idempotent replay) even on
  small apps. The zero-loss invariants and data-class model (ephemeral / hot / critical) are
  the eventing seam's concern, staged separately, not forced by this ADR.
- The durable-bus default (NATS JetStream vs. alternatives) and the no-UI-project exception
  stay **open questions** for a later ADR; this decision is scoped to the UI posture only.
