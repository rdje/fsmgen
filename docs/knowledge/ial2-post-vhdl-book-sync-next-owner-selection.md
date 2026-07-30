---
id: ial2-post-vhdl-book-sync-next-owner-selection
title: Frozen-legacy task-tree workflow sync follows the VHDL book repair
answers:
  - "what follows the mdBook VHDL introduction boundary sync?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.834 select?"
  - "why is the frozen legacy workflow sync selected next?"
  - "do task-tree instructions still tell agents to update frozen blobs?"
  - "does selecting workflow sync activate HIAL or VIAL?"
date: 2026-07-30
status: current
tags: [ial2, selector, task-tree, workflow, memory, frozen-legacy, documentation]
evidence: docs/IAL2_POST_VHDL_BOOK_SYNC_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC.md; docs/TASK_TREE.md; docs/TASK_TREE_README.md; docs/tasks/TEMPLATE.md; docs/decisions/0007-memory-architecture-supersedes-blob-narration.md; docs/decisions/0019-task-tree-in-file-secondary-views-are-historical.md; COMMIT.md
reverify: rg -n 'CHANGES.md|DEVELOPMENT_NOTES.md|ROADMAP_STATUS.md|LIVE_ACHIEVEMENT_STATUS.md' docs/TASK_TREE.md docs/TASK_TREE_README.md docs/tasks/TEMPLATE.md
---

Parent selector `.834` selects proposed no-behavior
`TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC.1` after the VHDL book boundary is
aligned.

Current task-tree guidance still tells maintainers to update or treat as
canonical the four decision-`0007`-frozen legacy blobs. The authoritative
`COMMIT.md`, bootstrap instructions, and current practice correctly route live
state through task trees, decisions, bounded `MEMORY.md`, the mdBook, and git.
The selected leaf repairs that tracked guidance while preserving decision
`0019`'s node-list/frontier rule and changing no product behavior.

HIAL/VIAL, end-to-end scale, import-tree refresh, public-test drift, other
protocol/backend and simulator work, and all director-gated owners remain
independent.

Clean selector commit `dc055558c` activates only the selected workflow leaf
through continuity changes. The stale guidance, all four frozen blobs, and
every product behavior remain unchanged during activation.
