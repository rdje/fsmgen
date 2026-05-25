# ISF-DATA-OP-WIDTH-BACKLOG-TRUTH-SYNC: Data-Operation Width Backlog Truth Sync

## Metadata

- Tree ID: `ISF-DATA-OP-WIDTH-BACKLOG-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14 documentation truth sync`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Synchronize the mdBook feature backlog wording for explicit data-operation
width evidence with the already-shipped same-transaction scalar parameter
surface.

## Non-Goals

- Do not change parser behavior, scheduler lowering, generated `.fsm`, HDL,
  schedule-report payloads, or public contract code.
- Do not widen data-operation width inference beyond the existing documented
  same-transaction scalar parameter default support.

## Acceptance Criteria

- The backlog no longer implies that every transaction parameter is
  fail-closed for data-operation width evidence.
- The wording still rejects unrelated or cross-transaction parameters,
  zero-valued transaction parameters, aggregate/list parameters, runtime
  signals, arbitrary expressions, unsupported package constants, and
  activation-site override-specialized data widths.
- Focused book/backlog validation passes, `mdbook build docs/book` passes, and
  the documentation-only leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DATA-OP-WIDTH-BACKLOG-TRUTH-SYNC`
  Status: `done`
  Goal: `Align data-operation width backlog wording with shipped TX_PARAM support.`
  Children: `ISF-DATA-OP-WIDTH-BACKLOG-TRUTH-SYNC.1`

- ID: `ISF-DATA-OP-WIDTH-BACKLOG-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Replace stale broad transaction-parameter fail-closed wording.`
  Acceptance: `Backlog wording matches the shipped same-transaction scalar parameter surface and focused docs validation passes.`
  Verification: `focused backlog/book audits Files=2, Tests=341; mdbook build docs/book; git diff --check`
  Commit: `ISF-DATA-OP-WIDTH-BACKLOG-TRUTH-SYNC.1: sync data width backlog wording`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-DATA-OP-WIDTH-BACKLOG-TRUTH-SYNC.1` synchronized stale data-operation width backlog wording. |

## Decisions

- `2026-05-25`: Treat this as documentation-only truth synchronization
  because the shipped behavior and public contract are already covered by
  existing tests.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-DATA-OP-WIDTH-BACKLOG-TRUTH-SYNC.1` | focused backlog/book audits; `mdbook build docs/book`; `git diff --check` | passed; focused `Files=2, Tests=341` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DATA-OP-WIDTH-BACKLOG-TRUTH-SYNC.1` | `ISF-DATA-OP-WIDTH-BACKLOG-TRUTH-SYNC.1: sync data width backlog wording` | task-scoped commit subject |

## Changelog

- `2026-05-25`: Created and activated task tree.
- `2026-05-25`: Synchronized data-operation width backlog wording; closed
  the tree.
