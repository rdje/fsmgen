# ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION: Generated Composition Fixture Promotion

## Metadata

- Tree ID: `ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Promote the checked-in spawned-child generated-composition ISF fixture to
file-backed strict schedule JSON, strict `--outdir`, scheduled `.fsm`, and
top/parent/child HDL reachability coverage.

## Non-Goals

- Widening generated-composition syntax or spawn semantics.
- Changing generated top wiring, parameter binding, or child-module naming.
- Adding the fixture to the quick/smoke tier.
- Snapshotting full generated HDL or full schedule JSON.

## Acceptance Criteria

- The fixture covers generated top emission, parent/child scheduled `.fsm`
  artifacts, start/done handoffs, named-drive request/payload handoffs, public
  input fanout, `await_all` synchronization, and generated top HDL wiring.
- A file-backed regression proves in-process lowering, strict schedule JSON
  parity, strict `--outdir` file emission, and strict HDL generation for the
  generated top, parent, and child scheduled `.fsm` artifacts.
- Public `tested_by` metadata, the ISF spec, downstream handoff, public
  contract, mdBook, fixture matrix, live docs, README, roadmap board, and task
  tree stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION`
  Status: `done`
  Goal: `Promote the generated-composition fixture to file-backed strict/outdir/HDL coverage.`
  Children: `ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.1`

- ID: `ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.1`
  Status: `done`
  Goal: `Add schedule/report/strict-outdir/HDL regression coverage for the generated-composition fixture.`
  Acceptance: `The new regression proves in-process and CLI behavior, public metadata/docs are synchronized, and focused plus ISF regression gates pass.`
  Verification: `prove -l t/1315-isf-generated-composition-fixture-coverage.t t/1122-isf-public-cli-outdir-lowering-audit.t t/1128-isf-public-multifile-schedule-report-audit.t t/1216-isf-generated-composition-top.t t/1217-isf-generated-composition-schedule-report.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`
  Commit: `ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.1: promote generated composition fixture coverage`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The generated-composition fixture now has file-backed strict/outdir/HDL coverage. |

## Decisions

- `2026-05-16`: Treat `isf/spawn_parent.isf` as a bounded generated-child
  composition contract fixture, not as a realistic external protocol claim.
- `2026-05-16`: Keep the fixture in the broader `isf` regression tier, not
  the curated quick/smoke tier.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.1` | `prove -l t/1315-isf-generated-composition-fixture-coverage.t t/1122-isf-public-cli-outdir-lowering-audit.t t/1128-isf-public-multifile-schedule-report-audit.t t/1216-isf-generated-composition-top.t t/1217-isf-generated-composition-schedule-report.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t` | `PASS: Files=9, Tests=105` |
| `2026-05-16` | `ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.1` | `./bin/ci-regression isf --no-book` | `PASS: Files=221, Tests=971` |
| `2026-05-16` | `ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.1` | `mdbook build docs/book` | `PASS` |
| `2026-05-16` | `ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.1` | `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.1` | `ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.1: promote generated composition fixture coverage` | `Task-scoped commit subject for this completed leaf.` |

## Changelog

- `2026-05-16`: Created task tree and started the generated-composition fixture
  promotion leaf.
- `2026-05-16`: Added file-backed strict schedule/report/outdir/HDL coverage
  for `isf/spawn_parent.isf`, synchronized public metadata and docs, and
  closed the task tree.
