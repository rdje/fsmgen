# ISF-SWITCH-FIXTURE-PROMOTION: Switch Fixture Promotion

## Metadata

- Tree ID: `ISF-SWITCH-FIXTURE-PROMOTION`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Promote the checked-in switch dispatch ISF fixture to file-backed schedule
JSON, scheduled `.fsm`, strict-mode, and HDL reachability coverage.

## Non-Goals

- Widening switch syntax or branch semantics.
- Adding nested child activation or await-sync behavior inside switch branches.
- Adding the fixture to the quick/smoke tier.
- Snapshotting full generated HDL or full schedule JSON.

## Acceptance Criteria

- The fixture covers sampled selector capture, explicit switch branch
  dispatch, default fallthrough to completion, named-drive branch starts, and
  delayed completion pulse behavior.
- A file-backed regression proves scheduled `.fsm` structure, schedule-report
  metadata, strict schedule JSON parity, and plain plus strict HDL generation.
- Public `tested_by` metadata, the ISF spec, downstream handoff, public
  contract, mdBook, fixture matrix, live docs, README, roadmap board, and task
  tree stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-SWITCH-FIXTURE-PROMOTION`
  Status: `done`
  Goal: `Promote the switch fixture to file-backed schedule/strict/HDL coverage.`
  Children: `ISF-SWITCH-FIXTURE-PROMOTION.1`

- ID: `ISF-SWITCH-FIXTURE-PROMOTION.1`
  Status: `done`
  Goal: `Add schedule/report/strict/HDL regression coverage for the switch fixture.`
  Acceptance: `The new regression proves in-process and CLI behavior, public metadata/docs are synchronized, and focused plus ISF regression gates pass.`
  Verification: `prove -l t/1313-isf-switch-fixture-coverage.t t/1103-isf-switch-branch-exits.t t/1205-isf-switch-clause-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `git diff --check`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`
  Commit: `ISF-SWITCH-FIXTURE-PROMOTION.1: promote switch fixture coverage`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The switch fixture now has file-backed schedule/report/strict/HDL coverage. |

## Decisions

- `2026-05-16`: Treat the fixture as bounded switch dispatch coverage, not as
  a claim about deferred nested child/await-sync branch bodies.
- `2026-05-16`: Keep the fixture in the broader `isf` regression tier, not
  the curated quick/smoke tier.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-SWITCH-FIXTURE-PROMOTION.1` | `prove -l t/1313-isf-switch-fixture-coverage.t t/1103-isf-switch-branch-exits.t t/1205-isf-switch-clause-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t` | `PASS: Files=7, Tests=103` |
| `2026-05-16` | `ISF-SWITCH-FIXTURE-PROMOTION.1` | `git diff --check` | `PASS` |
| `2026-05-16` | `ISF-SWITCH-FIXTURE-PROMOTION.1` | `mdbook build docs/book` | `PASS` |
| `2026-05-16` | `ISF-SWITCH-FIXTURE-PROMOTION.1` | `./bin/ci-regression isf --no-book` | `PASS: Files=219, Tests=963` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SWITCH-FIXTURE-PROMOTION.1` | `ISF-SWITCH-FIXTURE-PROMOTION.1: promote switch fixture coverage` | `Task-scoped commit subject for this completed leaf.` |

## Changelog

- `2026-05-16`: Created task tree and started the switch fixture promotion
  leaf.
- `2026-05-16`: Added file-backed schedule/report/strict/HDL coverage for
  `isf/switch_test.isf`, synchronized public metadata and docs, and closed the
  task tree.
