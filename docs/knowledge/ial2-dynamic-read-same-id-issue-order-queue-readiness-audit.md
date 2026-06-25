---
id: ial2-dynamic-read-same-id-issue-order-queue-readiness-audit
title: Dynamic read same-ID queue readiness selects single-beat RID contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.457 select?"
  - "is generated dynamic read same-ID issue-order queue behavior ready?"
  - "why is dynamic read single-beat RID queue contract selection next?"
  - "what remains unsupported after dynamic read same-ID queue readiness?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, read-rid, readiness]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_ID_QUEUE_STATE_REPRESENTATION_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.457|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.458|DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT|dynamic read single-beat|response-demux\\.read dynamic ID matching cannot be combined with same_id_ordering\\.read|bounded_dynamic_read_rid_demux_contract|compact_runtime_id_issue_order_slots' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.457` selects `.458`, public contract
selection for the first generated dynamic read same-ID `issue-order-queue`
behavior.

The audit finds the substrate ready for a contract selector, not direct
behavior. The first read-side contract should be all-dynamic read single-beat
`RID` response demux with explicit `same-id-ordering.read
(dynamic-id-reuse issue-order-queue)`, because it avoids final-beat-only
dequeue, raw non-final beats, `RLAST`, and read-data/runtime/multi-beat
consumer coupling.

Read burst-last `RID && RLAST` queues, read-data over generated dynamic read
queues, raw `ARLEN`, runtime validation, multi-beat output banks, broader
queue cardinality, mixed dynamic/static queues, dynamic scoreboards, direct
backend behavior, backend-language variants, and VHDL remain future exact
owners.
