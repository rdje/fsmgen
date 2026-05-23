# ISF-LATENCY-ACTOR-PARAM-BOUNDS: Latency Actor-Parameter Bounds

## Metadata

- Tree ID: `ISF-LATENCY-ACTOR-PARAM-BOUNDS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Allow transaction latency `(min ...)` and `(max ...)` bounds to use actor-local
scalar parameter defaults when those defaults resolve to positive integer
literals.

## Non-Goals

- Do not support transaction parameters as latency bounds.
- Do not support runtime interface signals, storage signals, or arbitrary
  expressions as latency bounds.
- Do not specialize latency bounds through reusable-library use-site parameter
  overrides.
- Do not change latency counter timing, timeout-state semantics, schedule
  report storage roles, or generated HDL behavior beyond resolving one more
  static source kind before existing lowering.
- Do not add stage-local latency or actor-level stage runtime semantics.

## Acceptance Criteria

- `(latency (min MIN_PARAM) (max MAX_PARAM))` lowers when each token names an
  actor-local scalar parameter default whose resolved value is positive.
- Parameter-backed latency bounds lower exactly like equivalent positive
  literal/static bounds.
- Non-scalar, zero-valued, unknown, transaction-parameter, runtime, and
  expression-valued latency bounds remain fail-closed with targeted
  diagnostics.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-LATENCY-ACTOR-PARAM-BOUNDS`
  Status: `done`
  Goal: `Ship actor-parameter-backed static transaction latency bounds.`
  Children: `ISF-LATENCY-ACTOR-PARAM-BOUNDS.1`,
  `ISF-LATENCY-ACTOR-PARAM-BOUNDS.2`

- ID: `ISF-LATENCY-ACTOR-PARAM-BOUNDS.1`
  Status: `done`
  Goal: `Select latency actor-parameter bounds.`
  Acceptance: `Create the active task tree, record the static actor-parameter
  source boundary, preserve non-goals, and update roadmap/live docs without
  behavior changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `8bf157ab ISF-LATENCY-ACTOR-PARAM-BOUNDS.1: select latency actor-param bounds`

- ID: `ISF-LATENCY-ACTOR-PARAM-BOUNDS.2`
  Status: `done`
  Goal: `Implement and document actor-parameter transaction latency bounds.`
  Acceptance: `Positive actor scalar parameters lower as literal latency
  bounds; unsupported bound tokens fail closed; specs, book, public contract,
  downstream handoff, and focused tests are synchronized.`
  Verification: focused syntax, latency/public/doc tests, mdBook, diff check,
  and broad ISF regression passed.
  Commit: `pending commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | none | `closed` | All selected leaves are complete. |

## Decisions

- `2026-05-22`: Select actor-local scalar parameter defaults only. They are
  compile-time static evidence in the current actor shell, matching shipped
  parameter-backed waits, while use-site override specialization and
  transaction parameters remain deferred.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-LATENCY-ACTOR-PARAM-BOUNDS.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |
| `2026-05-22` | `ISF-LATENCY-ACTOR-PARAM-BOUNDS.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1197-isf-latency-clause-boundary.t`; `prove -Iperl t/1197-isf-latency-clause-boundary.t t/1096-isf-schedule-json-report.t t/1106-isf-schedule-json-counter-storage.t t/1224-isf-contract-lowering.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check`; `./bin/ci-regression isf --no-book` | `behavior, public contract, docs, book, and broad ISF regression passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LATENCY-ACTOR-PARAM-BOUNDS.1` | `8bf157ab ISF-LATENCY-ACTOR-PARAM-BOUNDS.1: select latency actor-param bounds` | `selects static actor-parameter latency bound support` |
| `ISF-LATENCY-ACTOR-PARAM-BOUNDS.2` | `this commit: ISF-LATENCY-ACTOR-PARAM-BOUNDS.2: ship latency actor-param bounds` | `ships actor-local scalar parameter defaults as static transaction latency min/max bounds` |

## Changelog

- `2026-05-22`: Created task tree and selected static actor-parameter
  transaction latency bounds.
- `2026-05-22`: Shipped positive actor-local scalar parameter defaults as
  transaction latency `(min ...)`/`(max ...)` bounds and synchronized the
  spec, handoff, public contract, mdBook, roadmap, task tree, and live docs.
