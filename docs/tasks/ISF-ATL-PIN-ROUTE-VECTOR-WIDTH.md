# ISF-ATL-PIN-ROUTE-VECTOR-WIDTH: ATL Pin Route Vector Width

## Metadata

- Tree ID: `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Widen the shipped generated-child ATL top-level pin route subsets from one-bit
scalar routes to exact-width vector routes when the top-level pin and resolved
child endpoint declare the same positive width. The source syntax stays the
existing drive-body `(sink source)` pair, and the parent scheduled `.fsm`
keeps owning the explicit drive-call timing cycle.

## Non-Goals

- Do not add width adaptation, packing, truncation, sign extension, zero
  extension, slicing, aggregate payloads, or route-side transforms.
- Do not add expression movement, parameterized route drives, or drive-call
  actual binding.
- Do not add mixed pin/actor route sets, bidirectional route calls, multi-child
  pin routing, route mux/storage, fan-in/fan-out, ready/backpressure,
  CDC/reset remapping, repeated child activations, cross-transaction
  continuation, recursive actor networks, or permanent actor grouping.
- Do not change the accepted one-bit pin-route syntax, ordering, or public
  report key shape.
- Do not change actor-to-actor vector routes, which are already owned by
  `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH`.

## Acceptance Criteria

- The selected vector pin-route subset is documented before code changes.
- A generated-child pin-ingress route with matching top-level input-pin and
  resolved child input widths greater than one lowers to parent handoff ports
  and generated-top/HDL links with that exact width.
- A generated-child pin-egress route with matching resolved child output and
  top-level output-pin widths greater than one lowers to parent handoff ports
  and generated-top/HDL links with that exact width.
- Schedule JSON reports each widened route through the existing
  `actor_network.data_movements[]` entry shape with `width` equal to the
  endpoint width and a distinct width-source value.
- Mismatched top-level pin and child endpoint widths fail closed before
  scheduled `.fsm` emission with targeted diagnostics; missing endpoints and
  existing malformed route boundaries keep their current diagnostics.
- Focused fixture coverage proves parent/child/top `.fsm` artifacts, schedule
  JSON, strict outdir materialization, plain HDL generation, strict HDL
  generation, and mismatch failures for each shipped direction.
- ISF spec, downstream handoff, public contract, ATL design proposal, mdBook,
  roadmap, task tree, and live docs are synchronized with the shipped behavior
  and non-claims.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH`
  Status: `done`
  Goal: `ship exact-width vector generated-child ATL top-level pin routes`
  Children: `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.1`,
  `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.2`,
  `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.3`

- ID: `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.1`
  Status: `done`
  Goal: `select the bounded ATL pin-route vector-width tree`
  Acceptance: `task-tree owner, scope, boundaries, and implementation leaves are recorded before code changes`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `b09174f1 ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.1: select ATL pin-route vector width`

- ID: `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.2`
  Status: `done`
  Goal: `implement exact-width vector generated-child pin-ingress routes`
  Acceptance: `matching-width top-level input to resolved-child input routes lower through parent/top/HDL artifacts, mismatches fail closed, and public docs describe the shipped boundary`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1326-isf-atl-pin-ingress-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`
  Commit: `44830c8f ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.2: ship ATL pin-ingress vector width`

- ID: `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.3`
  Status: `done`
  Goal: `implement exact-width vector generated-child pin-egress routes`
  Acceptance: `matching-width resolved-child output to top-level output routes lower through parent/top/HDL artifacts, mismatches fail closed, and public docs describe the shipped boundary`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `perl -Iperl -c t/1322-isf-actor-network-static.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1326-isf-atl-pin-ingress-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`
  Commit: `7c7607bb ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.3: ship ATL pin-egress vector width`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.2` | `done` | Pin-ingress shipped first because it follows the existing one-child ingress route and keeps the transfer before child activation. |
| 2 | `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.3` | `done` | Pin-egress followed ingress so the inverse post-event direction could reuse the same exact-width policy once the ingress path was proven. |

## Decisions

- `2026-05-22`: Selected exact-width generated-child top-level pin routes as
  the next ATL vector-width tree after actor-to-actor vector routes shipped.
  The route syntax, generated-top data-link model, and schedule-report `width`
  field already describe the bounded shape. The first implementation leaf is
  pin ingress because it feeds a resolved child before activation and has the
  smaller timing surface.
- `2026-05-22`: Kept width adaptation, payload protocols, route storage,
  muxing, fan-in/fan-out, CDC/reset remapping, and mixed route sets out of
  this tree. Those need explicit scheduling, generated-top, and downstream
  contracts before they can be inferred safely.
- `2026-05-22`: Shipped pin ingress before pin egress. The accepted vector
  ingress path requires one resolved child, one top-level input pin, one child
  input endpoint, and exact matching positive widths. Unresolved external
  vector pin routing remains fail-closed because FSMGen cannot validate the
  child endpoint width without actor type metadata.
- `2026-05-22`: Shipped pin egress after pin ingress and closed the tree. The
  accepted vector egress path requires one resolved child, one child output
  endpoint, one top-level output pin, and exact matching positive widths.
  Unresolved external vector pin routing remains fail-closed because FSMGen
  cannot validate the child endpoint width without actor type metadata.

## Open Questions

- None blocking the current bounded subset.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.1` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-22` | `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1326-isf-atl-pin-ingress-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book` | `passed; broad ISF gate passed with Files=238, Tests=1552` |
| `2026-05-22` | `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.3` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `perl -Iperl -c t/1322-isf-actor-network-static.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1326-isf-atl-pin-ingress-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book` | `passed; broad ISF gate passed with Files=238, Tests=1559` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.1` | `b09174f1 ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.1: select ATL pin-route vector width` | Selection committed. |
| `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.2` | `44830c8f ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.2: ship ATL pin-ingress vector width` | Exact-width generated-child pin-ingress vector route committed. |
| `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.3` | `7c7607bb ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.3: ship ATL pin-egress vector width` | Exact-width generated-child pin-egress vector route committed. |

## Changelog

- `2026-05-22`: Created active R14 task tree and selected the bounded
  generated-child top-level pin route vector-width implementation sequence.
- `2026-05-22`: Shipped `.2`: exact-width vector top-level input-pin to
  resolved-child input routes now lower through parent/top/HDL artifacts and
  report as `vector_pin_to_actor_handoff`; mismatched widths and unresolved
  external vector pin routing fail closed.
- `2026-05-22`: Shipped `.3`: exact-width vector resolved-child output to
  top-level output-pin routes now lower through parent/top/HDL artifacts and
  report as `vector_actor_to_pin_handoff`; mismatched widths and unresolved
  external vector pin routing fail closed. The tree is closed.
