---
id: ial2-mixed-dynamic-static-write-multi-static-same-id-issue-order-queue-behavior
title: Mixed dynamic/static write BID same-ID issue-order queue is generated for one dynamic plus two static transactions
answers:
  - "does FSMGen support one-dynamic plus two-static mixed write BID issue-order queues?"
  - "does FSMGen generate mixed dynamic/static write BID multi-static same-ID issue-order queue behavior?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.524 implement?"
  - "which PPIF sample covers mixed dynamic/static write BID multi-static issue-order queues?"
date: 2026-06-26
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, mixed-dynamic-static, same-id-ordering, issue-order-queue, write-bid, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_MULTI_STATIC_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/REGRESSION_CORPUS.md; docs/ISF_PUBLIC_INTERFACE_CONTRACT.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md; docs/book/src/11-extensions-and-embedding.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static.ppif | rg 'bounded_mixed_dynamic_static_write_bid_issue_order_queue_demux_contract|generated_mixed_dynamic_static_issue_order_queue_demux|write_bid_one_dynamic_two_static_transactions|4.d3|4.d5'
---

FSMGen generates mixed dynamic/static write `BID` same-ID issue-order queue
behavior for exactly one dynamic write transaction and two pairwise-distinct
concrete static write transactions.

The public sample is
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static.ppif`,
registered as
`intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static`.

The generated report uses
`bounded_mixed_dynamic_static_write_bid_issue_order_queue_demux_contract`,
`generated_mixed_dynamic_static_issue_order_queue_demux`,
`earliest_matching_captured_or_static_runtime_id`,
`captured_or_static_request_id`, and
`mixed_dynamic_static_issue_order_earliest_matching_slot`. Static/dynamic
runtime-ID overlap is allowed and ordered by queue position. The same-ID
policy scope is `write_bid_one_dynamic_two_static_transactions`, with static
enqueue literals `4'd3` and `4'd5`.

The implementation is FSMGen-owned and does not depend on `sv2v`.
