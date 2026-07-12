---
id: task-tree-in-file-secondary-views-are-historical
title: Task-tree in-file secondary views are historical; the node list is the live source
answers:
  - "are the ## Current Frontier / ## Commit Log / ## Verification Log / ## Changelog sections in a task-tree file authoritative?"
  - "where is the live frontier of a task tree?"
  - "does a slice have to update the ## Current Frontier table?"
  - "how does PNT select the next leaf?"
  - "why is the ## Current Frontier table in IAL2-FEATURE-COMPLETENESS-FRONTIER.md stale?"
date: 2026-07-12
status: current
tags: [task-tree, continuity, convention, frontier, pnt, decision-0019]
evidence: docs/decisions/0019-task-tree-in-file-secondary-views-are-historical.md; docs/TASK_TREE.md; docs/tasks/TEMPLATE.md; docs/tasks/TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: rg -n 'node list|Historical snapshot|optional historical|decision 0019|0019' docs/TASK_TREE.md docs/tasks/TEMPLATE.md docs/decisions/0019-task-tree-in-file-secondary-views-are-historical.md
---

Per decision `0019`, the **authoritative live sources** for a task tree's
frontier, verification, and history are the `## Task Tree` **node list** (each
leaf's `Status`/`Verification`/`Commit`), `docs/TASK_TREE.md`, and
`git log --grep=<TREE-ID>`.

The four in-file secondary views — `## Current Frontier`, `## Verification Log`,
`## Commit Log`, and `## Changelog` — are **optional historical convenience
snapshots**. They are **not required to be maintained per-slice**, a slice is
complete without touching them, and when present they may lag (in
`IAL2-FEATURE-COMPLETENESS-FRONTIER.md` they had drifted 6–10 slices behind while
the node list stayed current). Existing stale views are stamped historical, not
backfilled; completed task-tree files are not swept (their views are accurate
finished snapshots).

PNT selects the earliest `active`/`pending`, unblocked leaf from the **node
list**, not from the `## Current Frontier` table (`docs/TASK_TREE.md` PNT
Selection Rules step 3). This matches practice: PNT continued correctly while the
`## Current Frontier` table was stale.

Chosen (retire) over a regenerate-and-check approach because the views duplicate
the node list + git and carry nothing unique (the `0007` re-narration
anti-pattern); retiring makes drift structurally impossible with no generator or
doctrine check to maintain. Owner: `TASK-TREE-AUX-VIEW-DRIFT-RESOLUTION`
(`done`).
