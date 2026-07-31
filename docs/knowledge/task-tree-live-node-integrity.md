---
id: task-tree-live-node-integrity
title: Active task-tree live-node structure is mechanically enforced
answers:
  - "how is active task-tree node integrity checked?"
  - "what does TASK-TREE-INTEGRITY enforce?"
  - "which live IAL2 task-ledger defects did .843 repair?"
  - "why is IAL2-FEATURE-COMPLETENESS-FRONTIER.705 done now?"
  - "which commit field was missing from the IAL2 task tree?"
  - "does TASK-TREE-INTEGRITY validate sealed task-tree segments?"
date: 2026-07-31
status: current
tags: [task-tree, doctrine, continuity, integrity, ial2]
evidence: docs/TASK_TREE_LIVE_NODE_INTEGRITY.md; scripts/check_task_tree_integrity.pl; t/1549-task-tree-integrity-doctrine.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; DOCTRINE_ENFORCEMENT.md; docs/decisions/0042-task-trees-seal-completed-subtrees-with-exact-provenance.md
reverify: scripts/check_task_tree_integrity.pl && prove -Iperl t/1549-task-tree-integrity-doctrine.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.843` repairs the active ledger and
registers `TASK-TREE-INTEGRITY`. The check validates active indexed roots,
unique canonical nodes, ancestry, exact direct-child enumeration, status
vocabulary and container state, and complete leaf evidence fields. It ignores
decision-`0019` historical convenience views. Decision `0042` extends the
same checked graph across optional bounded JSONL manifests and content-
addressed exact-source terminal segments; compact completed terminals must
retrieve and validate their complete exact version-object subtree. Existing
one-file trees remain valid.

The repair restores missing root child `.633`, normalizes `.73` from
`completed` to `done`, marks historical/resolved blocker `.705` live `done`,
and restores `.758`'s canonical commit field. Proposed `.844` is the next
selector. No product behavior changes.

Clean implementation commit `c21765214` activates only `.844` through a
separate continuity transition; it does not perform candidate selection.

Completed `.844` selects proposed HIAL/VIAL architecture audit `.1`, which
remains inactive until separate clean activation.
