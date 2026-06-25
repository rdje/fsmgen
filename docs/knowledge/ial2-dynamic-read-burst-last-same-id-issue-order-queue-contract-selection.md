---
id: ial2-dynamic-read-burst-last-same-id-issue-order-queue-contract-selection
title: Dynamic read burst-last same-ID queue contract selects implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.462 select?"
  - "what is the public contract for dynamic read burst-last same-ID issue-order queue behavior?"
  - "what should IAL2-FEATURE-COMPLETENESS-FRONTIER.463 implement?"
  - "what remains unsupported after dynamic read burst-last queue contract selection?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, read-rid, rlast, contract]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_ID_QUEUE_STATE_REPRESENTATION_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.462|IAL2-FEATURE-COMPLETENESS-FRONTIER\.463|DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION|bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract|generated_dynamic_issue_order_queue_demux_last_beat|generated_dynamic_read_rid_rlast_issue_order_queue|read_rid_rlast_two_dynamic_transactions|dynamic_read_burst_last_same_id_issue_order_queue' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.462` selects `.463`, direct
implementation of the first generated dynamic read burst-last `RID && RLAST`
same-ID `issue-order-queue` behavior.

The selected public contract is exactly two all-dynamic read transactions
with `same-id-ordering.read (dynamic-id-reuse issue-order-queue)`, explicit
generated `response-demux.read`, `response-scope burst-last`, and one-bit
`last-signal`. The report contract selects
`bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract`,
`generated_dynamic_issue_order_queue_demux_last_beat`,
`generated_dynamic_read_rid_rlast_issue_order_queue`,
`read_rid_rlast_two_dynamic_transactions`,
`compact_runtime_id_issue_order_slots`, and
`dynamic_issue_order_earliest_matching_slot`.

The behavior owner must split raw matching from final completion: raw
accepted read beats match active captured `ARID` slots by `RID` without
`RLAST`, while selected dequeue and generated transaction completions require
the earliest matching slot plus `RLAST`.

Read-data over generated dynamic read queues, raw `ARLEN`, runtime
validation, multi-beat output banks, queue recapture widening, broader queue
cardinality, mixed dynamic/static queues, dynamic scoreboards, direct backend
behavior, backend-language variants, and VHDL remain future exact owners.
