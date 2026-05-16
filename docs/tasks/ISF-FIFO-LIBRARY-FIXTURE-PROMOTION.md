# ISF-FIFO-LIBRARY-FIXTURE-PROMOTION: FIFO Library Fixture Promotion

## Metadata

- Tree ID: `ISF-FIFO-LIBRARY-FIXTURE-PROMOTION`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Promote the checked-in fixed FIFO library-use fixture to file-backed schedule
JSON, generated-top outdir, strict-mode, and HDL reachability coverage.

## Non-Goals

- Changing reusable-library syntax or binding semantics.
- Adding parameter-driven interface/storage elaboration.
- Adding nested library imports or standalone exported transactions/drives.
- Adding the fixture to the quick/smoke tier.
- Snapshotting full generated HDL or full schedule JSON.

## Acceptance Criteria

- `isf/fifo_library_use.isf` is covered as the file-backed fixed FIFO
  library-use fixture.
- A regression proves strict schedule JSON parity, generated top/importer/child
  scheduled `.fsm` artifacts, fixed parameter bindings, interface links, and
  plain plus strict HDL generation.
- Public `tested_by` metadata, the ISF spec, downstream handoff, public
  contract, mdBook, fixture matrix, live docs, README, roadmap board, and task
  tree stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-FIFO-LIBRARY-FIXTURE-PROMOTION`
  Status: `done`
  Goal: `Promote the fixed FIFO library-use fixture to strict schedule/outdir/HDL coverage.`
  Children: `ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.1`

- ID: `ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.1`
  Status: `done`
  Goal: `Add fixture-promotion regression coverage for the fixed FIFO library-use path.`
  Acceptance: `The regression proves in-process and CLI behavior, public metadata/docs are synchronized, and focused plus ISF regression gates pass.`
  Verification: `syntax checks; focused prove; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.1: promote FIFO library fixture coverage`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.1` | `done` | Promoted the checked-in fixed FIFO library-use fixture to the post-closure strict schedule/outdir/HDL coverage used by newer R14 fixtures. |

## Decisions

- `2026-05-16`: Treat this as promotion of the fixed `DATA_WIDTH=8`,
  `DEPTH=4`, `PTR_WIDTH=2`, `OCC_WIDTH=3` FIFO library fixture only.
  Parameter-driven elaboration, nested imports, and standalone transaction or
  drive exports remain deferred.
- `2026-05-16`: Keep the fixture in the broader `isf` regression tier, not
  the curated quick/smoke tier.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.1` | `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1321-isf-fifo-library-fixture-coverage.t`; `perl -Iperl -c t/1144-isf-public-tested-by-metadata-audit.t`; `perl -Iperl -c t/1183-ci-regression-tier-selection.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -l t/1321-isf-fifo-library-fixture-coverage.t t/1237-isf-fifo-library-fixture.t t/1238-isf-fifo-library-hdl-generation.t t/1239-isf-library-catalog-contract.t t/1255-isf-schedule-report-golden-matrix.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t` (`Files=9, Tests=112`); `./bin/ci-regression isf --no-book` (`Files=227, Tests=996`); `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.1` | `ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.1: promote FIFO library fixture coverage` | Promotes the fixed FIFO reusable-library fixture to strict schedule/outdir/HDL coverage. |

## Changelog

- `2026-05-16`: Created task tree and started the FIFO library fixture
  promotion leaf.
- `2026-05-16`: Completed `ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.1` and closed
  the task tree after adding strict schedule JSON, strict `--outdir`, and
  plain/strict generated-top HDL coverage for `isf/fifo_library_use.isf`.
