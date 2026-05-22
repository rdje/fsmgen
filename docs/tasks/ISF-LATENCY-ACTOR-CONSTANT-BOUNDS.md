# ISF-LATENCY-ACTOR-CONSTANT-BOUNDS: Latency Actor-Constant Bounds

## Metadata

- Tree ID: `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS`
- Status: `completed`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Allow transaction latency `(min ...)` and `(max ...)` bounds to use positive
actor constants anywhere the shipped positive literal bound is accepted.

## Non-Goals

- Do not accept actor parameters, transaction parameters, runtime signals, or
  arbitrary expressions as latency bounds.
- Do not change latency counter semantics, timeout-state semantics, latency
  report/storage roles, or generated HDL behavior beyond resolving static
  actor constants before existing lowering.
- Do not add stage-local latency or actor-level stage runtime semantics.

## Acceptance Criteria

- `(latency (min MIN_CONST) (max MAX_CONST))` lowers when each token is a
  declared actor constant whose resolved value is positive.
- Literal bounds keep existing behavior and diagnostics.
- Unknown, zero-valued, parameter-backed, and dynamic bound tokens remain
  fail-closed with targeted diagnostics.
- The ISF spec, mdBook, downstream/public guidance where relevant, roadmap
  status, task tree, and live docs are synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS`
  Status: `completed`
  Goal: `ship positive actor constants as transaction latency bounds`
  Children: `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.1`,
  `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.2`

- ID: `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.1`
  Status: `done`
  Goal: `select the latency actor-constant bounds task tree`
  Acceptance: `task-tree owner, source boundary, non-goals, and implementation leaf are recorded before code`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `4cfcce88 ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.1: select latency actor-constant bounds`

- ID: `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.2`
  Status: `done`
  Goal: `implement and document actor-constant transaction latency bounds`
  Acceptance: `positive actor constants lower as literal latency bounds; unsupported bound tokens fail closed; docs and focused tests are synchronized`
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1197-isf-latency-clause-boundary.t`; focused latency/schedule/contract tests; public/doc audits; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `pending this commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.2` | `done` | Completed; no remaining frontier in this tree. |

## Decisions

- `2026-05-22`: Treat actor constants as static compile-time evidence for
  latency bounds, matching wait counts and temporal contract windows.
  Parameters remain out of scope because they are overrideable specialization
  values.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| 2026-05-22 | `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.1` | `mdbook build docs/book`; `git diff --check` | Pass |
| 2026-05-22 | `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1197-isf-latency-clause-boundary.t`; `prove -Iperl t/1197-isf-latency-clause-boundary.t t/1096-isf-schedule-json-report.t t/1106-isf-schedule-json-counter-storage.t t/1224-isf-contract-lowering.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | Pass; broad ISF gate `Files=238, Tests=1585` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.1` | `4cfcce88 ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.1: select latency actor-constant bounds` | Selection commit. |
| `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.2` | `pending this commit: ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.2: ship latency actor-constant bounds` | Implementation and documentation commit. |

## Changelog

- `2026-05-22`: Created active R14 task tree for positive actor constants in
  transaction latency min/max bounds.
- `2026-05-22`: Shipped positive actor constants for transaction latency
  min/max bounds, with parameters and dynamic bounds still fail-closed.
