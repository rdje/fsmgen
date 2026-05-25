# ISF-ATL-PIN-INGRESS-MULTI-ROUTE: Bounded ATL Pin-Ingress Multi-Route

## Metadata

- Tree ID: `ISF-ATL-PIN-INGRESS-MULTI-ROUTE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Widen the generated-child ATL top-level input-pin to resolved-child input
route from one scalar route to a bounded multiple-route subset. The selected
shape lets several one-bit top-level input pins feed several one-bit inputs on
one resolved child through adjacent named drive calls before that child is
triggered.

## Non-Goals

- Do not add new source syntax beyond existing drive bodies and drive calls.
- Do not widen child-to-top-level-output pin egress in this tree.
- Do not widen actor-to-actor generated-child routes in this tree.
- Do not introduce route mux/storage, fan-in/fan-out, ready/backpressure,
  payload protocols, CDC/reset remapping, recursive actor networks, group
  endpoints, repeated child activations, or cross-transaction continuation.
- Do not allow multiple source pins to drive one child endpoint, one source pin
  to drive multiple child endpoints, or any route that crosses parent
  transactions.

## Acceptance Criteria

- The selected source shape is documented before code changes.
- The implementation accepts multiple one-bit generated-child pin-ingress
  routes only when all routes target the same resolved child, live in the same
  parent transaction, use one scalar `(child.endpoint pins.input_pin)` pair per
  drive body, and are activated by contiguous argument-free drive calls before
  the child trigger/event wait sequence.
- Generated parent `.fsm`, generated ATL top `.fsm`, schedule JSON, and
  SystemVerilog reachability are regression-covered for the positive subset.
- Existing fail-closed diagnostics remain targeted for wider pins, missing
  child inputs, repeated route drive calls, parameterized route drive calls,
  interleaved parent work, cross-transaction routes, and endpoint expressions.
- mdBook, ISF spec, downstream integration spec, public contract, live docs,
  and task-tree status are synchronized with the shipped subset and explicit
  non-claims.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ATL-PIN-INGRESS-MULTI-ROUTE`
  Status: `done`
  Goal: `ship a bounded generated-child ATL top-level pin-ingress multi-route scalar subset`
  Children: `ISF-ATL-PIN-INGRESS-MULTI-ROUTE.1`,
  `ISF-ATL-PIN-INGRESS-MULTI-ROUTE.2`

- ID: `ISF-ATL-PIN-INGRESS-MULTI-ROUTE.1`
  Status: `done`
  Goal: `select the bounded ATL pin-ingress multi-route feature slice`
  Acceptance: `task-tree owner, scope, boundaries, and implementation leaf are recorded before code changes`
  Verification: `git diff --check; mdbook build docs/book`
  Commit: `bb755776 ISF-ATL-PIN-INGRESS-MULTI-ROUTE.1: select ATL pin-ingress multi-route slice`

- ID: `ISF-ATL-PIN-INGRESS-MULTI-ROUTE.2`
  Status: `done`
  Goal: `implement bounded multiple scalar generated-child pin-ingress routes`
  Acceptance: `positive fixture, schedule report, generated top wiring, HDL reachability, docs, and focused gates prove the shipped subset`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c t/1322-isf-actor-network-static.t; perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t; perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1322-isf-actor-network-static.t; prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t; prove -Iperl t/1324-isf-atl-fixture-coverage.t t/1325-isf-atl-data-route-fixture-coverage.t t/1326-isf-atl-pin-ingress-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1328-isf-atl-trigger-wait-fixture-coverage.t t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t t/1331-isf-timing-conventions.t; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `5e973aa1 ISF-ATL-PIN-INGRESS-MULTI-ROUTE.2: ship bounded ATL pin-ingress route sets`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-ATL-PIN-INGRESS-MULTI-ROUTE.2` shipped the bounded one-child top-level input-pin ingress route set without adding mux/storage or fan-in/fan-out semantics. |

## Decisions

- `2026-05-22`: Selected pin ingress before pin egress because the current
  generated-child ingress fixture already routes one top-level input into one
  child input before the child trigger. The bounded widening can preserve that
  timing model and add adjacent drive calls without choosing egress publication
  or bidirectional pin movement semantics.
- `2026-05-22`: Kept the same existing `(sink source)` drive-body order. The
  scheduler may accept several contiguous route drive calls only when every
  route is a one-bit `scalar_pin_to_actor_handoff` into the same resolved
  child and no route-local mux, storage, or arbitration is implied.

## Open Questions

- None blocking the current bounded subset.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-ATL-PIN-INGRESS-MULTI-ROUTE.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-22` | `ISF-ATL-PIN-INGRESS-MULTI-ROUTE.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1322-isf-actor-network-static.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1324-isf-atl-fixture-coverage.t t/1325-isf-atl-data-route-fixture-coverage.t t/1326-isf-atl-pin-ingress-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1328-isf-atl-trigger-wait-fixture-coverage.t t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t t/1331-isf-timing-conventions.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ATL-PIN-INGRESS-MULTI-ROUTE.1` | `bb755776 ISF-ATL-PIN-INGRESS-MULTI-ROUTE.1: select ATL pin-ingress multi-route slice` | Selection committed. |
| `ISF-ATL-PIN-INGRESS-MULTI-ROUTE.2` | `5e973aa1 ISF-ATL-PIN-INGRESS-MULTI-ROUTE.2: ship bounded ATL pin-ingress route sets` | Implementation committed through this slice. |

## Changelog

- `2026-05-22`: Created active R14 task tree and selected the bounded
  implementation leaf.
- `2026-05-22`: Shipped the bounded one-child pin-ingress multi-route subset,
  synchronized public docs and the mdBook, and closed the tree.
