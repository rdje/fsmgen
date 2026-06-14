---
id: ial2-axi-manager-post-burst-residue-next-slice-selection
title: Post-burst-residue selector chooses concrete-ID same-ID ordering readiness
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.86?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.86 select?"
  - "what comes after burst residue alignment?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.85?"
  - "why is concrete-ID same-ID ordering next?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, concrete-id, ordering, selector, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_BURST_RESIDUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_BURST_RESIDUE_ALIGNMENT_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.86|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.87|POST_BURST_RESIDUE_NEXT_SLICE_SELECTION|concrete-ID same-ID ordering readiness|per_id_issue_order_queues' docs/AXI_IAL2_MANAGER_POST_BURST_RESIDUE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.86` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.87`, AXI concrete-ID same-ID ordering
readiness, after `.85` removed broad burst residue for the covered generated
auto-ID multi-beat output-bank subset.

The public multi-beat sample now leaves only `concrete_id_same_id_ordering`
and `per_id_issue_order_queues` under `same_id_ordering.residue`.
Concrete-ID samples still keep `same_id_ordering` under
`id_response_rule_engine.residue`.

`.87` should decide whether a conservative concrete-ID same-ID constraint,
report/static classification, public same-ID policy, or generated per-ID
issue-order queue substrate must come first.
