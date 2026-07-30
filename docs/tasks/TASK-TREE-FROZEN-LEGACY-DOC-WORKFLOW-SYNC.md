# TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC: Remove Frozen-Blob Write Instructions

## Metadata

- Tree ID: `TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC`
- Status: `done`
- Roadmap lane: `infra/continuity / task-tree doctrine alignment`
- Created: `2026-07-29`
- Last updated: `2026-07-30`
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
  Status: `done`
  Goal: `Align task-tree workflow instructions with the frozen legacy-doc rule.`
  Children: `TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC.1`

- ID: `TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC.1`
  Status: `done`
  Goal: `Replace active frozen-blob write instructions with the current layer model.`
  Acceptance: `Task-tree workflow docs agree with decisions 0007/0019 and COMMIT.md without modifying frozen blobs.`
  Verification: `Activated only after clean parent selector commit dc055558c through clean continuity commit 65704ce5a. docs/TASK_TREE.md and docs/TASK_TREE_README.md now route live state through the task index/node lists, decisions, bounded MEMORY.md, the mdBook, and git. The reusable template was audited: its decision-0019 historical-view comments were already correct, and only its stale acceptance phrase required repair. Exact scans leave the four legacy names only in docs/TASK_TREE.md's explicit decision-0007 frozen warning; none remains in the guide or template. Book/status/path truth passes 5 files/329 tests. Knowledge Map generation/check passes at 1,063 facts/5,471 question keys. The mdBook renders exactly 72 files/16,541,296 bytes and its repository-local output is removed. .artifacts/tmp/tests is empty, MEMORY.md is 47 lines, README.md is 2,351 lines, diff hygiene passes, and all doctrine gates pass. Completion-closeout canonical Stats-compatible capacity is 17,093,181,440/25,769,803,776 bytes = 15.919/24.000 GiB = 66.33%, with separate macOS kernel pressure level 1 and memory_pressure 73% free; guard occupancy is excluded from capacity truth. All four frozen blobs, decisions 0007/0019, the node-list/frontier rule, and every product behavior remain unchanged. No background job remains.`
  Commit: `TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC.1: align workflow memory layers`

## Decisions

- `2026-07-29`: Startup review found `docs/TASK_TREE.md` and
  `docs/TASK_TREE_README.md` still describe the four frozen blobs as live write
  destinations. The authoritative `COMMIT.md` and decision `0007` say the
  opposite. The repair is isolated here rather than folded into storage policy.

## Blockers

- None. Tree complete; the next clean action returns to the parent selector.
