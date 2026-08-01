---
id: ial2-dynamic-read-single-beat-same-id-issue-order-queue-contract-selection
title: Dynamic read single-beat same-ID queue contract selects implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.458 select?"
  - "what is the public contract for dynamic read single-beat same-ID issue-order queue behavior?"
  - "what should IAL2-FEATURE-COMPLETENESS-FRONTIER.459 implement?"
  - "what remains unsupported after dynamic read single-beat queue contract selection?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, read-rid, contract]
evidence: >-
  docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_ID_QUEUE_STATE_REPRESENTATION_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md;
  docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.458|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.459|DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION|bounded_dynamic_read_rid_issue_order_queue_demux_contract|generated_dynamic_read_rid_issue_order_queue|read_rid_two_dynamic_transactions|axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue|generated_dynamic_issue_order_queue_demux' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.458` selects `.459`, implementation of
the first generated dynamic read same-ID `issue-order-queue` behavior.

The selected public contract is exactly two all-dynamic read transactions with
`same-id-ordering.read (dynamic-id-reuse issue-order-queue)` and explicit
generated `response-demux.read` using `response-scope single-beat`. The report
contract selects `bounded_dynamic_read_rid_issue_order_queue_demux_contract`,
`generated_dynamic_read_rid_issue_order_queue`,
`read_rid_two_dynamic_transactions`, `compact_runtime_id_issue_order_slots`,
and `dynamic_issue_order_earliest_matching_slot`.

Read burst-last `RID && RLAST` queues, read-data over generated dynamic read
queues, raw `ARLEN`, runtime validation, multi-beat output banks, broader
queue cardinality, mixed dynamic/static queues, dynamic scoreboards, direct
backend behavior, backend-language variants, and VHDL remain future exact
owners.
