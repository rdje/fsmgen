# ISF-ATL-PIN-VECTOR-MULTI-ROUTE: ATL Pin Vector Multi-Route

## Metadata

- Tree ID: `ISF-ATL-PIN-VECTOR-MULTI-ROUTE`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Widen the generated-child ATL top-level pin multi-route subsets from scalar
one-bit routes only to exact-width vector route sets. The source syntax stays
the existing drive-body `(sink source)` pair, each drive call remains the
explicit transfer timing cycle, and every route must prove matching top-level
pin and resolved child endpoint widths before scheduled `.fsm` emission.

## Non-Goals

- Do not add width adaptation, packing, truncation, sign extension, zero
  extension, slicing, aggregate payloads, or route-side transforms.
- Do not mix scalar and vector routes in the same generated-child pin
  multi-route set.
- Do not add route mux/storage, fan-in/fan-out, ready/backpressure, payload
  protocols, CDC/reset remapping, repeated child activations,
  cross-transaction continuation, recursive actor networks, or permanent actor
  grouping.
- Do not change existing scalar pin multi-route behavior or the existing
  one-route exact-width vector pin-ingress/pin-egress behavior.
- Do not widen actor-to-actor vector routes; those are owned by
  `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH`.

## Acceptance Criteria

- The selected vector pin multi-route subset is documented before code
  changes.
- A generated-child pin-ingress route set with two or more vector top-level
  input pins feeding matching resolved child input endpoints lowers through
  parent handoff ports and generated-top/HDL links with each exact route width.
- A generated-child pin-egress route set with two or more vector resolved
  child outputs feeding matching top-level output pins lowers through parent
  handoff ports and generated-top/HDL links with each exact route width.
- Schedule JSON reports each route through the existing
  `actor_network.data_movements[]` entry shape with the route-local width and
  the existing vector pin route width-source value.
- Mismatched top-level pin and child endpoint widths fail closed before
  scheduled `.fsm` emission with targeted diagnostics.
- Focused fixture coverage proves parent/child/top `.fsm` artifacts, schedule
  JSON, strict outdir materialization, plain HDL generation, strict HDL
  generation, and mismatch failures for each shipped direction.
- ISF spec, downstream handoff, public contract, ATL design proposal, mdBook,
  roadmap, task tree, and live docs are synchronized with the shipped behavior
  and non-claims.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ATL-PIN-VECTOR-MULTI-ROUTE`
  Status: `active`
  Goal: `ship exact-width vector generated-child ATL top-level pin multi-route sets`
  Children: `ISF-ATL-PIN-VECTOR-MULTI-ROUTE.1`,
  `ISF-ATL-PIN-VECTOR-MULTI-ROUTE.2`,
  `ISF-ATL-PIN-VECTOR-MULTI-ROUTE.3`

- ID: `ISF-ATL-PIN-VECTOR-MULTI-ROUTE.1`
  Status: `done`
  Goal: `select the bounded ATL pin vector multi-route tree`
  Acceptance: `task-tree owner, scope, boundaries, and implementation leaves are recorded before code changes`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `this commit: ISF-ATL-PIN-VECTOR-MULTI-ROUTE.1: select ATL pin vector multi-route`

- ID: `ISF-ATL-PIN-VECTOR-MULTI-ROUTE.2`
  Status: `done`
  Goal: `implement exact-width vector generated-child pin-ingress multi-route sets`
  Acceptance: `matching-width top-level input to resolved-child input vector route sets lower through parent/top/HDL artifacts, mismatches fail closed, and public docs describe the shipped boundary`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`;
  `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`;
  `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`;
  `prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t`;
  `prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1326-isf-atl-pin-ingress-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t`;
  `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1332-isf-atl-doc-status-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`;
  `mdbook build docs/book`; `./bin/ci-regression isf --no-book`;
  `git diff --check`
  Commit: `this commit: ISF-ATL-PIN-VECTOR-MULTI-ROUTE.2: ship ATL pin-ingress vector multi-route`

- ID: `ISF-ATL-PIN-VECTOR-MULTI-ROUTE.3`
  Status: `pending`
  Goal: `implement exact-width vector generated-child pin-egress multi-route sets`
  Acceptance: `matching-width resolved-child output to top-level output vector route sets lower through parent/top/HDL artifacts, mismatches fail closed, and public docs describe the shipped boundary`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ATL-PIN-VECTOR-MULTI-ROUTE.3` | `pending` | Pin-egress follows the shipped ingress vector multi-route subset so the inverse post-event direction can reuse the same exact-width vector route-set policy. |

## Decisions

- `2026-05-22`: Selected exact-width vector same-child pin multi-route sets as
  the next bounded ATL widening. This combines two shipped surfaces: scalar
  same-child pin multi-route sets and one-route exact-width vector pin routes.
- `2026-05-22`: Kept mixed scalar/vector route sets out of scope for this
  tree. The first vector multi-route contract is simpler to review when every
  route in the set is vector and each route proves its own top-pin/child-port
  exact-width match.
- `2026-05-22`: Kept width adaptation, route storage, muxing, fan-in/fan-out,
  ready/backpressure, payload protocols, CDC/reset remapping, repeated
  activation, and cross-transaction continuation deferred.
- `2026-05-22`: Shipped `.2` without adding new syntax. The existing
  `(sink source)` drive-body route and drive-call timing now cover multiple
  vector pin-ingress routes when all routes share one resolved child and
  parent transaction, remain adjacent before the trigger, and prove exact
  route-local top-input/child-input widths.

## Open Questions

- None blocking the selected bounded subset.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-ATL-PIN-VECTOR-MULTI-ROUTE.1` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-22` | `ISF-ATL-PIN-VECTOR-MULTI-ROUTE.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1326-isf-atl-pin-ingress-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1332-isf-atl-doc-status-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `passed: Files=238, Tests=1565` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ATL-PIN-VECTOR-MULTI-ROUTE.1` | `this commit: ISF-ATL-PIN-VECTOR-MULTI-ROUTE.1: select ATL pin vector multi-route` | Selection committed. |
| `ISF-ATL-PIN-VECTOR-MULTI-ROUTE.2` | `this commit: ISF-ATL-PIN-VECTOR-MULTI-ROUTE.2: ship ATL pin-ingress vector multi-route` | Exact-width vector pin-ingress route-set committed. |

## Changelog

- `2026-05-22`: Created active R14 task tree and selected the bounded
  generated-child top-level pin vector multi-route implementation sequence.
- `2026-05-22`: Completed `.1`: the active frontier is now `.2`, exact-width
  vector same-child pin-ingress multi-route sets.
- `2026-05-22`: Completed `.2`: the active frontier is now `.3`, exact-width
  vector same-child pin-egress multi-route sets.
