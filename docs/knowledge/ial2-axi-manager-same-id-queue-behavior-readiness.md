---
id: ial2-axi-manager-same-id-queue-behavior-readiness
title: Same-ID queue behavior readiness selects a first behavior-slice selector
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.104 decide?"
  - "can FSMGen ship generated same-ID queue behavior directly after metadata?"
  - "does same-ID queue behavior need a new IAL1 prerequisite?"
  - "what comes after same-ID queue-head demux metadata?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, same-id, issue-order, queue, response-demux, readiness, task-tree]
evidence: docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_REPRESENTATION_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.104|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.105|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.106|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.108|no new IAL1/IAL0/SystemVerilog substrate prerequisite|generated AXI same-ID read burst-last queue state|generated_write_bid_queue_head_demux|queue state needs a queue-head-demux dequeue event|accepted_same_id_reuse|generated_queue_behavior' docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE_SELECTION.md docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md docs/AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.104` audited generated AXI same-ID queue
state and queue-head response-demux readiness after `.103`
selected-not-generated metadata.

The audit found no obvious new IAL1, IAL0, or SystemVerilog substrate
prerequisite for the first bounded generated behavior slice. Existing lower
layers already carry scalar state, pulse actions, guarded rules, generated
inputs/outputs, Boolean/equality guards, constants, and generated assertions.

Direct broad behavior implementation is still too large. Queue state and
queue-head demux are behavior-coupled: queue state needs a dequeue event from
queue-head demux, and queue-head demux needs queue-head transaction identity
from queue state. Accepted concrete same-ID reuse must stay false until both
sides ship together for a covered group.

`.105` later selected the first generated behavior boundary, `.106` shipped
the bounded read burst-last depth-2 sample behavior, and `.108` shipped the
bounded write depth-2 queue-head `BID` demux behavior. Broader same-ID queue
expansion remains behind the active `.109` selector.
