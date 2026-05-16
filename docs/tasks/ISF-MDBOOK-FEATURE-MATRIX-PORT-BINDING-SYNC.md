# ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC: Port Binding Matrix Coverage

## Metadata

- Tree ID: `ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Expand the ISF shipped feature matrix so transaction ports, activation-site
bindings, actor-pin binding coverage, and `transaction_port_bindings[]`
schedule-report provenance are explicit book-facing rows.

## Non-Goals

- Do not change parser, scheduler, emitter, schedule-report, generated `.fsm`,
  generated HDL, or public manifest behavior.
- Do not widen binding syntax beyond the shipped `do`, `spawn`, and
  rule-trigger input-binding surfaces.
- Do not mark rule-trigger output bindings or snapshot-vs-live binding timing
  selection as shipped.

## Acceptance Criteria

- The ISF shipped feature matrix has an explicit transaction port and
  activation binding row.
- The matrix has a representative transaction port/bind example.
- The matrix keeps rule-trigger output bindings and richer binding timing as
  explicit non-claims.
- The matrix audit is updated to require that row, example, and non-claim.
- Live docs and roadmap/task-tree state are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC`
  Status: `done`
  Goal: `Add explicit transaction port and activation binding coverage to the ISF feature matrix.`
  Children: `ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC.1`

- ID: `ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC.1`
  Status: `done`
  Goal: `Synchronize feature-matrix coverage for transaction ports and bindings.`
  Acceptance: `The matrix and audit explicitly cover transaction ports,
  activation bindings, report provenance, and binding non-claims.`
  Verification: `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`;
  `prove -Iperl t/1305-isf-book-feature-matrix-audit.t
  t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`;
  `./bin/ci-regression isf --no-book`
  (`Files=213, Tests=905`); `git diff --check`
  Commit: `ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC.1: cover port bindings`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC.1` | `done` | Transaction ports and activation bindings are shipped user-visible features and should not be only implied by broader matrix rows. |

## Decisions

- `2026-05-16`: This is a matrix coverage sync, not a port-binding behavior
  change.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC.1` | `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `PASS`; broad ISF gate: `Files=213, Tests=905` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC.1` | `ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC.1: cover port bindings` | Closed the transaction port and activation binding matrix coverage sync. |

## Changelog

- `2026-05-16`: Created active R14 documentation-coverage task tree for the
  ISF shipped feature matrix transaction port/binding row.
- `2026-05-16`: Completed the matrix row, example, non-claim, audit, mdBook
  build, and broad ISF regression evidence for transaction port/binding
  coverage.
