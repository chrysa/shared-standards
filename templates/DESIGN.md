# Product design contract

## Product and users

Describe the product, its users, supported devices and three priority tasks.
Mark planned capabilities explicitly; do not describe a mock-up as a shipped feature.

## Information architecture

Define primary objects, navigation, main actions and detailed journey references.

## Identity and token ownership

Reference the canonical semantic tokens, typography, spacing, grid, themes and reusable
components. Explain brand choices without duplicating values owned by code.
Record unresolved choices and existing design/code drift.

## Interaction and resilience

Specify component states and loading, empty, validation, error, offline, stale-data and
reconnect behaviour where applicable. Preserve focus, input and scroll during updates.

## Accessibility and assets

State the applicable accessibility target and native equivalents, keyboard behaviour,
focus, contrast and reduced-motion requirements. Record asset provenance and licences.

## Acceptance and evidence

List representative task scenarios, viewport/window sizes, keyboard checks and failure
recovery cases. Link to reproducible evidence and unresolved limitations.
Static lint does not certify usability, visual quality or accessibility.

## Agent use

Reference this contract explicitly from AGENTS.md or CLAUDE.md before UI work.
Prefer on-demand loading. Keep the design contract aligned with code.
