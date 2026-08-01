---
id: ial2-dynamic-read-burst-last-depth3-same-id-issue-order-queue-behavior
title: Depth-3 all-dynamic read burst-last same-ID issue-order queue is generated
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.488 ship?"
  - "is generated dynamic read burst-last depth-3 same-ID issue-order queue supported?"
  - "what PPIF sample covers depth-3 dynamic read RID RLAST queue behavior?"
  - "what first generated scope names the depth-3 dynamic read RLAST queue?"
  - "does FSMGen depend on sv2v for this read RLAST queue behavior?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, rlast, cardinality, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.488|DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR|axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue|read_rid_rlast_three_dynamic_transactions|axi0_read_dynamic_same_id_issue_order_nonlast_no_dequeue|axi0_read_dynamic_same_id_issue_order_r2_completion_selected_match|sv2v' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
  t/248-regression-corpus-accounting.t docs/REGRESSION_CORPUS.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`.488` ships generated support for one bounded depth-3 all-dynamic read
burst-last `RID && RLAST` same-ID `issue-order-queue` with exactly three
dynamic read transactions, one-bit `last_signal`, `read-max-pending` at
least 3, and queue depth 3.

The public sample is
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue.ppif`,
support-accounted as
`intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue`.

The same-ID ordering report uses
`first_generated_scope: read_rid_rlast_three_dynamic_transactions`, lists
`r0`, `r1`, and `r2`, and reports `generated_queues[0].depth: 3`.
The queue includes non-final no-dequeue, slot2 onehot, and `r2`
completion-selected-match assertions. FSMGen-owned generation/lowering
remains the default; `sv2v` is not selected as a dependency for this slice.
