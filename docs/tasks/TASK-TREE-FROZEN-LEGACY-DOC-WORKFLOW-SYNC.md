# TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC: Remove Frozen-Blob Write Instructions

## Metadata

- Tree ID: `TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC`
- Status: `proposed`
- Roadmap lane: `infra/continuity / task-tree doctrine alignment`
- Created: `2026-07-29`
- Last updated: `2026-07-29`
- Owner: repo-local workflow

## Goal

Synchronize the task-tree workflow documentation with decision `0007` and
`COMMIT.md` so it no longer instructs maintainers to update frozen legacy
blobs.

## Non-Goals

- Do not edit the frozen blobs themselves.
- Do not change the task-tree node/frontier source-of-truth rule in decision
  `0019`.

## Acceptance Criteria

- `docs/TASK_TREE.md`, `docs/TASK_TREE_README.md`, and
  `docs/tasks/TEMPLATE.md` consistently route live state to task-trees,
  decisions, bounded `MEMORY.md`, mdBook, and git.
- No active workflow instruction names `CHANGES.md`,
  `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`, or
  `LIVE_ACHIEVEMENT_STATUS.md` as a required write destination.
- Focused doctrine, memory, docs, and diff gates pass and the leaf is committed
  through `COMMIT.md`.

## Task Tree

- ID: `TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC`
  Status: `proposed`
  Goal: `Align task-tree workflow instructions with the frozen legacy-doc rule.`
  Children: `TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC.1`

- ID: `TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC.1`
  Status: `proposed`
  Goal: `Replace active frozen-blob write instructions with the current layer model.`
  Acceptance: `Task-tree workflow docs agree with decisions 0007/0019 and COMMIT.md without modifying frozen blobs.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-07-29`: Startup review found `docs/TASK_TREE.md` and
  `docs/TASK_TREE_README.md` still describe the four frozen blobs as live write
  destinations. The authoritative `COMMIT.md` and decision `0007` say the
  opposite. The repair is isolated here rather than folded into storage policy.

## Blockers

- Inactive until selected from a clean tree after the current adoption closes.
