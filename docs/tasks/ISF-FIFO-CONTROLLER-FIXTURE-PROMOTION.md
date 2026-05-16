# ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION: FIFO Controller Fixture Promotion

## Metadata

- Tree ID: `ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Promote the checked-in FIFO controller matrix fixture to file-backed schedule
JSON, scheduled `.fsm`, strict-mode, and HDL reachability coverage.

## Non-Goals

- Adding FIFO data-bank storage to the controller fixture.
- Changing same-cycle push/pop occupancy, full/empty, or pointer semantics.
- Changing generated HDL port-pruning behavior for unused interface signals.
- Adding the fixture to the quick/smoke tier.
- Snapshotting full generated HDL or full schedule JSON.

## Acceptance Criteria

- `isf/fifo_controller.isf` is covered as a file-backed depth-4 FIFO
  controller matrix fixture.
- A regression proves scheduled `.fsm` structure, schedule-report metadata,
  strict schedule JSON parity, and plain plus strict HDL generation.
- Public `tested_by` metadata, the ISF spec, downstream handoff, public
  contract, mdBook, fixture matrix, live docs, README, roadmap board, and task
  tree stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION`
  Status: `done`
  Goal: `Promote FIFO controller matrix behavior to file-backed schedule/strict/HDL coverage.`
  Children: `ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.1`

- ID: `ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.1`
  Status: `done`
  Goal: `Add fixture-promotion regression coverage for the FIFO controller matrix.`
  Acceptance: `The regression proves in-process and CLI behavior, public metadata/docs are synchronized, and focused plus ISF regression gates pass.`
  Verification: `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm t/1320-isf-fifo-controller-fixture-coverage.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t`; `prove -l t/1320-isf-fifo-controller-fixture-coverage.t t/1235-isf-fifo-same-cycle-update-matrix.t t/1255-isf-schedule-report-golden-matrix.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.1: promote FIFO controller fixture coverage`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The FIFO controller matrix fixture now has file-backed schedule/report/strict/HDL coverage. |

## Decisions

- `2026-05-16`: Treat this as controller-only promotion. The fixture must not
  claim data-bank storage or `data_out` datapath behavior; that behavior is
  owned by the FIFO datapath and reusable FIFO fixtures.
- `2026-05-16`: Keep the fixture in the broader `isf` regression tier, not
  the curated quick/smoke tier.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.1` | `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm t/1320-isf-fifo-controller-fixture-coverage.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t` | `PASS` |
| `2026-05-16` | `ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.1` | `prove -l t/1320-isf-fifo-controller-fixture-coverage.t t/1235-isf-fifo-same-cycle-update-matrix.t t/1255-isf-schedule-report-golden-matrix.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t` | `PASS: Files=7, Tests=105` |
| `2026-05-16` | `ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.1` | `./bin/ci-regression isf --no-book` | `PASS: Files=226, Tests=992` |
| `2026-05-16` | `ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.1` | `mdbook build docs/book` | `PASS` |
| `2026-05-16` | `ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.1` | `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.1` | `ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.1: promote FIFO controller fixture coverage` | `Task-scoped commit subject for this completed leaf.` |

## Changelog

- `2026-05-16`: Created task tree and started the FIFO controller fixture
  promotion leaf.
- `2026-05-16`: Added file-backed schedule/report/strict/HDL coverage for
  `isf/fifo_controller.isf`, synchronized public metadata and docs, and closed
  the task tree.
