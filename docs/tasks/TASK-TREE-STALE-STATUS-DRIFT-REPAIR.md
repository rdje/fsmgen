# TASK-TREE-STALE-STATUS-DRIFT-REPAIR: Stale Task-Tree Status Drift Repair

## Metadata

- Tree ID: `TASK-TREE-STALE-STATUS-DRIFT-REPAIR`
- Status: `done`
- Roadmap lane: `infra/continuity`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Remove stale `active`/`pending` task status markers from completed task-tree
files when those markers contradict `docs/TASK_TREE.md` and can mislead resume
or PNT selection.

## Non-Goals

- Do not reopen completed feature work.
- Do not alter code, tests, generated sources, or public behavior.
- Do not rewrite historical commit evidence beyond the minimum status
  correction needed to keep task-tree recovery unambiguous.

## Acceptance Criteria

- Every non-template `docs/tasks/*.md` file agrees with the canonical task index:
  no completed/exhausted tree still exposes `active`, `in_progress`, `proposed`,
  or PNT-eligible `pending` status markers.
- `docs/TASK_TREE.md` records this repair slice while it is active and then marks
  it complete.
- `MEMORY.md` points at this work while in flight and returns to an exhausted
  PNT pointer after completion.
- A knowledge fact captures the recovered invariant so future sessions do not
  re-derive the audit from scratch.
- `scripts/check_memory_architecture.sh`, `bash knowledge-map/scripts/check_knowledge_map.sh`,
  and `git diff --check` pass.
- The slice is committed through `COMMIT.md`.

## Task Tree

- ID: `TASK-TREE-STALE-STATUS-DRIFT-REPAIR`
  Status: `done`
  Goal: `Normalize stale task-tree status markers that contradict the exhausted PNT frontier.`
  Children: `TASK-TREE-STALE-STATUS-DRIFT-REPAIR.1`

- ID: `TASK-TREE-STALE-STATUS-DRIFT-REPAIR.1`
  Status: `done`
  Goal: `Audit and correct stale active/pending/proposed markers in completed task trees.`
  Acceptance: `Only intended task-tree drift markers are normalized; canonical index and MEMORY align with exhausted PNT state.`
  Verification: `perl stale-status scan over docs/tasks/*.md excluding the template/current repair owner; bash knowledge-map/scripts/check_knowledge_map.sh; scripts/check_memory_architecture.sh; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Stale status markers in completed task files were normalized; the canonical index still records no proposed tree and exhausted PNT. |

## Decisions

- `2026-06-12`: Treat stale `active`/`pending` markers inside completed task
  files as continuity drift rather than new feature work. The canonical task
  index says no proposed task tree is queued and active PNT is exhausted, so the
  repair must preserve that state instead of selecting old backlog implicitly.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `TASK-TREE-STALE-STATUS-DRIFT-REPAIR.1` | `perl stale-status scan over docs/tasks/*.md excluding the template/current repair owner` | `pass; no stale active/proposed/in_progress/pending status markers remain outside the repair owner` |
| `2026-06-12` | `TASK-TREE-STALE-STATUS-DRIFT-REPAIR.1` | `bash knowledge-map/scripts/check_knowledge_map.sh; scripts/check_memory_architecture.sh; prove -Iperl t/1414-docs-relative-paths-audit.t; git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `TASK-TREE-STALE-STATUS-DRIFT-REPAIR.1` | `pending` | `status drift repair complete; commit pending` |

## Changelog

- `2026-06-12`: Created task tree and began the stale status drift repair slice.
- `2026-06-12`: Normalized stale status markers in completed task trees and added
  the Knowledge Map fact for future recovery.
