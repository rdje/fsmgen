# ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC: Issue Bundle Matrix Coverage

## Metadata

- Tree ID: `ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Expand the ISF shipped feature matrix so downstream issue-bundle capture has a
book-facing runnable example and audit coverage beside the shipped diagnostics
and issue-reporting row.

## Non-Goals

- Do not change `bin/fsmgen-issue-bundle`, parser, scheduler, emitter,
  schedule-report payload, generated `.fsm`, generated HDL, or public manifest
  behavior.
- Do not require downstream consumers to classify failures as `.fsm`, `.isf`,
  parser, lowering, HDL, or API-specific before reporting.
- Do not duplicate the full issue-reporting protocol inside the feature
  matrix; link-level and example-level coverage is enough here.

## Acceptance Criteria

- The ISF shipped feature matrix has a representative
  `bin/fsmgen-issue-bundle` example.
- The example preserves the format-agnostic bug-reporting promise.
- The matrix audit is updated to require the helper and a concrete option
  marker.
- Live docs and roadmap/task-tree state are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC`
  Status: `done`
  Goal: `Add downstream issue-bundle example coverage to the ISF feature matrix.`
  Children: `ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC.1`

- ID: `ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC.1`
  Status: `done`
  Goal: `Synchronize feature-matrix example coverage for downstream issue bundles.`
  Acceptance: `The matrix and audit explicitly cover fsmgen-issue-bundle
  invocation markers and the format-agnostic reporting boundary.`
  Verification: `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`;
  `prove -Iperl t/1305-isf-book-feature-matrix-audit.t
  t/1303-isf-public-live-book-paths-audit.t
  t/1251-fsmgen-issue-bundle-helper.t`; `mdbook build docs/book`;
  `./bin/ci-regression isf --no-book`
  (`Files=213, Tests=918`); `git diff --check`
  Commit: `ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC.1: cover issue bundles`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC.1` | `done` | The diagnostics/issue-reporting row is shipped, but the support matrix should include the runnable helper invocation downstream users need. |

## Decisions

- `2026-05-16`: This is a matrix example sync, not an issue-bundle helper
  behavior change.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC.1` | `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t t/1251-fsmgen-issue-bundle-helper.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `PASS`; broad ISF gate: `Files=213, Tests=918` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC.1` | `ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC.1: cover issue bundles` | Closed the downstream issue-bundle example matrix coverage sync. |

## Changelog

- `2026-05-16`: Created active R14 documentation-coverage task tree for ISF
  shipped feature matrix downstream issue-bundle example coverage.
- `2026-05-16`: Completed the matrix helper example, audit, mdBook build, and
  broad ISF regression evidence for downstream issue-bundle coverage.
