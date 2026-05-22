# ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT: Bounded ATL Multi-Route Data Movement

## Metadata

- Tree ID: `ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Widen the shipped generated-child ATL actor-to-actor data route from one
scalar route to a bounded multiple-route subset where several scalar source
ports from one resolved child may be moved into several scalar sink ports on
one resolved child before the sink child is triggered.

## Non-Goals

- Do not add new source syntax beyond existing drive bodies and drive calls.
- Do not introduce route mux/storage, fan-in/fan-out, ready/backpressure,
  payload protocols, CDC/reset remapping, recursive actor networks, group
  endpoints, or repeated child activations.
- Do not widen pin-to-child, child-to-pin, or unqualified external-instance
  routing in this tree.
- Do not allow multiple source children, multiple sink children, or routes
  that cross parent transactions.

## Acceptance Criteria

- The selected source shape is documented before code changes.
- The implementation accepts multiple one-bit generated-child actor-to-actor
  routes only when all routes share the same resolved source and sink child,
  the source trigger/event wait happen first, every route drive call is
  contiguous after the source event wait, and the sink trigger/event wait
  happen after the route drive calls.
- Generated parent `.fsm`, generated ATL top `.fsm`, schedule JSON, and
  SystemVerilog reachability are regression-covered for the positive subset.
- Existing fail-closed diagnostics remain targeted for wider payloads,
  repeated activations, repeated waits, cross-transaction routes, interleaved
  parent work, route endpoint expressions, and parameterized route drive calls.
- mdBook, ISF spec, downstream integration spec, public contract, live docs,
  and task-tree status are synchronized with the shipped subset and explicit
  non-claims.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT`
  Status: `active`
  Goal: `ship a bounded generated-child ATL multi-route scalar movement subset`
  Children: `ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.1`,
  `ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.2`

- ID: `ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.1`
  Status: `done`
  Goal: `select the next bounded ATL data-route feature slice`
  Acceptance: `task-tree owner, scope, boundaries, and implementation leaf are recorded before code changes`
  Verification: `git diff --check; mdbook build docs/book`
  Commit: `pending`

- ID: `ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.2`
  Status: `pending`
  Goal: `implement bounded multiple scalar generated-child actor-to-actor routes`
  Acceptance: `positive fixture, schedule report, generated top wiring, HDL reachability, docs, and focused gates prove the shipped subset`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.2` | `pending` | The existing ATL route code is already hardened around the one-route boundary, so the next safe widening is multiple scalar routes between the same resolved source/sink pair without adding mux/storage or fan-in/fan-out semantics. |

## Decisions

- `2026-05-22`: Selected a bounded multiple-route subset instead of a broader
  mux/storage route model. The implementation must keep the current
  `(sink source)` drive-body order and existing drive-call timing points; the
  scheduler may accept several contiguous route drive calls only when they
  share one resolved source child, one resolved sink child, one parent
  transaction, one source trigger/event wait pair, and one sink trigger/event
  wait pair.
- `2026-05-22`: Deferred fan-in/fan-out, route muxing, inserted storage,
  ready/backpressure, payload protocols, CDC/reset remapping, repeated
  triggers, repeated waits, and multi-transaction continuation because each
  needs independent scheduling evidence and user-facing semantics.

## Open Questions

- None blocking the current bounded subset.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.1` | `git diff --check`; `mdbook build docs/book` | `pending` |
| `2026-05-22` | `ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.2` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.1` | `pending` | Selection commit pending. |
| `ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.2` | `pending` | Implementation pending. |

## Changelog

- `2026-05-22`: Created active R14 task tree and selected the first bounded
  implementation leaf.
