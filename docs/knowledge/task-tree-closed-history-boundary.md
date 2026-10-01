---
id: task-tree-closed-history-boundary
title: Closed task-history suffixes require a committed legal heading
answers:
  - "how is a closed task acceptance-history boundary selected?"
  - "why must the semantic history boundary commit before rollover?"
date: 2026-10-01
status: current
tags: [task-tree, doctrine, continuity, history]
evidence: docs/TASK_TREE.md; scripts/check_task_tree_integrity.pl; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/check_task_tree_integrity.pl
---

The acceptance-history manifest authenticates an exact committed predecessor
and a suffix beginning at a unique named level-two heading. Its unchanged
closed heading contract forbids empty headings, newlines and backticks.

The former semantic `Decisions` boundary was retired under `.54`; the next
closed acceptance heading contains backticks. `.64.1` therefore inserts one
legal `Completed Acceptance History` heading before the closed body and
commits it without deleting history or altering the manifest. `.64.2` must
consume that exact committed source before retirement. Current node contracts
and native/feature limits remain ahead of the boundary. Complete source and
suffix products overlap and are authenticated separately; neither represents
discarded bytes. Existing Git retention preserves prior history chains.
