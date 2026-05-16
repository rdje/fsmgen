# ISF-I2C-FIXTURE-PROMOTION: I2C Fixture Promotion

## Metadata

- Tree ID: `ISF-I2C-FIXTURE-PROMOTION`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Promote the I2C-like ISF fixture from focused repeat/data-op smoke coverage to
file-backed schedule JSON, strict-mode, and HDL reachability coverage.

## Non-Goals

- Claiming complete I2C protocol compliance.
- Adding the fixture to the quick/smoke tier.
- Snapshotting full generated HDL or full schedule JSON.
- Widening ISF syntax or scheduler semantics.

## Acceptance Criteria

- The fixture drives write-data SDA from documented sampled-byte bit selection
  instead of relying on an implicit undeclared `data_bit` input.
- The fixture still covers nested repeats, switch branches, parameterized
  drives, shift-left data movement, and sampled aliases.
- A file-backed regression proves scheduled `.fsm` structure, schedule-report
  metadata, strict schedule JSON parity, and plain plus strict HDL generation.
- Public `tested_by` metadata, the ISF spec, downstream handoff, public
  contract, mdBook, live docs, README, roadmap board, and task tree stay
  synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-I2C-FIXTURE-PROMOTION`
  Status: `done`
  Goal: `Promote the I2C-like fixture to file-backed schedule/strict/HDL coverage.`
  Children: `ISF-I2C-FIXTURE-PROMOTION.1`

- ID: `ISF-I2C-FIXTURE-PROMOTION.1`
  Status: `done`
  Goal: `Refresh the I2C fixture write-data path and add schedule/strict/HDL regression coverage.`
  Acceptance: `The fixture avoids implicit undeclared write-data inputs, the new regression proves in-process and CLI behavior, public metadata/docs are synchronized, and focused plus ISF regression gates pass.`
  Verification: `prove -l t/1309-isf-i2c-fixture-coverage.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `git diff --check`; `./bin/ci-regression isf --no-book`
  Commit: `ISF-I2C-FIXTURE-PROMOTION.1: promote I2C fixture coverage`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-I2C-FIXTURE-PROMOTION.1` | `done` | Shipped in this tree; no remaining frontier. |

## Decisions

- `2026-05-16`: Treat this as a bounded I2C-like fixture promotion, not a
  complete external protocol compliance claim.
- `2026-05-16`: Keep the fixture in the broader `isf` regression tier, not the
  curated quick/smoke tier.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-I2C-FIXTURE-PROMOTION.1` | `prove -l t/1309-isf-i2c-fixture-coverage.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t` | `PASS: Files=5, Tests=92` |
| `2026-05-16` | `ISF-I2C-FIXTURE-PROMOTION.1` | `git diff --check` | `PASS` |
| `2026-05-16` | `ISF-I2C-FIXTURE-PROMOTION.1` | `./bin/ci-regression isf --no-book` | `PASS: Files=215, Tests=947` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-I2C-FIXTURE-PROMOTION.1` | `ISF-I2C-FIXTURE-PROMOTION.1: promote I2C fixture coverage` | `Task-scoped commit subject for this completed leaf.` |

## Changelog

- `2026-05-16`: Created task tree and started the I2C fixture promotion leaf.
- `2026-05-16`: Shipped the I2C-like fixture promotion, including sampled
  `data[7]` write-data drive selection, write-data shifting, strict
  schedule/HDL coverage, public metadata updates, spec/book/downstream/
  public-contract synchronization, and focused plus broad validation.
