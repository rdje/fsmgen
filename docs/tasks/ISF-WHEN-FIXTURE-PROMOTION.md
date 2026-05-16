# ISF-WHEN-FIXTURE-PROMOTION: When Fixture Promotion

## Metadata

- Tree ID: `ISF-WHEN-FIXTURE-PROMOTION`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Promote the checked-in conditional `when` ISF fixture to file-backed schedule
JSON, scheduled `.fsm`, strict-mode, and HDL reachability coverage.

## Non-Goals

- Widening `when` syntax or condition semantics.
- Adding nested child activation or await-sync behavior inside `when` bodies.
- Adding the fixture to the quick/smoke tier.
- Snapshotting full generated HDL or full schedule JSON.

## Acceptance Criteria

- The fixture covers entry drive setup, two conditional `when` decision states,
  multi-step true-body drives, false-path fallthrough, named-drive fan-in, and
  delayed completion pulse behavior.
- A file-backed regression proves scheduled `.fsm` structure, schedule-report
  metadata, strict schedule JSON parity, and plain plus strict HDL generation.
- Public `tested_by` metadata, the ISF spec, downstream handoff, public
  contract, mdBook, fixture matrix, live docs, README, roadmap board, and task
  tree stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-WHEN-FIXTURE-PROMOTION`
  Status: `done`
  Goal: `Promote the when fixture to file-backed schedule/strict/HDL coverage.`
  Children: `ISF-WHEN-FIXTURE-PROMOTION.1`

- ID: `ISF-WHEN-FIXTURE-PROMOTION.1`
  Status: `done`
  Goal: `Add schedule/report/strict/HDL regression coverage for the when fixture.`
  Acceptance: `The new regression proves in-process and CLI behavior, public metadata/docs are synchronized, and focused plus ISF regression gates pass.`
  Verification: `prove -l t/1314-isf-when-fixture-coverage.t t/1104-isf-when-branch-exits.t t/1107-isf-when-body-ops.t t/1206-isf-when-clause-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `git diff --check`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`
  Commit: `ISF-WHEN-FIXTURE-PROMOTION.1: promote when fixture coverage`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The when fixture now has file-backed schedule/report/strict/HDL coverage. |

## Decisions

- `2026-05-16`: Treat the fixture as bounded transaction-local conditional
  body coverage, not as a claim about deferred nested child/await-sync bodies.
- `2026-05-16`: Keep the fixture in the broader `isf` regression tier, not
  the curated quick/smoke tier.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-WHEN-FIXTURE-PROMOTION.1` | `prove -l t/1314-isf-when-fixture-coverage.t t/1104-isf-when-branch-exits.t t/1107-isf-when-body-ops.t t/1206-isf-when-clause-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t` | `PASS: Files=8, Tests=102` |
| `2026-05-16` | `ISF-WHEN-FIXTURE-PROMOTION.1` | `git diff --check` | `PASS` |
| `2026-05-16` | `ISF-WHEN-FIXTURE-PROMOTION.1` | `mdbook build docs/book` | `PASS` |
| `2026-05-16` | `ISF-WHEN-FIXTURE-PROMOTION.1` | `./bin/ci-regression isf --no-book` | `PASS: Files=220, Tests=967` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-WHEN-FIXTURE-PROMOTION.1` | `ISF-WHEN-FIXTURE-PROMOTION.1: promote when fixture coverage` | `Task-scoped commit subject for this completed leaf.` |

## Changelog

- `2026-05-16`: Created task tree and started the when fixture promotion
  leaf.
- `2026-05-16`: Added file-backed schedule/report/strict/HDL coverage for
  `isf/when_test.isf`, synchronized public metadata and docs, and closed the
  task tree.
