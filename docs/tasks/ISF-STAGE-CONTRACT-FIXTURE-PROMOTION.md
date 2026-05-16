# ISF-STAGE-CONTRACT-FIXTURE-PROMOTION: Stage Contract Fixture Promotion

## Metadata

- Tree ID: `ISF-STAGE-CONTRACT-FIXTURE-PROMOTION`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Promote a checked-in ready/valid stage plus bounded temporal-contract ISF
fixture to file-backed schedule JSON, scheduled `.fsm`, strict-mode, and HDL
reachability coverage.

## Non-Goals

- Widening transaction stage syntax beyond the shipped top-level
  ready/valid barrier.
- Widening temporal contracts beyond top-level bounded eventual checks.
- Changing monitor overlap policy, reset policy, or assertion projection.
- Adding the fixture to the quick/smoke tier.
- Snapshotting full generated HDL or full schedule JSON.

## Acceptance Criteria

- The fixture combines a sampled payload, a top-level ready/valid stage, a
  top-level bounded eventual contract, and ordinary completion.
- A file-backed regression proves scheduled `.fsm` structure, schedule-report
  metadata, strict schedule JSON parity, and plain plus strict HDL generation.
- Public `tested_by` metadata, the ISF spec, downstream handoff, public
  contract, mdBook, fixture matrix, live docs, README, roadmap board, and task
  tree stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-STAGE-CONTRACT-FIXTURE-PROMOTION`
  Status: `done`
  Goal: `Promote stage plus bounded temporal-contract coverage to a realistic file-backed fixture.`
  Children: `ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.1`

- ID: `ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.1`
  Status: `done`
  Goal: `Add fixture and regression coverage for a ready/valid stage with a bounded eventual contract.`
  Acceptance: `The new fixture and regression prove in-process and CLI behavior, public metadata/docs are synchronized, and focused plus ISF regression gates pass.`
  Verification: `prove -l t/1317-isf-stage-contract-fixture-coverage.t t/1223-isf-stage-lowering.t t/1224-isf-contract-lowering.t t/1225-isf-stage-contract-schedule-report.t t/1254-isf-temporal-contract-storage-report.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.1: promote stage contract fixture coverage`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The stage/contract fixture now has file-backed schedule/report/strict/HDL coverage. |

## Decisions

- `2026-05-16`: Treat the fixture as bounded ready/valid plus bounded
  eventual-contract coverage, not as a claim for nested stages, nested
  contracts, expression contracts, or wider temporal logic.
- `2026-05-16`: Keep the fixture in the broader `isf` regression tier, not
  the curated quick/smoke tier.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.1` | `prove -l t/1317-isf-stage-contract-fixture-coverage.t t/1223-isf-stage-lowering.t t/1224-isf-contract-lowering.t t/1225-isf-stage-contract-schedule-report.t t/1254-isf-temporal-contract-storage-report.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t` | `PASS: Files=9, Tests=112` |
| `2026-05-16` | `ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.1` | `./bin/ci-regression isf --no-book` | `PASS: Files=223, Tests=979` |
| `2026-05-16` | `ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.1` | `mdbook build docs/book` | `PASS` |
| `2026-05-16` | `ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.1` | `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.1` | `ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.1: promote stage contract fixture coverage` | `Task-scoped commit subject for this completed leaf.` |

## Changelog

- `2026-05-16`: Created task tree and started the stage/contract fixture
  promotion leaf.
- `2026-05-16`: Added `isf/stream_stage_contract.isf`, file-backed
  schedule/report/strict/HDL coverage, synchronized public metadata and docs,
  and closed the task tree.
