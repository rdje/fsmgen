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
reverify: rg -n '0047|DEVELOPMENT_NOTES|ROADMAP_STATUS|LIVE_ACHIEVEMENT_STATUS' docs/TASK_TREE.md docs/TASK_TREE_README.md docs/tasks/TEMPLATE.md COMMIT.md
---

Parent selector `.834` selects proposed no-behavior
`TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC.1` after the VHDL book boundary is
aligned.

The selected leaf is complete: task-tree guidance no longer tells maintainers
to update or treat as canonical the four decision-`0007`-frozen legacy blobs.
It now routes live state through task trees, decisions, bounded `MEMORY.md`,
the mdBook, and git while preserving decision `0019`'s node-list/frontier rule
and changing no product behavior. The template's decision-`0019` comments were
already correct; only its stale acceptance phrase required repair.

HIAL/VIAL, end-to-end scale, import-tree refresh, public-test drift, other
protocol/backend and simulator work, and all director-gated owners remain
independent.

Clean selector commit `dc055558c` activates only the selected workflow leaf
through continuity changes. The stale guidance, all four frozen blobs, and
every product behavior remain unchanged during activation.

The workflow leaf subsequently completes through clean commit `771d2918c`
without modifying any frozen blob. That clean completion activates parent
selector `.835` continuity-only; it does not select or modify the next child.
Decision `0047` later retires the former changelog path and obligation; the
remaining rationale/status lifecycle boundaries stay separately owned.
