# ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC: Report Metadata Matrix Coverage

## Metadata

- Tree ID: `ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Expand the ISF shipped feature matrix so report-only actor metadata, actor
parameter defaults, schedule JSON schema-version stability, and public storage
role/value-family metadata are explicit book-facing rows.

## Non-Goals

- Do not change parser, scheduler, emitter, schedule-report payload, generated
  `.fsm`, generated HDL, public contract code, or manifest behavior.
- Do not mark actor-level phase/stage metadata as runtime scheduling behavior.
- Do not expose raw parser actor hashes, private lowering internals, or raw
  assignment provenance as downstream report API.

## Acceptance Criteria

- The ISF shipped feature matrix has explicit rows for actor report metadata
  and schedule-report schema/storage-role metadata.
- The matrix has a representative schedule JSON metadata example.
- The matrix keeps actor-level phase/stage runtime semantics and raw internals
  as explicit non-claims.
- The matrix audit is updated to require those rows, example markers, and
  non-claims.
- Live docs and roadmap/task-tree state are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC`
  Status: `done`
  Goal: `Add explicit schedule-report metadata coverage to the ISF feature matrix.`
  Children: `ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC.1`

- ID: `ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC.1`
  Status: `done`
  Goal: `Synchronize feature-matrix coverage for report-only actor metadata and schedule JSON public metadata.`
  Acceptance: `The matrix and audit explicitly cover actor params/phases/stages,
  schema_version, storage role families, and report-metadata non-claims.`
  Verification: `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`;
  `prove -Iperl t/1305-isf-book-feature-matrix-audit.t
  t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`;
  `./bin/ci-regression isf --no-book`
  (`Files=213, Tests=914`); `git diff --check`
  Commit: `ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC.1: cover report metadata`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC.1` | `done` | The book feature matrix should make report-only actor metadata and schedule-report public metadata explicit rather than leaving them implied by the broad schedule-report row. |

## Decisions

- `2026-05-16`: This is a matrix coverage sync, not a schedule-report payload
  change.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC.1` | `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `PASS`; broad ISF gate: `Files=213, Tests=914` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC.1` | `ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC.1: cover report metadata` | Closed the report metadata matrix coverage sync. |

## Changelog

- `2026-05-16`: Created active R14 documentation-coverage task tree for ISF
  shipped feature matrix schedule-report metadata coverage.
- `2026-05-16`: Completed the matrix rows, schedule JSON example, non-claims,
  audit, mdBook build, and broad ISF regression evidence for report metadata
  coverage.
