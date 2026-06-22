---
id: ial2-post-counted-group-local-enqueue-next-slice-selection
title: Post counted group-local enqueue selector chooses dynamic same-ID readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.215 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.216?"
  - "what comes after counted group-local same-ID enqueue?"
  - "why is dynamic same-ID ordering the next AXI manager audit?"
  - "is there a cleanup prerequisite after counted admitted guard alignment?"
date: 2026-06-22
status: current
tags: [ial2, axi, manager, same-id, dynamic-id, per-id-queues, feature-completeness]
evidence: docs/AXI_IAL2_MANAGER_POST_COUNTED_GROUP_LOCAL_ENQUEUE_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_BEHAVIOR.md; docs/knowledge/ial2-feature-completeness-next-slice.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.215|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.216|POST_COUNTED_GROUP_LOCAL_ENQUEUE_NEXT_SLICE_SELECTION|dynamic same-ID|per_id_issue_order_queues|counted concrete-ID queue-head' docs/AXI_IAL2_MANAGER_POST_COUNTED_GROUP_LOCAL_ENQUEUE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.215` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.216`, readiness audit for dynamic same-ID
issue-order queues beyond selected counted concrete-ID queue-head groups.

The selector found no immediate cleanup prerequisite after `.214`. The
representative generated queue-head reports now expose counted
request-set-capacity fit guards, concrete-ID group request-assertion scope,
and expected read-data/interleaving/burst residues. The remaining local AXI
same-ID ordering residue is `per_id_issue_order_queues`, while broad dynamic
ID arbitration remains outside the selected counted concrete-ID queue-head
subset.

`.216` is audit-only. It must decide whether the next owner is a dynamic
per-ID queue/scoreboard contract, fail-closed diagnostic/report cleanup,
lower-layer prerequisite, or narrower selector before any parser, generator,
sample, support-accounting, test, validation, generated-artifact, or HDL
behavior changes.
