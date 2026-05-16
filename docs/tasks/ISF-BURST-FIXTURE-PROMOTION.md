# ISF-BURST-FIXTURE-PROMOTION: Burst Fixture Promotion

## Metadata

- Tree ID: `ISF-BURST-FIXTURE-PROMOTION`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Promote the burst-reader ISF fixture from focused repeat-counter smoke coverage
to file-backed schedule JSON, strict-mode, and HDL reachability coverage.

## Non-Goals

- Changing burst-reader source behavior.
- Adding the fixture to the quick/smoke tier.
- Snapshotting full generated HDL or full schedule JSON.
- Widening ISF wait, repeat, latency, or watchdog semantics.

## Acceptance Criteria

- A file-backed regression proves scheduled `.fsm` structure, schedule-report
  metadata, strict schedule JSON parity, and plain plus strict HDL generation.
- The regression covers dynamic repeat counter storage, watchdog and latency
  counter roles, sampled aliases, completion/timeout pulse fan-in, and clean
  strict HDL generation.
- Public `tested_by` metadata, the ISF spec, downstream handoff, public
  contract, mdBook, live docs, README, roadmap board, and task tree stay
  synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-BURST-FIXTURE-PROMOTION`
  Status: `done`
  Goal: `Promote the burst-reader fixture to file-backed schedule/strict/HDL coverage.`
  Children: `ISF-BURST-FIXTURE-PROMOTION.1`

- ID: `ISF-BURST-FIXTURE-PROMOTION.1`
  Status: `done`
  Goal: `Add schedule/report/strict/HDL regression coverage for burst_reader.isf.`
  Acceptance: `The new regression proves in-process and CLI behavior, public metadata/docs are synchronized, and focused plus ISF regression gates pass.`
  Verification: `prove -l t/1310-isf-burst-fixture-coverage.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `git diff --check`; `./bin/ci-regression isf --no-book`
  Commit: `ISF-BURST-FIXTURE-PROMOTION.1: promote burst fixture coverage`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-BURST-FIXTURE-PROMOTION.1` | `done` | Shipped in this tree; no remaining frontier. |

## Decisions

- `2026-05-16`: Treat this as a fixture coverage promotion only; do not change
  scheduler semantics or quick-tier placement.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-BURST-FIXTURE-PROMOTION.1` | `prove -l t/1310-isf-burst-fixture-coverage.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t` | `PASS: Files=5, Tests=93` |
| `2026-05-16` | `ISF-BURST-FIXTURE-PROMOTION.1` | `git diff --check` | `PASS` |
| `2026-05-16` | `ISF-BURST-FIXTURE-PROMOTION.1` | `./bin/ci-regression isf --no-book` | `PASS: Files=216, Tests=951` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-BURST-FIXTURE-PROMOTION.1` | `ISF-BURST-FIXTURE-PROMOTION.1: promote burst fixture coverage` | `Task-scoped commit subject for this completed leaf.` |

## Changelog

- `2026-05-16`: Created task tree and started the burst-reader fixture
  promotion leaf.
- `2026-05-16`: Shipped burst-reader fixture promotion, including strict
  schedule/HDL coverage, public metadata updates, spec/book/downstream/
  public-contract synchronization, and focused plus broad validation.
