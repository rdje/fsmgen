# ISF-ATL-PIN-MIXED-ROUTE-SETS: ATL Pin Mixed Route Sets

## Metadata

- Tree ID: `ISF-ATL-PIN-MIXED-ROUTE-SETS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Widen the generated-child ATL top-level pin route-set subsets so one
same-child route set may combine scalar one-bit routes and exact-width vector
routes in the same direction. The source syntax stays the existing drive-body
`(sink source)` pair, drive calls remain the explicit transfer timing cycles,
and each route keeps its own scalar or exact-width evidence in
`actor_network.data_movements[]`.

## Non-Goals

- Do not add width adaptation, packing, truncation, sign extension, zero
  extension, slicing, aggregate payloads, or route-side transforms.
- Do not mix pin-ingress and pin-egress routes in the same route set.
- Do not mix generated-child pin routes with actor-to-actor routes in the same
  route set.
- Do not add route mux/storage, fan-in/fan-out, ready/backpressure, payload
  protocols, CDC/reset remapping, repeated child activations,
  cross-transaction continuation, recursive actor networks, or permanent actor
  grouping.
- Do not change already shipped scalar-only or vector-only route-set behavior.

## Acceptance Criteria

- The selected mixed scalar/vector pin route-set subset is documented before
  code changes.
- A generated-child pin-ingress route set with one scalar top-level input pin
  and one or more exact-width vector top-level input pins feeding matching
  resolved child inputs lowers through parent/top/HDL artifacts with each
  route width preserved.
- A generated-child pin-egress route set with one scalar resolved child output
  and one or more exact-width vector resolved child outputs feeding matching
  top-level outputs lowers through parent/top/HDL artifacts with each route
  width preserved.
- Schedule JSON reports each route through the existing
  `actor_network.data_movements[]` entry shape with route-local `kind`,
  `width`, and `width_source` values.
- Mismatched vector route widths fail closed before scheduled `.fsm` emission
  with targeted diagnostics, and existing one-to-one uniqueness/contiguity
  diagnostics remain intact.
- Focused fixture coverage proves parent/child/top `.fsm` artifacts, schedule
  JSON, strict outdir materialization, plain HDL generation, strict HDL
  generation, and mismatch failures for each shipped direction.
- ISF spec, downstream handoff, public contract, ATL design proposal, mdBook,
  roadmap, task tree, and live docs are synchronized with the shipped behavior
  and non-claims.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ATL-PIN-MIXED-ROUTE-SETS`
  Status: `active`
  Goal: `ship mixed scalar/vector generated-child ATL top-level pin route sets`
  Children: `ISF-ATL-PIN-MIXED-ROUTE-SETS.1`,
  `ISF-ATL-PIN-MIXED-ROUTE-SETS.2`,
  `ISF-ATL-PIN-MIXED-ROUTE-SETS.3`

- ID: `ISF-ATL-PIN-MIXED-ROUTE-SETS.1`
  Status: `done`
  Goal: `select the bounded ATL pin mixed route-set tree`
  Acceptance: `task-tree owner, scope, boundaries, and implementation leaves are recorded before code changes`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `this commit: ISF-ATL-PIN-MIXED-ROUTE-SETS.1: select ATL pin mixed route sets`

- ID: `ISF-ATL-PIN-MIXED-ROUTE-SETS.2`
  Status: `pending`
  Goal: `implement mixed scalar/vector generated-child pin-ingress route sets`
  Acceptance: `same-child top-level input to resolved-child input route sets may combine scalar and exact-width vector routes while preserving route-local public metadata and generated-top wiring`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-ATL-PIN-MIXED-ROUTE-SETS.3`
  Status: `pending`
  Goal: `implement mixed scalar/vector generated-child pin-egress route sets`
  Acceptance: `same-child resolved-child output to top-level output route sets may combine scalar and exact-width vector routes while preserving route-local public metadata and generated-top wiring`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ATL-PIN-MIXED-ROUTE-SETS.2` | `pending` | Pin-ingress goes first because it is the smaller pre-trigger direction and follows the already-shipped scalar-only and vector-only ingress route sets. |
| 2 | `ISF-ATL-PIN-MIXED-ROUTE-SETS.3` | `pending` | Pin-egress follows ingress so the inverse post-event direction can reuse the same mixed route-set policy once ingress is proven. |

## Decisions

- `2026-05-22`: Selected mixed scalar/vector same-child pin route sets as the
  next bounded ATL widening after scalar-only and vector-only route sets
  shipped in both pin directions.
- `2026-05-22`: Kept the existing `(sink source)` route syntax and drive-call
  timing model. The selected change is route-set grouping only: each route
  keeps its own `kind`, `width`, and `width_source`.
- `2026-05-22`: Kept width adaptation, payload protocols, route storage,
  muxing, fan-in/fan-out, CDC/reset remapping, and cross-transaction
  continuation deferred.

## Open Questions

- None blocking the selected bounded subset.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-ATL-PIN-MIXED-ROUTE-SETS.1` | `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ATL-PIN-MIXED-ROUTE-SETS.1` | `this commit: ISF-ATL-PIN-MIXED-ROUTE-SETS.1: select ATL pin mixed route sets` | Selection commit. |

## Changelog

- `2026-05-22`: Created active R14 task tree and selected the bounded
  generated-child top-level pin mixed scalar/vector route-set implementation
  sequence.
