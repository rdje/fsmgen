---
id: ial2-axi-manager-same-id-queue-behavior-first-slice
title: Same-ID queue behavior first slice is generated for read burst-last depth-2
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.106 ship?"
  - "is AXI same-ID queue-head response demux generated?"
  - "what does the same-ID queue-head response-demux sample report?"
  - "does FSMGen accept concrete same-ID reuse for the queue-head sample?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.107?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, same-id, issue-order, queue, response-demux, generated, task-tree]
evidence: docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE_SELECTION.md; ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif; ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'generated_read_burst_last_queue_head_demux|generated_write_bid_queue_head_demux|accepted_same_id_reuse|generated_queue_behavior|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.109' docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md docs/AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.106` shipped the first generated AXI
same-ID issue-order queue behavior.

For the public sample
`ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif`,
FSMGen now generates read burst-last queue-head behavior for one duplicate
concrete read-ID group with two transactions and depth `2`.

The generated IAL1 uses compact one-hot queue state for concrete ID `3`,
emits finite enqueue/dequeue and same-cycle dequeue/enqueue update rules,
emits queue-head `RID`/`RLAST` response-demux rules for `r0` and `r1`, and
exposes `axi0_r0_complete`/`axi0_r1_complete` as generated pulse outputs.

Schedule JSON marks `response_demux.generated_behavior` and
`same_id_ordering.generated_behavior` true. The read concrete-ID reuse policy
reports `enforcement: generated_issue_order_queue`,
`implementation_status: generated_read_burst_last_queue_head_demux`,
`accepted_same_id_reuse: true`, and `generated_queue_behavior: true`.

`.107` selected write queue-head behavior as the next same-ID expansion, and
`.108` has since shipped generated write depth-2 queue-head `BID` demux for
one duplicate concrete write-ID group. `.110` has also shipped generated read
single-beat depth-2 queue-head `RID` demux without `RLAST` for one duplicate
concrete read-ID group. The active frontier is now
`IAL2-FEATURE-COMPLETENESS-FRONTIER.111`, an audit/selector for the next
same-ID queue behavior expansion. Deeper or multiple duplicate-ID groups,
same-family mixed auto-ID, read-data consumption, direct backend, and VHDL
remain deferred.
