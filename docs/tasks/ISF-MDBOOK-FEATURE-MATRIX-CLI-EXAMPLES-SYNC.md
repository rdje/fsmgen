# ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC: CLI Example Matrix Coverage

## Metadata

- Tree ID: `ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Expand the ISF shipped feature matrix so the shipped `.isf` CLI entrypoints
have book-facing examples for strict mode, schedule JSON, multi-file `--outdir`
lowering, and plain HDL handoff.

## Non-Goals

- Do not change `bin/fsmgen`, parser, scheduler, emitter, schedule-report
  payload, generated `.fsm`, generated HDL, or public manifest behavior.
- Do not add new CLI flags or widen strict-mode behavior.
- Do not duplicate the full CLI reference inside the feature matrix.

## Acceptance Criteria

- The ISF shipped feature matrix has representative `.isf` CLI examples for
  `--strict`, `--emit-schedule-json`, `--outdir`, and plain HDL generation.
- The matrix audit is updated to require those example markers.
- Live docs and roadmap/task-tree state are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC`
  Status: `done`
  Goal: `Add explicit CLI example coverage to the ISF feature matrix.`
  Children: `ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC.1`

- ID: `ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC.1`
  Status: `done`
  Goal: `Synchronize feature-matrix example coverage for shipped .isf CLI paths.`
  Acceptance: `The matrix and audit explicitly cover strict, schedule-json,
  outdir, and HDL-generation CLI markers.`
  Verification: `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`;
  `prove -Iperl t/1305-isf-book-feature-matrix-audit.t
  t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`;
  `./bin/ci-regression isf --no-book`
  (`Files=213, Tests=921`); `git diff --check`
  Commit: `ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC.1: cover CLI examples`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC.1` | `done` | The `.isf` CLI row is shipped, but the support matrix should show the main CLI invocation shapes users can copy. |

## Decisions

- `2026-05-16`: This is a matrix example sync, not a CLI behavior change.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC.1` | `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `PASS`; broad ISF gate: `Files=213, Tests=921` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC.1` | `ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC.1: cover CLI examples` | Closed the CLI example matrix coverage sync. |

## Changelog

- `2026-05-16`: Created active R14 documentation-coverage task tree for ISF
  shipped feature matrix CLI example coverage.
- `2026-05-16`: Completed the matrix CLI examples, audit, mdBook build, and
  broad ISF regression evidence for `.isf` CLI coverage.
