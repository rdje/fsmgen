---
id: ial2-mixed-dynamic-static-write-same-id-issue-order-queue-behavior
title: Mixed dynamic/static write BID same-ID issue-order queue is generated for selected one-static and two-static shapes
answers:
  - "does FSMGen generate mixed dynamic/static write BID same-ID issue-order queue behavior?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.503 implement?"
  - "does mixed dynamic/static write issue-order queue allow static ID overlap?"
  - "does mixed dynamic/static write issue-order queue depend on sv2v?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, mixed-dynamic-static, same-id-ordering, issue-order-queue, write-bid, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_MULTI_STATIC_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue.ppif; ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'write_mixed_dynamic_static_same_id_issue_order_queue(_multi_static)?|write_bid_one_dynamic_(one|two)_static_transactions|bounded_mixed_dynamic_static_write_bid_issue_order_queue_demux_contract|generated_mixed_dynamic_static_issue_order_queue_demux|4.d3|4.d5' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_MULTI_STATIC_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue.ppif ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

FSMGen generates mixed dynamic/static write `BID` same-ID issue-order queue
behavior for the selected one-dynamic plus one-concrete-static and
one-dynamic plus two-concrete-static write transaction shapes.

The public samples are:

- `ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue.ppif`,
  registered as
  `intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue`.
- `ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static.ppif`,
  registered as
  `intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static`.

The generated report uses
`bounded_mixed_dynamic_static_write_bid_issue_order_queue_demux_contract`,
`generated_mixed_dynamic_static_issue_order_queue_demux`,
`earliest_matching_captured_or_static_runtime_id`,
`captured_or_static_request_id`, and
`mixed_dynamic_static_issue_order_earliest_matching_slot`. Static/dynamic
runtime-ID overlap is allowed and ordered by queue position:
`static_id_conflict_policy: ordered_overlap_allowed`.

The implementation is FSMGen-owned and does not depend on `sv2v`.
