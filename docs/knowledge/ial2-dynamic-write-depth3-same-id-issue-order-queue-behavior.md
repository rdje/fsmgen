---
id: ial2-dynamic-write-depth3-same-id-issue-order-queue-behavior
title: Depth-3 all-dynamic write same-ID issue-order queue is generated
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.482 ship?"
  - "is generated dynamic write depth-3 same-ID issue-order queue supported?"
  - "what PPIF sample covers the depth-3 dynamic write queue?"
  - "how are depth-3 dynamic queue rule names disambiguated?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, cardinality, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_write_depth3_same_id_issue_order_queue.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.482|DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR|axi_manager_capacity_status_dynamic_write_depth3_same_id_issue_order_queue|write_bid_three_dynamic_transactions|w0_w1_dequeue_w0_enqueue_w2|depth-3 dynamic write' docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md ppif/axi_manager_capacity_status_dynamic_write_depth3_same_id_issue_order_queue.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t docs/REGRESSION_CORPUS.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`.482` ships generated support for one depth-3 all-dynamic write BID same-ID
`issue-order-queue` with exactly three dynamic write transactions and
`write-max-pending` at least 3.

The public sample is
`ppif/axi_manager_capacity_status_dynamic_write_depth3_same_id_issue_order_queue.ppif`,
support-accounted as
`intent.ppif_axi_manager_capacity_status_dynamic_write_depth3_same_id_issue_order_queue`.

The same-ID ordering report uses
`first_generated_scope: write_bid_three_dynamic_transactions`, lists `w0`,
`w1`, and `w2`, and reports `generated_queues[0].depth: 3`. Ambiguous
depth-3 cross-transaction selected-dequeue-plus-enqueue rules include the
selected dequeued transaction in their name, for example
`axi0_write_dynamic_same_id_issue_order_w0_w1_dequeue_w0_enqueue_w2`, while
same-transaction refresh names keep the existing `dequeue_enqueue` form.
