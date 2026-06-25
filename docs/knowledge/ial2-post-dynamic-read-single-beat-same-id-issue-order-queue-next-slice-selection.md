---
id: ial2-post-dynamic-read-single-beat-same-id-issue-order-queue-next-slice-selection
title: Post dynamic read single-beat queue selector chooses read burst-last queue readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.460 select?"
  - "what comes after dynamic read single-beat same-ID issue-order queue behavior?"
  - "why is dynamic read burst-last queue readiness next?"
  - "what remains unsupported after the post dynamic read queue selector?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, read-rid, rlast, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.460|IAL2-FEATURE-COMPLETENESS-FRONTIER\.461|POST_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION|dynamic read burst-last|dynamic-id-reuse issue-order-queue supports only response_scope single-beat|bounded_dynamic_read_rid_issue_order_queue_demux_contract|generated_dynamic_issue_order_queue_demux_last_beat' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.460` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.461`, readiness audit for generated
dynamic read burst-last `RID && RLAST` same-ID `issue-order-queue` behavior.

The selector follows `.459`, which shipped generated bounded two-transaction
all-dynamic read single-beat `RID` dynamic same-ID issue-order queue behavior.
The next burst-last queue path needs a readiness audit because it must define
final-beat-only queue dequeue, raw non-final beat handling, `response-scope
burst-last` and `last-signal` requirements, selected final-match assertions,
generated completion ownership, report/residue movement, support-accounted
sample shape, validation gates, and rollback before behavior changes.

Read-data over generated dynamic queues, raw `ARLEN`, runtime validation,
multi-beat output banks, broader cardinality, mixed dynamic/static queues,
dynamic scoreboards, validation retry, direct backend behavior,
backend-language variants, and VHDL remain unsupported future exact-owner
work after the `.460` selector.
