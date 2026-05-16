# ISF-FIFO-DATAPATH-FIXTURE-PROMOTION: FIFO Datapath Fixture Promotion

## Metadata

- Tree ID: `ISF-FIFO-DATAPATH-FIXTURE-PROMOTION`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Promote the checked-in FIFO datapath fixture for actor-owned bank store/load
to file-backed schedule JSON, scheduled `.fsm`, strict-mode, and HDL
reachability coverage.

## Non-Goals

- Changing bank store/load syntax or same-cycle read/write policy.
- Adding general memory-array HDL emission for banks.
- Adding the fixture to the quick/smoke tier.
- Snapshotting full generated HDL or full schedule JSON.

## Acceptance Criteria

- `isf/fifo_data_path.isf` is covered as a file-backed fixture for depth-4
  actor-owned bank store/load.
- A regression proves scheduled `.fsm` structure, bounded `bank_accesses`
  report metadata, strict schedule JSON parity, and plain plus strict HDL
  generation.
- Public `tested_by` metadata, the ISF spec, downstream handoff, public
  contract, mdBook, fixture matrix, live docs, README, roadmap board, and task
  tree stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-FIFO-DATAPATH-FIXTURE-PROMOTION`
  Status: `done`
  Goal: `Promote FIFO datapath bank access to file-backed schedule/strict/HDL coverage.`
  Children: `ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.1`

- ID: `ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.1`
  Status: `done`
  Goal: `Add fixture-promotion regression coverage for FIFO datapath bank access.`
  Acceptance: `The regression proves in-process and CLI behavior, public metadata/docs are synchronized, and focused plus ISF regression gates pass.`
  Verification: `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm t/1319-isf-fifo-datapath-fixture-coverage.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t`; `prove -l t/1319-isf-fifo-datapath-fixture-coverage.t t/1236-isf-bank-access-lowering.t t/1255-isf-schedule-report-golden-matrix.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.1: promote FIFO datapath fixture coverage`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The FIFO datapath bank-access fixture now has file-backed schedule/report/strict/HDL coverage. |

## Decisions

- `2026-05-16`: Treat this as promotion of the shipped scalarized bank access
  surface only. General memory arrays, write-first collision behavior, bypass
  policy, and arbitrary-depth parameterized FIFOs remain deferred.
- `2026-05-16`: Keep the fixture in the broader `isf` regression tier, not
  the curated quick/smoke tier.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.1` | `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm t/1319-isf-fifo-datapath-fixture-coverage.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t` | `PASS` |
| `2026-05-16` | `ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.1` | `prove -l t/1319-isf-fifo-datapath-fixture-coverage.t t/1236-isf-bank-access-lowering.t t/1255-isf-schedule-report-golden-matrix.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t` | `PASS: Files=7, Tests=105` |
| `2026-05-16` | `ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.1` | `./bin/ci-regression isf --no-book` | `PASS: Files=225, Tests=988` |
| `2026-05-16` | `ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.1` | `mdbook build docs/book` | `PASS` |
| `2026-05-16` | `ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.1` | `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.1` | `ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.1: promote FIFO datapath fixture coverage` | `Task-scoped commit subject for this completed leaf.` |

## Changelog

- `2026-05-16`: Created task tree and started the FIFO datapath fixture
  promotion leaf.
- `2026-05-16`: Added file-backed schedule/report/strict/HDL coverage for
  `isf/fifo_data_path.isf`, synchronized public metadata and docs, and closed
  the task tree.
