# ISF-UART-FIXTURE-PROMOTION: UART Fixture Promotion

## Metadata

- Tree ID: `ISF-UART-FIXTURE-PROMOTION`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Promote the UART transmit ISF fixture from focused shift-right smoke coverage
to file-backed schedule JSON, strict-mode, and HDL reachability coverage.

## Non-Goals

- Claiming complete UART protocol compliance.
- Adding baud timing or oversampling behavior.
- Adding the fixture to the quick/smoke tier.
- Snapshotting full generated HDL or full schedule JSON.
- Widening ISF shift or drive semantics.

## Acceptance Criteria

- The fixture drives the serial `tx` output from an explicit sampled-byte bit
  selection instead of the full sampled byte.
- The fixture still covers parameterized drives, repeat, known-width
  `shift_right`, sampled aliases, busy drive sequencing, and completion pulse
  behavior.
- A file-backed regression proves scheduled `.fsm` structure, schedule-report
  metadata, strict schedule JSON parity, and plain plus strict HDL generation.
- Public `tested_by` metadata, the ISF spec, downstream handoff, public
  contract, mdBook, live docs, README, roadmap board, and task tree stay
  synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-UART-FIXTURE-PROMOTION`
  Status: `done`
  Goal: `Promote the UART fixture to file-backed schedule/strict/HDL coverage.`
  Children: `ISF-UART-FIXTURE-PROMOTION.1`

- ID: `ISF-UART-FIXTURE-PROMOTION.1`
  Status: `done`
  Goal: `Refresh the UART serial-bit drive and add schedule/report/strict/HDL regression coverage.`
  Acceptance: `The fixture avoids implicit truncation, the new regression proves in-process and CLI behavior, public metadata/docs are synchronized, and focused plus ISF regression gates pass.`
  Verification: `prove -l t/1311-isf-uart-fixture-coverage.t t/1099-isf-repeat-data-ops.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `git diff --check`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`
  Commit: `ISF-UART-FIXTURE-PROMOTION.1: promote UART fixture coverage`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The UART fixture now uses explicit sampled-byte bit selection and has file-backed schedule/report/strict/HDL coverage. |

## Decisions

- `2026-05-16`: Treat this as a bounded UART-like transmit fixture, not a
  complete UART protocol compliance suite.
- `2026-05-16`: Keep the fixture in the broader `isf` regression tier, not the
  curated quick/smoke tier.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-UART-FIXTURE-PROMOTION.1` | `prove -l t/1311-isf-uart-fixture-coverage.t t/1099-isf-repeat-data-ops.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t` | `PASS: Files=6, Tests=96` |
| `2026-05-16` | `ISF-UART-FIXTURE-PROMOTION.1` | `git diff --check` | `PASS` |
| `2026-05-16` | `ISF-UART-FIXTURE-PROMOTION.1` | `mdbook build docs/book` | `PASS` |
| `2026-05-16` | `ISF-UART-FIXTURE-PROMOTION.1` | `./bin/ci-regression isf --no-book` | `PASS: Files=217, Tests=955` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-UART-FIXTURE-PROMOTION.1` | `ISF-UART-FIXTURE-PROMOTION.1: promote UART fixture coverage` | `Task-scoped commit subject for this completed leaf.` |

## Changelog

- `2026-05-16`: Created task tree and started the UART fixture promotion leaf.
- `2026-05-16`: Updated `isf/uart_tx.isf` to drive `tx` from `byte_data[0]`,
  added file-backed schedule/report/strict/HDL coverage, synchronized public
  metadata and docs, and closed the task tree.
