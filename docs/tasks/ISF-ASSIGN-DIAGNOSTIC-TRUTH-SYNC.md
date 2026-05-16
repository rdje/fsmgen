# ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC: Removed Assign Diagnostic Truth Sync

## Metadata

- Tree ID: `ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Synchronize the public R14 documentation for the removed transaction
`(assign ...)` keyword with the already-shipped targeted migration diagnostic
and regression coverage.

## Non-Goals

- Do not change parser, scheduler, report, generated `.fsm`, or HDL behavior.
- Do not reintroduce `(assign ...)` as accepted ISF syntax.
- Do not specify a new transaction-local combinational assignment construct.

## Acceptance Criteria

- The canonical mdBook feature backlog no longer says the removed
  `(assign ...)` targeted diagnostic is pending.
- The downstream handoff and live docs stay explicit that `(assign ...)`
  remains fail-closed, with migration guidance to existing timing constructs.
- Existing focused regression coverage for the diagnostic remains passing.
- Live docs and roadmap/task-tree status are updated.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC`
  Status: `done`
  Goal: `Synchronize removed-assign diagnostic truth across public docs`
  Children: `ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC.1`

- ID: `ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Correct stale removed-assign diagnostic backlog wording`
  Acceptance: `Book backlog and handoff describe the shipped fail-closed targeted diagnostic and focused regression evidence still passes`
  Verification: `prove -Iperl t/1180-isf-unsupported-transaction-clause-boundary.t`; `mdbook build docs/book`
  Commit: `ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC.1: sync assign diagnostic truth`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `_None_` | `_None_` | Tree closed |

## Decisions

- `2026-05-16`: Treat this as documentation-truth synchronization, not a code
  feature, because `LoweringIR` already emits the migration-specific diagnostic
  and `t/1180-isf-unsupported-transaction-clause-boundary.t` already covers
  top-level, `when`, `switch`, and `repeat` contexts.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC.1` | `prove -Iperl t/1180-isf-unsupported-transaction-clause-boundary.t`; `mdbook build docs/book` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC.1` | `ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC.1: sync assign diagnostic truth` | `pending commit` |

## Changelog

- `2026-05-16`: Created task tree for removed-assign diagnostic truth sync.
- `2026-05-16`: Closed tree after synchronizing public docs with existing
  lowerer behavior and focused regression evidence.
