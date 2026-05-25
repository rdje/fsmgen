# ISF-TIMING-CONVENTIONS: Default Actor Timing Conventions

## Metadata

- Tree ID: `ISF-TIMING-CONVENTIONS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Ship convention-over-configuration timing defaults for ISF actors that omit
actor-level clock, reset, or watchdog declarations.

## Non-Goals

- Do not change the meaning of explicit `(clock ...)`, `(reset ...)`, or
  `(watchdog ...)` clauses.
- Do not add actor-level timing defaults to actors that use
  `(clock-domains ...)`, because named domains own their clocks and resets.
- Do not change the shipped flat reset source form; explicit `(reset name)`
  keeps its existing synchronous reset semantics unless a future slice selects
  a compatibility change.
- Do not add new watchdog syntax or per-await watchdog behavior.

## Acceptance Criteria

- A legacy single-clock actor that omits `(clock ...)` behaves as if
  `(clock clk)` was declared.
- A legacy single-clock actor that omits `(reset ...)` behaves as if
  `(reset (rst_n async active_low))` was declared.
- Any actor that omits `(watchdog ...)` reports and lowers with watchdog limit
  `65535`, exactly `(2^16 - 1)`.
- Explicit actor-level timing clauses override the defaults exactly as authored,
  and duplicate singleton diagnostics remain unchanged.
- Actors using `(clock-domains ...)` keep domain-owned clock/reset semantics;
  omitted domain resets remain omitted, while the actor watchdog default still
  applies.
- Specs, public contract text, downstream handoff, mdBook, tests, and live docs
  describe the defaulted behavior transparently.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TIMING-CONVENTIONS`
  Status: `done`
  Goal: `Ship default actor timing conventions for omitted ISF timing clauses.`
  Children: `ISF-TIMING-CONVENTIONS.1`

- ID: `ISF-TIMING-CONVENTIONS.1`
  Status: `done`
  Goal: `Implement and document omitted clock/reset/watchdog defaults.`
  Acceptance: `Parser output, lowering, schedule reports, public-contract metadata, specs, downstream handoff, and the mdBook all agree that omitted single-clock actor timing defaults to clock clk, async active-low reset rst_n, and watchdog 65535, while explicit clauses and named clock-domain timing remain source-owned.`
  Verification: `passed`
  Commit: `d5bf42e2 ISF-TIMING-CONVENTIONS.1: default omitted actor timing`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TIMING-CONVENTIONS.1` | `done` | User requested convention-over-configuration defaults for omitted actor clock, reset, and watchdog clauses. |

## Decisions

- `2026-05-20`: The convention applies only when an actor omits the timing
  clause. Explicit timing syntax remains author-owned.
- `2026-05-20`: Single-clock legacy actors receive default clock and reset
  clauses; named clock-domain actors keep domain-owned clock/reset semantics.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `ISF-TIMING-CONVENTIONS.1` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1331-isf-timing-conventions.t t/1165-isf-public-actor-shell-timing-shape-audit.t t/1152-isf-public-report-scalar-metadata-audit.t t/1159-isf-public-report-reset-shape-metadata-audit.t`; `prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1255-isf-schedule-report-golden-matrix.t`; `prove -Iperl t/1096-isf-schedule-json-report.t t/1247-isf-clock-domain-partition.t`; `mdbook build docs/book`; `prove -Iperl t/1230-isf-library-import-resolution.t t/1331-isf-timing-conventions.t`; `./bin/ci-regression isf --no-book` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TIMING-CONVENTIONS.1` | `d5bf42e2 ISF-TIMING-CONVENTIONS.1: default omitted actor timing` | `Default actor timing conventions implemented and documented.` |

## Changelog

- `2026-05-20`: Created task tree and selected the convention-over-configuration implementation leaf.
- `2026-05-20`: Completed `ISF-TIMING-CONVENTIONS.1`; omitted legacy single-clock actor timing now defaults to `clk`, async active-low `rst_n`, and watchdog `65535`, while explicit timing and named clock-domain ownership remain source-owned.
