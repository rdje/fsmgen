# ISF-PHASE-FIXTURE-PROMOTION: Phase Fixture Promotion

## Metadata

- Tree ID: `ISF-PHASE-FIXTURE-PROMOTION`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Promote the checked-in phase metadata ISF fixture to file-backed schedule JSON,
scheduled `.fsm`, strict-mode, and HDL reachability coverage.

## Non-Goals

- Adding executable actor-level phase semantics.
- Widening transaction `(phase ...)` beyond the current pass-through state
  marker.
- Widening transaction `(stage ...)` semantics.
- Treating phase metadata as a protocol-compliance fixture.
- Adding the fixture to the quick/smoke tier.

## Acceptance Criteria

- The fixture no longer mixes reusable drive assignments with completion-pulse
  assignments on the same output.
- The fixture continues to cover transaction phase pass-through states,
  parser-validated phase body metadata, completion pulse behavior, and strict
  HDL reachability.
- A file-backed regression proves scheduled `.fsm` structure, schedule-report
  metadata, strict schedule JSON parity, and plain plus strict HDL generation.
- Public `tested_by` metadata, the ISF spec, downstream handoff, public
  contract, mdBook, fixture matrix, live docs, README, roadmap board, and task
  tree stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-PHASE-FIXTURE-PROMOTION`
  Status: `done`
  Goal: `Promote the phase metadata fixture to file-backed schedule/strict/HDL coverage.`
  Children: `ISF-PHASE-FIXTURE-PROMOTION.1`

- ID: `ISF-PHASE-FIXTURE-PROMOTION.1`
  Status: `done`
  Goal: `Refresh the phase fixture and add schedule/report/strict/HDL regression coverage.`
  Acceptance: `The fixture avoids mixed assignment families on done, the new regression proves in-process and CLI behavior, public metadata/docs are synchronized, and focused plus ISF regression gates pass.`
  Verification: `prove -l t/1312-isf-phase-fixture-coverage.t t/1179-isf-phase-stage-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `git diff --check`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`
  Commit: `ISF-PHASE-FIXTURE-PROMOTION.1: promote phase fixture coverage`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The phase fixture now avoids mixed `done` assignment families and has file-backed schedule/report/strict/HDL coverage. |

## Decisions

- `2026-05-16`: Treat the fixture as phase-metadata/pass-through coverage,
  not executable actor-level phase scheduling.
- `2026-05-16`: Keep the fixture in the broader `isf` regression tier, not
  the curated quick/smoke tier.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-PHASE-FIXTURE-PROMOTION.1` | `prove -l t/1312-isf-phase-fixture-coverage.t t/1179-isf-phase-stage-boundary.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t` | `PASS: Files=6, Tests=99` |
| `2026-05-16` | `ISF-PHASE-FIXTURE-PROMOTION.1` | `git diff --check` | `PASS` |
| `2026-05-16` | `ISF-PHASE-FIXTURE-PROMOTION.1` | `mdbook build docs/book` | `PASS` |
| `2026-05-16` | `ISF-PHASE-FIXTURE-PROMOTION.1` | `./bin/ci-regression isf --no-book` | `PASS: Files=218, Tests=959` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-PHASE-FIXTURE-PROMOTION.1` | `ISF-PHASE-FIXTURE-PROMOTION.1: promote phase fixture coverage` | `Task-scoped commit subject for this completed leaf.` |

## Changelog

- `2026-05-16`: Created task tree and started the phase fixture promotion
  leaf.
- `2026-05-16`: Removed the unused reusable `done` drive from
  `isf/phase_test.isf`, added file-backed schedule/report/strict/HDL
  coverage, synchronized public metadata and docs, and closed the task tree.
