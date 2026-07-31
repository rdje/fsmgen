---
id: task-tree-in-file-secondary-views-are-historical
title: Task-tree in-file secondary views are historical; the node list is the live source
answers:
  - "are the ## Current Frontier / ## Commit Log / ## Verification Log / ## Changelog sections in a task-tree file authoritative?"
  - "where is the live frontier of a task tree?"
  - "does a slice have to update the ## Current Frontier table?"
  - "how does PNT select the next leaf?"
  - "why is the ## Current Frontier table in IAL2-FEATURE-COMPLETENESS-FRONTIER.md stale?"
  - "how can I retrieve the former completed task-tree index?"
date: 2026-07-12
status: current
tags: [task-tree, continuity, convention, frontier, pnt, decision-0019]
evidence: docs/decisions/0019-task-tree-in-file-secondary-views-are-historical.md; docs/decisions/0042-task-trees-seal-completed-subtrees-with-exact-provenance.md; docs/TASK_TREE.md; docs/tasks/TEMPLATE.md; docs/tasks/TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: rg -n 'node list|sealed segments|optional historical|decision 0019|0042' docs/TASK_TREE.md docs/tasks/TEMPLATE.md docs/decisions/0019-task-tree-in-file-secondary-views-are-historical.md docs/decisions/0042-task-trees-seal-completed-subtrees-with-exact-provenance.md
---

Per decision `0019`, the **authoritative live sources** for a task tree's
frontier, verification, and history are the `## Task Tree` **node list** (each
leaf's `Status`/`Verification`/`Commit`), `docs/TASK_TREE.md`, and
`git log --grep=<TREE-ID>`.

Decision `0042` refines only the storage topology for long-running trees: the
authoritative node graph may be the checked union of the live node list and
manifest-addressed exact-source sealed segments. Every nonterminal frontier
node and ancestor remains live, so PNT selection is unchanged.

The four in-file secondary views — `## Current Frontier`, `## Verification Log`,
`## Commit Log`, and `## Changelog` — are **optional historical convenience
snapshots**. They are **not required to be maintained per-slice**, a slice is
complete without touching them, and when present they may lag (in
`IAL2-FEATURE-COMPLETENESS-FRONTIER.md` they had drifted 6–10 slices behind while
the node list stayed current). Existing stale views are stamped historical, not
backfilled. The oversized IAL2 secondary views now live only in exact version
object `44b5f159789ba1c31b487c6b047097bb27a9770d:docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`;
its 844 authoritative child nodes are separately sealed and reconstructed.
Completed task-tree files are not swept (their views remain accurate finished
snapshots).

PNT selects the earliest `active`/`pending`, unblocked leaf from the **node
list**, not from the `## Current Frontier` table (`docs/TASK_TREE.md` PNT
Selection Rules step 3). This matches practice: PNT continued correctly while the
`## Current Frontier` table was stale.

The cross-tree index follows the same principle after `.7`: only active and
proposed rows remain live. Its former 540 unique done/deferred rows are
digest-proved at the same exact revision through
`doctrine/task_tree/index_archives.jsonl`; the task files themselves remain at
their stable repository paths.

Chosen (retire) over a regenerate-and-check approach because the views duplicate
the node list + git and carry nothing unique (the `0007` re-narration
anti-pattern); retiring makes drift structurally impossible with no generator or
doctrine check to maintain. Owner: `TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION`
(`done`).
