# ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY: ATL Route Drive Argument Boundary

## Metadata

- Tree ID: `ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Make the ATL data-movement route-drive formal and actual-argument boundary
uniform across every shipped ATL route kind. The current generated-child
actor-to-actor route is already coverage-locked; this tree extends the same
non-parameterized route-drive contract to the shipped top-level pin-ingress
and pin-egress route families and keeps diagnostics kind-neutral where the
route kind has not yet been selected.

## Non-Goals

- Do not add parameterized ATL route drives.
- Do not add route drive-call actual binding.
- Do not introduce route mux/storage, fan-in/fan-out, ready/backpressure,
  payload protocols, CDC/reset remapping, expression movement, route-side
  transforms, recursive actor networks, group endpoints, repeated child
  activations, or cross-transaction continuation.
- Do not change the accepted positive route subsets for actor-to-actor,
  pin-ingress, or pin-egress movement.

## Acceptance Criteria

- The selected boundary is documented before code changes.
- Parameterized selected ATL route drive definitions fail closed before
  scheduled `.fsm` emission for actor-to-actor, top-level pin-ingress, and
  top-level pin-egress route families.
- Selected ATL route drive calls with actual arguments fail closed before
  scheduled `.fsm` emission for actor-to-actor, top-level pin-ingress, and
  top-level pin-egress route families.
- Diagnostics describe the shared ATL scalar data-movement boundary instead of
  implying that every ATL route is actor-to-actor.
- Focused tests prove the pin-ingress and pin-egress route-drive argument
  boundary without changing the accepted positive fixtures.
- mdBook, ISF spec, downstream integration handoff, public contract, design
  proposal, live docs, and task-tree status are synchronized with the shipped
  boundary and explicit non-claims.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY`
  Status: `done`
  Goal: `harden ATL route drive formal and actual-argument rejection across shipped data-movement route kinds`
  Children: `ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.1`,
  `ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.2`

- ID: `ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.1`
  Status: `done`
  Goal: `select the shared ATL route-drive argument boundary slice`
  Acceptance: `task-tree owner, scope, boundaries, and implementation leaf are recorded before code changes`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `this commit: ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.1: select ATL route-drive argument boundary`

- ID: `ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.2`
  Status: `done`
  Goal: `implement and document the shared ATL route-drive argument boundary`
  Acceptance: `pin-ingress and pin-egress formal/actual-argument fail-closed coverage, kind-neutral diagnostics, synchronized public docs, and focused gates prove the boundary`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t; prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1326-isf-atl-pin-ingress-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `this commit: ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.2: harden ATL route-drive argument boundary`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.2` implemented and documented the shared ATL route-drive argument boundary across shipped route kinds. |

## Decisions

- `2026-05-22`: Selected this hardening after the pin-ingress and pin-egress
  multi-route leaves because those route families now use the same drive-body
  and drive-call timing model as actor-to-actor routes. The boundary should be
  uniform: route drives are explicit one-cycle timing points, not
  parameterized procedures with route-local actual binding.
- `2026-05-22`: Kept this as a boundary-hardening tree, not a payload or
  expression-movement feature. Actual binding would need a route payload,
  transform, mux/storage, and scheduling contract that is outside this slice.

## Open Questions

- None blocking the current bounded subset.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.1` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-22` | `ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1326-isf-atl-pin-ingress-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed`; ISF regression gate reported `Files=238, Tests=1541` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.1` | `this commit: ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.1: select ATL route-drive argument boundary` | Selection committed. |
| `ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.2` | `this commit: ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.2: harden ATL route-drive argument boundary` | Implementation committed. |

## Changelog

- `2026-05-22`: Created active R14 task tree and selected the shared ATL
  route-drive argument-boundary implementation leaf.
- `2026-05-22`: Hardened the route-drive formal/actual-argument boundary for
  pin-ingress and pin-egress route families, synchronized public docs, and
  closed the tree.
