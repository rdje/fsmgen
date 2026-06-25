---
id: ial2-dynamic-read-depth3-same-id-issue-order-queue-readiness-audit
title: Depth-3 all-dynamic read single-beat queue can be implemented directly
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.484 select?"
  - "is generated dynamic read depth-3 same-ID issue-order queue ready?"
  - "what owns depth-3 dynamic read single-beat queue implementation?"
  - "what remains deferred after the depth-3 dynamic read queue audit?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, cardinality, readiness]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue.ppif; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.484|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.485|DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT|read_rid_three_dynamic_transactions|r0_r1_dequeue_r0_enqueue_r2|depth-3 dynamic read' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`.484` selects `.485`, direct bounded implementation of one generated
all-dynamic read single-beat `RID` same-ID `issue-order-queue` with exactly
three dynamic read transactions, generated single-beat `RID` response-demux
completion, `read-max-pending` at least 3, and queue depth 3.

The audit found the current blocker is local and explicit: the dynamic read
queue planner still requires exactly two all-dynamic reads and records queue
depth 2, while the shared dynamic queue builder currently admits depth 3 only
for write. The transition, assignment, state-expression, selected-match,
assertion, and report helpers are already driven by queue depth and the
transaction list.

A lightweight helper probe for a synthetic depth-3 read group produced 99
transition rules, 19 assertions, zero duplicate names, the disambiguated
cross-transaction rule
`axi0_read_dynamic_same_id_issue_order_r0_r1_dequeue_r0_enqueue_r2`, the
tail-selected refresh rule
`axi0_read_dynamic_same_id_issue_order_r2_r1_r0_dequeue_enqueue_r0`, and the
`r2` completion-selected-match assertion.

`.485` should update the depth-3 read single-beat behavior, report/test
expectations, one PPIF sample, support accounting, and docs in one owned
slice. Read burst-last depth-3 queues, read-data over depth-3 dynamic queues,
mixed dynamic/static queues, scoreboards, arbitrary cardinality, direct
backend behavior, backend-language variants, external converter dependencies,
and VHDL remain deferred.
