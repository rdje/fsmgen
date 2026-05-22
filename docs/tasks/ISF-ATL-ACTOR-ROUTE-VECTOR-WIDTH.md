# ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH: ATL Actor Route Vector Width

## Metadata

- Tree ID: `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Widen the shipped generated-child ATL actor-to-actor data-route subset from
one-bit scalar routes to exact-width vector routes when the resolved source
child output and sink child input declare the same positive width. The route
syntax stays the existing `(sink source)` drive-body pair, and the parent
scheduled `.fsm` remains the explicit timing owner for the drive-call cycle.

## Non-Goals

- Do not add packing, truncation, sign extension, zero extension, slicing, or
  aggregate payload protocols.
- Do not add expression movement, route-side transforms, parameterized route
  drives, or drive-call actual binding.
- Do not add vector top-level pin-ingress or pin-egress routes in this tree.
- Do not add route mux/storage, fan-in/fan-out, ready/backpressure, CDC/reset
  remapping, repeated child activations, cross-transaction continuation,
  recursive actor networks, or permanent actor grouping.
- Do not change the accepted one-bit route syntax, timing order, or report key
  shape.

## Acceptance Criteria

- The selected vector-width route subset is documented before code changes.
- A generated-child actor-to-actor ATL route with matching source-output and
  sink-input widths greater than one lowers to parent handoff ports with that
  exact width.
- The generated top wires the vector child output to the parent source handoff
  and the parent sink handoff to the vector child input without adding storage
  or route muxing.
- Schedule JSON reports the widened route through the existing
  `actor_network.data_movements[]` fields with `width` equal to the endpoint
  width and a distinct width-source value.
- Mismatched source/sink route widths fail closed before scheduled `.fsm`
  emission with a targeted diagnostic; missing endpoints and existing
  malformed route boundaries keep their current diagnostics.
- Focused fixture coverage proves parent/child/top `.fsm` artifacts, schedule
  JSON, strict outdir materialization, plain HDL generation, strict HDL
  generation, and the mismatch failure.
- ISF spec, downstream handoff, public contract, ATL design proposal, mdBook,
  roadmap, task tree, and live docs are synchronized with the shipped behavior
  and non-claims.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH`
  Status: `active`
  Goal: `ship exact-width vector generated-child actor-to-actor ATL routes`
  Children: `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.1`,
  `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.2`

- ID: `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.1`
  Status: `done`
  Goal: `select the bounded ATL actor-route vector-width slice`
  Acceptance: `task-tree owner, scope, boundaries, and implementation leaf are recorded before code changes`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `this commit: ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.1: select ATL actor-route vector width`

- ID: `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.2`
  Status: `pending`
  Goal: `implement exact-width vector generated-child actor-to-actor ATL routes`
  Acceptance: `matching-width vector routes lower through parent/top/HDL artifacts, mismatches fail closed, and public docs describe the shipped boundary`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.2` | `pending` | `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.1` selected the bounded exact-width vector route subset; implementation can start after this selection commit. |

## Decisions

- `2026-05-22`: Selected exact-width generated-child actor-to-actor vector
  routes as the next ATL feature because the shipped route syntax, generated
  top handoff model, and schedule-report `width` field already describe the
  needed shape. The minimal useful widening is same-width vector movement
  only; any width adaptation, payload packing, route storage, or muxing needs a
  later explicit task tree.
- `2026-05-22`: Kept pin-ingress and pin-egress vector movement out of this
  tree. Those routes touch top-level public pins and deserve their own
  boundary once actor-to-actor vector handoffs are proven.

## Open Questions

- None blocking the current bounded subset.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.1` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-22` | `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.2` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.1` | `this commit: ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.1: select ATL actor-route vector width` | Selection committed. |
| `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.2` | `pending` | `pending` |

## Changelog

- `2026-05-22`: Created active R14 task tree and selected the bounded
  generated-child actor-to-actor vector-width route implementation leaf.
