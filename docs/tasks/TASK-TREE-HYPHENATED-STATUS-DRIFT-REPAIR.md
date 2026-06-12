# TASK-TREE-HYPHENATED-STATUS-DRIFT-REPAIR: Hyphenated Status Drift Repair

## Metadata

- Tree ID: `TASK-TREE-HYPHENATED-STATUS-DRIFT-REPAIR`
- Status: `done`
- Roadmap lane: `infra/continuity`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Normalize the remaining historical hyphenated `in-progress` task-tree status
marker that contradicts the canonical task index and can mislead future PNT
or resume scans.

## Non-Goals

- Do not reopen completed feature work.
- Do not alter code, tests, generated sources, public behavior, or mdBook
  user-facing behavior.
- Do not rewrite earlier commits.

## Acceptance Criteria

- `docs/tasks/ISF-TRIGGER-ANCHOR.md` top metadata status agrees with the
  canonical `docs/TASK_TREE.md` row (`done`).
- A non-template task-file scan fails to find `active`, `proposed`, `pending`,
  `in_progress`, or `in-progress` status markers after this repair closes.
- The Knowledge Map fact for stale task-tree status drift includes the
  hyphenated `in-progress` spelling in its recovery check.
- `docs/TASK_TREE.md` and `MEMORY.md` return to exhausted PNT state.
- `scripts/check_memory_architecture.sh`, `bash knowledge-map/scripts/check_knowledge_map.sh`,
  and `git diff --check` pass.
- The slice is committed through `COMMIT.md`.

## Task Tree

- ID: `TASK-TREE-HYPHENATED-STATUS-DRIFT-REPAIR`
  Status: `done`
  Goal: `Normalize the remaining hyphenated stale status marker in completed task metadata.`
  Children: `TASK-TREE-HYPHENATED-STATUS-DRIFT-REPAIR.1`

- ID: `TASK-TREE-HYPHENATED-STATUS-DRIFT-REPAIR.1`
  Status: `done`
  Goal: `Repair the stale ISF-TRIGGER-ANCHOR top metadata status and harden the status-drift fact check.`
  Acceptance: `No non-template task file exposes an active/proposed/pending/in-progress status marker after the repair closes.`
  Verification: `perl tightened status scan over docs/tasks/*.md; bash knowledge-map/scripts/check_knowledge_map.sh; scripts/check_memory_architecture.sh; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-TRIGGER-ANCHOR` metadata now matches the canonical done row and the status-drift recheck catches both underscore and hyphen spellings. |

## Decisions

- `2026-06-12`: Treat the stale `ISF-TRIGGER-ANCHOR` metadata status as
  continuity drift. The canonical task index already marks the tree complete,
  and no feature behavior is being reopened.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `TASK-TREE-HYPHENATED-STATUS-DRIFT-REPAIR.1` | `perl tightened status scan over docs/tasks/*.md excluding template/current owner` | `pass; no active/proposed/pending/in-progress markers outside the repair owner` |
| `2026-06-12` | `TASK-TREE-HYPHENATED-STATUS-DRIFT-REPAIR.1` | `bash knowledge-map/scripts/check_knowledge_map.sh; scripts/check_memory_architecture.sh; prove -Iperl t/1414-docs-relative-paths-audit.t; git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `TASK-TREE-HYPHENATED-STATUS-DRIFT-REPAIR.1` | `pending` | `hyphenated status drift repair complete; commit pending` |

## Changelog

- `2026-06-12`: Created task tree and began the hyphenated status drift repair.
- `2026-06-12`: Normalized `ISF-TRIGGER-ANCHOR` metadata and hardened the stale
  status fact recheck.
