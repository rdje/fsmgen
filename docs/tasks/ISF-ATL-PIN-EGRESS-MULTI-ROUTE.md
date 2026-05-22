# ISF-ATL-PIN-EGRESS-MULTI-ROUTE: Bounded ATL Pin-Egress Multi-Route

## Metadata

- Tree ID: `ISF-ATL-PIN-EGRESS-MULTI-ROUTE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Widen the generated-child ATL resolved-child output to top-level output-pin
route from one scalar route to a bounded multiple-route subset. The selected
shape lets several one-bit outputs from one resolved child drive several
one-bit top-level output pins through adjacent named drive calls after that
child's event wait has completed.

## Non-Goals

- Do not add new source syntax beyond existing drive bodies and drive calls.
- Do not widen top-level input-pin ingress in this tree.
- Do not widen actor-to-actor generated-child routes in this tree.
- Do not introduce route mux/storage, fan-in/fan-out, ready/backpressure,
  payload protocols, CDC/reset remapping, recursive actor networks, group
  endpoints, repeated child activations, or cross-transaction continuation.
- Do not allow multiple child endpoints to drive one top-level output pin, one
  child endpoint to drive multiple top-level output pins, or any route that
  crosses parent transactions.

## Acceptance Criteria

- The selected source shape is documented before code changes.
- The implementation accepts multiple one-bit generated-child pin-egress
  routes only when all routes source the same resolved child, live in the same
  parent transaction, use one scalar `(pins.output_pin child.endpoint)` pair per
  drive body, and are activated by contiguous argument-free drive calls after
  the child trigger/event wait sequence.
- Generated parent `.fsm`, generated child `.fsm`, generated ATL top `.fsm`,
  schedule JSON, and SystemVerilog reachability are regression-covered for the
  positive subset.
- Existing fail-closed diagnostics remain targeted for wider pins, missing
  child outputs, repeated route drive calls, parameterized route drive calls,
  interleaved parent work, cross-transaction routes, and endpoint expressions.
- mdBook, ISF spec, downstream integration spec, public contract, live docs,
  and task-tree status are synchronized with the shipped subset and explicit
  non-claims.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ATL-PIN-EGRESS-MULTI-ROUTE`
  Status: `done`
  Goal: `ship a bounded generated-child ATL resolved-child output to top-level pin-egress multi-route scalar subset`
  Children: `ISF-ATL-PIN-EGRESS-MULTI-ROUTE.1`,
  `ISF-ATL-PIN-EGRESS-MULTI-ROUTE.2`

- ID: `ISF-ATL-PIN-EGRESS-MULTI-ROUTE.1`
  Status: `done`
  Goal: `select the bounded ATL pin-egress multi-route feature slice`
  Acceptance: `task-tree owner, scope, boundaries, and implementation leaf are recorded before code changes`
  Verification: `git diff --check; mdbook build docs/book`
  Commit: `this commit: ISF-ATL-PIN-EGRESS-MULTI-ROUTE.1: select ATL pin-egress multi-route slice`

- ID: `ISF-ATL-PIN-EGRESS-MULTI-ROUTE.2`
  Status: `done`
  Goal: `implement bounded multiple scalar generated-child pin-egress routes`
  Acceptance: `positive fixture, schedule report, generated top wiring, HDL reachability, docs, and focused gates prove the shipped subset`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c t/1322-isf-actor-network-static.t; perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t; perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1322-isf-actor-network-static.t; prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t; prove -Iperl t/1324-isf-atl-fixture-coverage.t t/1325-isf-atl-data-route-fixture-coverage.t t/1326-isf-atl-pin-ingress-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1328-isf-atl-trigger-wait-fixture-coverage.t t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t t/1331-isf-timing-conventions.t; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `this commit: ISF-ATL-PIN-EGRESS-MULTI-ROUTE.2: ship bounded ATL pin-egress route sets`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-ATL-PIN-EGRESS-MULTI-ROUTE.2` shipped the bounded one-child resolved-child output to top-level output route set without adding mux/storage or fan-in/fan-out semantics. |

## Decisions

- `2026-05-22`: Selected pin egress after pin ingress because the current
  generated-child egress fixture already routes one resolved-child output to
  one top-level output after the child event wait. The bounded widening can
  preserve that timing model and add adjacent drive calls without choosing
  mux/storage, fan-in/fan-out, or bidirectional pin semantics.
- `2026-05-22`: Kept the same existing `(sink source)` drive-body order. The
  scheduler may accept several contiguous route drive calls only when every
  route is a one-bit `scalar_actor_to_pin_handoff` from the same resolved child
  and no route-local mux, storage, or arbitration is implied.

## Open Questions

- None blocking the current bounded subset.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-ATL-PIN-EGRESS-MULTI-ROUTE.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-22` | `ISF-ATL-PIN-EGRESS-MULTI-ROUTE.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1322-isf-actor-network-static.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1324-isf-atl-fixture-coverage.t t/1325-isf-atl-data-route-fixture-coverage.t t/1326-isf-atl-pin-ingress-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1328-isf-atl-trigger-wait-fixture-coverage.t t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t t/1331-isf-timing-conventions.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ATL-PIN-EGRESS-MULTI-ROUTE.1` | `this commit: ISF-ATL-PIN-EGRESS-MULTI-ROUTE.1: select ATL pin-egress multi-route slice` | Selection committed. |
| `ISF-ATL-PIN-EGRESS-MULTI-ROUTE.2` | `this commit: ISF-ATL-PIN-EGRESS-MULTI-ROUTE.2: ship bounded ATL pin-egress route sets` | Implementation committed through this slice. |

## Changelog

- `2026-05-22`: Created active R14 task tree and selected the bounded
  implementation leaf.
- `2026-05-22`: Shipped the bounded one-child pin-egress multi-route subset,
  synchronized public docs and the mdBook, and closed the tree.
