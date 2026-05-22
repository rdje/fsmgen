# ISF-ATL-MULTI-EVENT-WAIT: ATL Multi-Event Waits

## Metadata

- Tree ID: `ISF-ATL-MULTI-EVENT-WAIT`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Widen the bounded ATL parent-handoff orchestration surface so one parent
transaction may wait for more than one actor event after a same-cycle temporary
trigger batch. The selected first runtime semantics are explicit sequential
wait states in source order: every authored `(await actor.event)` remains a
reviewable cycle boundary, and each wait reports through the existing
`actor_network.event_waits[]` entry shape.

## Non-Goals

- Do not add true same-cycle event fan-in, event payloads, event fan-out,
  ready/backpressure, CDC, or group endpoint semantics.
- Do not combine multi-event waits with ATL data movement or generated-child
  route sets in this tree.
- Do not widen nested waits, rule-level waits, cross-transaction waits, or
  waits inside control-flow bodies.
- Do not require permanent `(group ...)` declarations for temporary
  trigger-batch/event-wait associations.
- Do not change already shipped one-event wait behavior or generated-child
  trigger/event handoff behavior.

## Acceptance Criteria

- The selected multi-event wait subset is documented before code changes.
- A parent transaction with one contiguous temporary trigger batch followed by
  multiple top-level `(await actor.event)` clauses lowers to one scheduled
  parent `.fsm` with one generated input handoff per waited event.
- Wait states are explicit and source-ordered. No hidden join, storage, or
  combinational fan-in is inferred.
- Schedule JSON reports every wait through `actor_network.event_waits[]` with
  the existing keys, preserving source order.
- Strict schedule JSON, plain HDL, and strict HDL cover the positive fixture.
- Focused negative coverage keeps nested waits, data-movement coupling, and
  non-selected multi-event shapes fail-closed.
- ISF spec, downstream handoff if impacted, public contract if impacted, ATL
  design proposal, mdBook, roadmap, task tree, and live docs are synchronized
  with the shipped behavior and non-claims.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ATL-MULTI-EVENT-WAIT`
  Status: `active`
  Goal: `ship bounded transaction-body ATL multi-event wait sequencing`
  Children: `ISF-ATL-MULTI-EVENT-WAIT.1`,
  `ISF-ATL-MULTI-EVENT-WAIT.2`

- ID: `ISF-ATL-MULTI-EVENT-WAIT.1`
  Status: `done`
  Goal: `select the bounded ATL multi-event wait task tree`
  Acceptance: `task-tree owner, scope, boundaries, and implementation leaf are recorded before code changes`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `this commit: ISF-ATL-MULTI-EVENT-WAIT.1: select ATL multi-event waits`

- ID: `ISF-ATL-MULTI-EVENT-WAIT.2`
  Status: `pending`
  Goal: `implement sequential multi-event waits after a temporary trigger batch`
  Acceptance: `one parent transaction may trigger distinct static actors in one temporary trigger batch and then wait for multiple actor events in source order while preserving explicit wait states, ports, reports, and HDL evidence`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ATL-MULTI-EVENT-WAIT.2` | `pending` | Multi-event waits are the next smallest ATL orchestration widening after trigger batches and one-event waits shipped; the selected leaf keeps explicit sequential wait semantics rather than introducing a hidden join. |

## Decisions

- `2026-05-22`: Selected source-ordered sequential waits as the first
  multi-event semantics. The author already writes every wait explicitly, so
  the scheduler can preserve reviewable state boundaries instead of inventing
  a new join primitive.
- `2026-05-22`: Kept the first implementation tied to temporary trigger
  batches over direct static actor instances. This avoids mixing the event
  widening with generated-child tops, route scheduling, group endpoints, or
  CDC behavior.

## Open Questions

- None blocking the selected bounded subset.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-ATL-MULTI-EVENT-WAIT.1` | `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ATL-MULTI-EVENT-WAIT.1` | `this commit: ISF-ATL-MULTI-EVENT-WAIT.1: select ATL multi-event waits` | Selection commit. |

## Changelog

- `2026-05-22`: Created active R14 task tree and selected the bounded
  transaction-body ATL multi-event wait implementation sequence.
