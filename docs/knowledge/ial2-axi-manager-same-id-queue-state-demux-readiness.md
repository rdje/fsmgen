---
id: ial2-axi-manager-same-id-queue-state-demux-readiness
title: Same-ID queue readiness audit selects queue-state representation first
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.100 decide?"
  - "can FSMGen implement same-ID queue-head demux before queue state?"
  - "what comes after the same-ID queue readiness audit?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.101?"
  - "what is the current same-ID queue behavior frontier?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, issue-order, queue, demux, readiness, task-tree]
evidence: docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_REPRESENTATION_SELECTION.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_ADMITTED_REQUEST_PULSES_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.100|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.101|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.105|compact_onehot_transaction_slots|first generated AXI same-ID queue state and queue-head behavior slice|accepted_same_id_reuse|generated_queue_behavior|auto-ID busy/selected-ID' docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_DEMUX_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_REPRESENTATION_SELECTION.md docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.100` audits AXI same-ID
`issue-order-queue` state and queue-head demux readiness after admitted
request pulses.

The audit does not select behavior implementation. Live reports show admitted
request pulses are generated, but `accepted_same_id_reuse` and
`generated_queue_behavior` remain false. Existing generated response demux is
still auto-ID busy/selected-ID matching, including the read burst-last path,
so queue-head demux cannot ship before queue identity state exists.

`.101` has since selected `compact_onehot_transaction_slots`, `.102` selected
the queue-head response-demux contract, `.103` shipped selected-not-generated
metadata, `.104` selected the behavior-slice selector, and `.105` selected the
first implementation boundary. The current active frontier is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.106`, generated AXI same-ID read
burst-last queue state and queue-head demux behavior. Duplicate concrete
same-ID reuse remains fail-closed until generated behavior ships.
