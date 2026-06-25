---
id: ial2-post-dynamic-write-same-id-issue-order-queue-next-slice-selection
title: Post dynamic write queue selector chooses dynamic read queue readiness
answers:
  - "what comes after dynamic write same-ID issue-order queue behavior?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.456 select?"
  - "why is dynamic read same-ID queue readiness next?"
  - "what remains unsupported after the post dynamic write queue selector?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, read-rid, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_ID_QUEUE_STATE_REPRESENTATION_SELECTION.md; docs/AXI_IAL2_MANAGER_GENERATED_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_GENERATED_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.456|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.457|POST_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION|dynamic read same-ID|response-demux\\.read dynamic ID matching cannot be combined with same_id_ordering\\.read|generated_dynamic_issue_order_queue_demux|bounded_dynamic_write_bid_issue_order_queue_demux_contract' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.456` selects `.457`, readiness audit for
generated dynamic read same-ID `issue-order-queue` behavior after `.455`
shipped the first generated dynamic write `BID` queue.

The selector changes no runtime or generated behavior. It records that the
current generated dynamic queue path is write-only: `response-demux.write` can
use `generated_dynamic_issue_order_queue_demux`, while the read demux path
still rejects `same-id-ordering.read` beyond covered dynamic reject mappings.

Dynamic read queue readiness is next because existing read-side dynamic
behavior already has single-beat `RID`, burst-last `RID && RLAST`, read-data,
raw `ARLEN`, runtime validation, multi-beat, and recapture consumers. The audit
must decide whether the first generated read queue should be single-beat,
burst-last, a shared read representation prerequisite, broader write
cardinality first, or another narrower prerequisite.

Broader write cardinality, mixed dynamic/static queues, dynamic scoreboards,
direct backend behavior, backend-language variants, and VHDL remain future
exact owners.
