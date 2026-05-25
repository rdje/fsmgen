# ISF-STATIC-TIMING-FAIL-CLOSED-LIST-TRUTH-SYNC: Timing Checklist Truth Sync

## Metadata

- Tree ID: `ISF-STATIC-TIMING-FAIL-CLOSED-LIST-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14 documentation truth sync`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Synchronize static timing fail-closed checklist wording after the shipped
transaction-parameter repeat, wait, latency, and top-level await-local
watchdog slices, so user-facing docs no longer imply every transaction
parameter remains invalid for watchdog or latency bounds.

## Non-Goals

- Do not change parser, scheduler, generated `.fsm`, HDL, schedule-report,
  public API, or runtime behavior.
- Do not widen transaction-parameter support beyond the already-shipped
  same-transaction timing slots.
- Do not rework historical notes that correctly describe older state at the
  time of earlier slices.

## Acceptance Criteria

- The downstream fail-closed checklist distinguishes shipped same-transaction
  latency and top-level await-local watchdog parameter sources from still
  invalid actor-level, nested control-flow, cross-transaction, zero, and
  non-scalar parameter sources.
- Any mirrored public spec or mdBook wording touched by the stale checklist is
  synchronized.
- Focused documentation/book audits pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-STATIC-TIMING-FAIL-CLOSED-LIST-TRUTH-SYNC`
  Status: `done`
  Goal: `Synchronize static timing fail-closed checklist wording`
  Children: `ISF-STATIC-TIMING-FAIL-CLOSED-LIST-TRUTH-SYNC.1`

- ID: `ISF-STATIC-TIMING-FAIL-CLOSED-LIST-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Update stale watchdog and latency transaction-parameter checklist wording`
  Acceptance: `Docs, mdBook, live docs, validation, and commit workflow are complete`
  Verification: `focused spec/book/backlog audits Files=4, Tests=366; mdbook build docs/book; git diff --check`
  Commit: `ISF-STATIC-TIMING-FAIL-CLOSED-LIST-TRUTH-SYNC.1: sync timing checklist docs`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-STATIC-TIMING-FAIL-CLOSED-LIST-TRUTH-SYNC.1` | `done` | The downstream fail-closed checklist now matches shipped transaction-parameter timing slots. |

## Decisions

- `2026-05-25`: Keep this slice documentation-only. The behavior was already
  shipped by the repeat, wait, latency, and top-level await-local watchdog
  transaction-parameter slices.

## Open Questions

- None for this bounded slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-STATIC-TIMING-FAIL-CLOSED-LIST-TRUTH-SYNC.1` | focused spec/book/backlog audits; `mdbook build docs/book`; `git diff --check` | passed; focused `Files=4, Tests=366` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-STATIC-TIMING-FAIL-CLOSED-LIST-TRUTH-SYNC.1` | `ISF-STATIC-TIMING-FAIL-CLOSED-LIST-TRUTH-SYNC.1: sync timing checklist docs` | task-scoped commit subject |

## Changelog

- `2026-05-25`: Created task tree and selected the documentation truth-sync leaf.
- `2026-05-25`: Synchronized stale watchdog and latency transaction-parameter
  fail-closed checklist wording; closed the tree.
