---
id: ial2-axi-manager-same-id-queue-behavior-first-slice-selection
title: Same-ID queue behavior first slice is read burst-last depth-2
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.105 decide?"
  - "what is the first generated AXI same-ID queue behavior slice?"
  - "what same-ID queue behavior did .105 select?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, issue-order, queue, response-demux, implementation, task-tree]
evidence: docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.105|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.106|read-family-only|burst-last|exactly two read transactions|computed queue depth 2|generated AXI same-ID read burst-last queue state' docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE_SELECTION.md docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.105` selected the first generated AXI
same-ID queue behavior implementation slice.

The selected implementation owner was
`IAL2-FEATURE-COMPLETENESS-FRONTIER.106`, generated read burst-last queue
state plus queue-head response demux for the existing public same-ID
queue-head sample shape: one selected read family, one duplicate concrete
read-ID group, exactly two read transactions, computed queue depth `2`,
one-bit `RLAST`, no same-family auto-ID lifecycle, and no read-data
consumption.

`.106` has since shipped that bounded behavior. Write queue-head behavior,
read `single-beat`, deeper or multiple groups, mixed same-family auto-ID,
read-data consumption, direct backend, and VHDL remain deferred.
