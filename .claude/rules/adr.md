# ADR — chrysa format (falsifiable decisions)

______________________________________________________________________

> A classic ADR records a decision. The chrysa format adds three fields that make
> it **refutable**: fatal hypothesis, kill-test, validation gate. Without them an
> ADR can never be proven wrong, so it teaches nothing. Canonical source:
> `chrysa/shared-standards`. Scaffold: `/adr-new`.

______________________________________________________________________

## Rule

Any structural decision → one ADR under `docs/adr/`, series named in the repo's
`CLAUDE.md`. An ADR is **never edited** after it reaches `Accepted` — except its
status. Changing your mind = a new ADR that supersedes the old one. Written in
English.

**An ADR is mandatory for:** a new external dependency · an LLM/cloud provider
choice · a breaking public-API change · a data-model change · any exception to a
[strategic pillar](pillars.md).

**No ADR for:** a behaviour-preserving refactor, a naming choice, a bug fix.

______________________________________________________________________

## The three fields that matter

**Fatal hypothesis** — the single belief whose falsity invalidates the decision.
One only (two → the decision is too big, split it). **Falsifiable**: you can
describe the evidence that would disprove it. About the real world (cost, latency,
a third party's behaviour, adoption), not an internal intention.

**Kill-test** — the observable, dated signal that proves the hypothesis wrong.
It states *what* to measure, *which threshold*, *when* it is checked, *what
happens* on breach. Mechanise it as a test when you can; a kill-test living only
in a doc waits to be re-read, one in CI fires by itself.

**Validation gate** — the pre-agreed condition that unlocks the next step. The
inverse of the kill-test (the kill-test kills, the gate unblocks). Written
**before** implementation, else it is a rationalisation.

______________________________________________________________________

## Statuses

`Proposed` · `Accepted` · `Superseded` (points to successor) · `Killed` (the
kill-test fired — the hypothesis was false) · `Deprecated` (context gone, no
successor). `Killed` is the format working, not a failure: an ADR corpus with no
`Killed` entry has kill-tests that are too lax.

______________________________________________________________________

## Template

```markdown
# <SERIES>-<NNNN>: <Short imperative title>

- **Status:** Proposed
- **Date:** <YYYY-MM-DD>
- **Deciders:** <name>
- **Pillars touched:** <llm-independence | gafam-independence | data-portability | k8s-in-project | adaptation-layer | none>
- **Supersedes / Superseded by:** —

## Context
What is true today that forces a decision now. Facts and constraints only.

## Decision
One sentence, active voice, present tense.

## Fatal hypothesis
The single falsifiable assumption that, if false, invalidates this decision.

## Kill-test
Observable, dated signal that proves the hypothesis wrong. What to measure,
threshold, when checked, action on breach. Mechanised as a test, or: why not.

## Validation gate
The pre-agreed condition that unlocks the next step. Written before building.

## Options considered
| Option | Why not |
| ------ | ------- |
| <A>    | <the real reason, not a strawman> |

## Consequences
Accepted costs (what gets worse, on purpose) · gains · debt created (and when it
is paid) · blast radius (what must change if this ADR is Killed).
```

______________________________________________________________________

## Why

- A decision you cannot disprove is a decision you cannot learn from.
- The kill-test is the only contradictor a solo developer has.
- Complements the [strategic pillars](pillars.md): most pillar exceptions land here.

______________________________________________________________________

## Manual verification

In review, check: the fatal hypothesis is falsifiable and singular · the kill-test
has a numeric threshold, a cadence and an action · it is mechanised, or the ADR
says why it cannot be · the gate predates the implementation · rejected options
have real reasons · the blast radius is named.
