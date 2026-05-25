# ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC: Feature Matrix Coverage Synchronization

## Metadata

- Tree ID: `ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Expand the ISF book shipped-feature matrix so shipped transaction stage
lowering and temporal contract assertion projection are visible as explicit
feature-family rows, not only implicit parts of schedule-report or diagnostic
coverage.

## Non-Goals

- Do not change parser, scheduler, emitter, schedule-report, generated `.fsm`,
  generated HDL, or public manifest behavior.
- Do not widen stage or contract syntax beyond the already-shipped bounded
  top-level subsets.
- Do not mark broader stage/contract forms as shipped.

## Acceptance Criteria

- The ISF shipped feature matrix has explicit rows for transaction stage
  lowering and temporal contracts/SystemVerilog assertion projection.
- The matrix examples or non-claims keep the broader stage/contract backlog
  boundary visible.
- The existing matrix audit is updated so those shipped rows cannot disappear.
- Live docs and roadmap/task-tree state are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC`
  Status: `done`
  Goal: `Add missing shipped stage/contract rows to the ISF feature matrix.`
  Children: `ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC.1`

- ID: `ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC.1`
  Status: `done`
  Goal: `Synchronize feature-matrix coverage for shipped stage and contract features.`
  Acceptance: `The matrix and audit explicitly cover the shipped stage and
  temporal-contract rows while preserving broader backlog wording.`
  Verification: `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`;
  `prove -Iperl t/1305-isf-book-feature-matrix-audit.t
  t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`;
  `./bin/ci-regression isf --no-book`; `git diff --check`
  Commit: `e180fd09 ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC.1: cover stage contracts`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC.1` | `done` | The support matrix must enumerate shipped stage and temporal-contract features explicitly. |

## Decisions

- `2026-05-16`: This is a matrix coverage sync, not a stage/contract behavior
  change.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC.1` | `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | passed; ISF gate Files=213, Tests=899 |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC.1` | `e180fd09 ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC.1: cover stage contracts` | `completion commit` |

## Changelog

- `2026-05-16`: Added explicit transaction stage and temporal contract rows to
  the ISF shipped feature matrix and widened the matrix audit.
