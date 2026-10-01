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
  - "is the semantic task tree Current Frontier prose a live resume source?"
  - "is the HIAL task tree Current Frontier prose a live resume source?"
date: 2026-10-01
status: current
tags: [task-tree, continuity, convention, frontier, pnt, decision-0019]
evidence: docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/decisions/0019-task-tree-in-file-secondary-views-are-historical.md; docs/decisions/0042-task-trees-seal-completed-subtrees-with-exact-provenance.md; docs/TASK_TREE.md; docs/tasks/TEMPLATE.md; docs/tasks/TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: (scripts/decision_records.py read 0019 0042 && cat docs/TASK_TREE.md docs/tasks/TEMPLATE.md) | rg -n 'node list|sealed segments|optional historical|decision 0019|0042'
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

SEMANTIC-INTROSPECTION-MCP-FRONTIER.63 retires its unlabelled historical
Current Frontier prose with exact retrieval from
49ef15cba77bdb8572beb079a1a3e81bfa04a85e:docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md.
Its authoritative nodes/index already had the correct statuses. The retirement
adds no second live projection or per-slice maintenance obligation. The live
node list, cross-tree index and bounded Memory pointer remain resume sources.

HIAL's unlabelled Current Frontier snapshot is likewise retired under
.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.10.13. Its complete section is recoverable
from 889d7e1beb7bcec1b214f4209d1cf725cb2f5239:docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md.
The snapshot named completed .11.5; the authoritative nodes were correct.
Independent full-source/section and current-document verification preserves
every other node and adjacent material, with hostile pointer/node/suffix
controls, in docs/audits/hial-frontier-retirement-20261001/. This retirement
adds no live projection or per-slice snapshot maintenance obligation.
