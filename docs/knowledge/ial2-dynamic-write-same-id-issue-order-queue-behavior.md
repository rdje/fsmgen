---
id: ial2-dynamic-write-same-id-issue-order-queue-behavior
title: Dynamic write same-ID issue-order queue behavior is generated
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.455 implement?"
  - "how does FSMGen generate dynamic same-ID issue-order queues for AXI write BID?"
  - "what PPIF sample demonstrates dynamic write same-ID issue-order queue behavior?"
  - "what remains unsupported after dynamic write same-ID issue-order queue behavior?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, write-bid]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_write_same_id_issue_order_queue.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.455|bounded_dynamic_write_bid_issue_order_queue_demux_contract|generated_dynamic_issue_order_queue_demux|compact_runtime_id_issue_order_slots|dynamic_issue_order_earliest_matching_slot|generated_dynamic_write_bid_issue_order_queue|axi_manager_capacity_status_dynamic_write_same_id_issue_order_queue' docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md ppif/axi_manager_capacity_status_dynamic_write_same_id_issue_order_queue.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t docs/REGRESSION_CORPUS.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.455` implements generated dynamic same-ID
`issue-order-queue` behavior for exactly two all-dynamic AXI manager write
transactions with explicit generated `response-demux.write`.

The support-accounted public sample is
`ppif/axi_manager_capacity_status_dynamic_write_same_id_issue_order_queue.ppif`.
It generates compact runtime-ID issue-order slots, captures `AWID` into
slot-local ID registers at enqueue, and matches `BID` responses through
`dynamic_issue_order_earliest_matching_slot`.

Same captured IDs complete in queue order because the earliest matching slot
wins. Different captured IDs may complete out of global issue order when a
younger slot matches `BID` and an older slot does not. The report uses
`bounded_dynamic_write_bid_issue_order_queue_demux_contract`,
`generated_dynamic_issue_order_queue_demux`,
`compact_runtime_id_issue_order_slots`, and
`generated_dynamic_write_bid_issue_order_queue`.

Dynamic read queues, more than two dynamic writes, mixed dynamic/static
queues, dynamic scoreboards, direct backend behavior, backend-language
variants, and VHDL remain future exact owners.
