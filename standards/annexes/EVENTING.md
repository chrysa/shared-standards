# Annexe EV — Eventing & real-time streaming (backend)

> **Normative annexe.** Authority: `standards/STANDARDS.chrysa.md`. Domain: `STD-EVENTING-001`
> (GV-015). Rule ids (`EV-nnn`) are stable. This annexe governs the **producer/consumer side** of
> real-time systems — event buses, pub/sub channels, streaming transports (WebSocket, SSE, a
> broker). It complements the socle *reactive & real-time by default* rule and its **frontend
> twin** [`FRONTEND.md`](FRONTEND.md) FE-080 (a screen reflects live state); the **wire contract**
> for events/webhooks lives in [`API-CONTRACTS.md`](API-CONTRACTS.md) (`AP-`) and the resilience
> baseline in the socle *failures are contained, and observable*. Numeric values (buffer sizes,
> timeouts, poll/TTL intervals) live in the per-repo contract, never restated here (GV-030).

## 1. Channel contracts

### EV-000 — Every channel has a name and a typed, versioned contract

A real-time channel is not an anonymous firehose: each channel has a **stable name**, a declared
set of **publishers and subscribers**, and a **typed message schema** that is versioned like any
other contract (`AP-`). A subscriber knows, from the contract alone, what shapes arrive on a
channel and what a new version changes — a channel whose payload is "whatever the publisher sends
today" is an outage waiting for the next publisher edit. Message schemas are validated at the
boundary (external data is validated at runtime even when typed — socle rule).

## 2. Non-blocking flow

### EV-010 — Subscription is decoupled from processing by a bounded buffer

The path that **receives** an event never does the slow work inline. Reception hands the event to
a **bounded buffer/queue**, and separate workers drain it — so the receiver (the event loop, the
socket reader, the subscription callback) is never blocked on I/O and a slow consumer cannot stall
the transport. The buffer is **bounded with an explicit overflow policy** (drop-oldest, reject,
shed with a typed error) declared per channel; an unbounded in-memory queue that grows under load
until the process dies is the defect this rule removes (mirrors the socle *bounded resources*).

### EV-011 — Backpressure and lag are observable

A consumer that falls behind is **visible** — queue depth, consumer lag, and drop counts are
metrics (OP-010), and crossing the declared budget raises an actionable alert (OP-020). A silent
backlog that only surfaces as stale data downstream is a monitoring gap, not a healthy system.

## 3. Fail-safe external access

### EV-020 — Every call to external infrastructure is guarded and degrades

Each call to the bus, broker, cache or store the stream depends on is wrapped in a **guard** that,
when the dependency is unavailable, **degrades safely** — returns a safe default, no-ops, or
surfaces the state — rather than throwing into the event loop and taking the stream down. This is
the streaming-tier application of the socle *failures are contained, and observable* rule (bounded
timeouts, bounded retries, a circuit-breaker on a repeatedly-failing dependency) and the backend
twin of FE-050: the system says a channel is degraded, it does not freeze or lie. Losing the live
channel degrades to the last known state, never to a crash.

### EV-021 — Dependency health is probed on demand and cached, not hot-polled

The health of an external dependency is checked **when it is needed and the result cached** for a
declared TTL — not re-probed by a tight recurring job whose only effect is load. A recurring
health poll is justified only where nothing else would ever trigger a check; its interval is a
per-repo value (GV-030), and its purpose is to bound cache staleness, not to hammer the dependency.

## 4. Delivery semantics

### EV-030 — Delivery semantics are declared, and consumers match them

Each channel declares its **delivery guarantee** — at-least-once, at-most-once, ordered or not.
Where delivery is at-least-once, **consumers are idempotent** (a redelivered or duplicated event
produces no double effect — the socle *idempotent submission* and `AP-` idempotency rules applied
to events), and replay/duplicate/late-arrival handling is defined rather than assumed. A consumer
that double-charges on a redelivery because it assumed exactly-once is a defect, not bad luck.

## 5. Transport is an adapter

### EV-040 — The transport is behind the domain's port

Which transport carries the events — WebSocket, SSE, a message broker, an in-process pub/sub — is
an **adapter chosen by configuration** (endpoint via env, per *external servers addressed through
the environment*), never a vendor client wired into business code. The domain publishes and
consumes through a port in its own language (pillar 5 *adaptation layer*); swapping SSE for
WebSocket, or one broker for another, is an adapter change, not a domain rewrite. The fleet's
realtime-transport decision (WebSocket-first) is a per-product choice expressed at this seam, not
a hard dependency of the domain.

______________________________________________________________________

## 6. Gates

| Gate | Rule | Mode (this wave) |
| ---- | ---- | ---------------- |
| Unbounded queue / no overflow policy on a channel | EV-010 | `guideline-checker` · **info** |
| External-infra call in a stream path with no guard/timeout | EV-020 | `guideline-checker` · **info** |
| Channel with no declared delivery semantics | EV-030 | review |

Rollout follows GV-020: detectors land as `info`, promoted to `warning` then `error` once the
fleet's existing debt is cleared — never blocking on introduction.
