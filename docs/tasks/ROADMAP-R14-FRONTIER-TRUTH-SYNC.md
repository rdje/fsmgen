# ROADMAP-R14-FRONTIER-TRUTH-SYNC: R14 Frontier Truth Synchronization

## Metadata

- Tree ID: `ROADMAP-R14-FRONTIER-TRUTH-SYNC`
- Status: `closed`
- Roadmap lane: `roadmap maintenance`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Remove stale R14 roadmap text that still names a completed task leaf as the
current PNT frontier after `ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.2` closed.

## Non-Goals

- Do not change compiler behavior.
- Do not select the next behavior-bearing ISF feature in this tree.
- Do not widen or reclassify any mdBook feature support boundary.

## Acceptance Criteria

- The top roadmap snapshot and lower R14 `Left` section agree that no task
  tree is active after the ATL multi-route task closure.
- `docs/TASK_TREE.md` lists this maintenance tree with completion evidence.
- Live recovery docs record that the change is documentation-only.
- Focused documentation checks pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ROADMAP-R14-FRONTIER-TRUTH-SYNC`
  Status: `done`
  Goal: `synchronize stale R14 frontier status after ATL multi-route closure`
  Children: `ROADMAP-R14-FRONTIER-TRUTH-SYNC.1`

- ID: `ROADMAP-R14-FRONTIER-TRUTH-SYNC.1`
  Status: `done`
  Goal: `remove the stale completed-leaf frontier wording from R14 live status`
  Acceptance: `roadmap, task-tree index, and live docs agree that no tree is active before the next PNT selection`
  Verification: `git diff --check; mdbook build docs/book`
  Commit: `e00d5d82 ROADMAP-R14-FRONTIER-TRUTH-SYNC.1: sync R14 frontier status after ATL multi-route`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The stale R14 frontier wording is removed. |

## Decisions

- `2026-05-22`: Treated this as roadmap maintenance because it changes only
  live status truth after a completed feature tree. The next behavior-bearing
  PNT still has to create or activate its own task tree before code changes.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ROADMAP-R14-FRONTIER-TRUTH-SYNC.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ROADMAP-R14-FRONTIER-TRUTH-SYNC.1` | `e00d5d82 ROADMAP-R14-FRONTIER-TRUTH-SYNC.1: sync R14 frontier status after ATL multi-route` | Documentation-only maintenance commit. |

## Changelog

- `2026-05-22`: Removed stale R14 frontier wording that still named the
  completed ATL multi-route implementation leaf as current.
