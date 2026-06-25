---
id: ial2-dynamic-write-depth3-same-id-issue-order-queue-readiness-audit
title: Depth-3 all-dynamic write queue can be implemented directly
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.481 select?"
  - "is generated dynamic write depth-3 same-ID issue-order queue ready?"
  - "what owns depth-3 dynamic write queue implementation?"
  - "what remains deferred after the depth-3 write queue audit?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, cardinality, readiness]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_QUEUE_RECAPTURE_REPORT_NEXT_SLICE_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; ppif/axi_manager_capacity_status_dynamic_write_same_id_issue_order_queue.ppif; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.481|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.482|DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT|write_bid_three_dynamic_transactions|depth-3|three dynamic write' docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`.481` selects `.482`, direct bounded implementation of one generated
all-dynamic write BID same-ID `issue-order-queue` with exactly three dynamic
write transactions, generated BID response-demux completion, `write-max-pending`
at least 3, and queue depth 3.

The audit found the current blocker is the local dynamic queue admission and
storage gate, which is still hard-coded for `depth == 2` and exactly two
transactions. The transition, assignment, state-expression, selected-match,
assertion, and report helpers are already driven by `group->{depth}` and the
transaction list.

`.482` should update the depth-3 write behavior, report/test expectations,
one PPIF sample, support accounting, and docs in one owned slice. Read-side
depth-3 queues, read-data, mixed dynamic/static queues, scoreboards, direct
backend behavior, backend-language variants, and VHDL remain deferred.
