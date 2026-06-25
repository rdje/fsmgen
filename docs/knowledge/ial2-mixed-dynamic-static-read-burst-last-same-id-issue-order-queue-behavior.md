---
id: ial2-mixed-dynamic-static-read-burst-last-same-id-issue-order-queue-behavior
title: Mixed dynamic/static read RID/RLAST same-ID issue-order queue is generated for one dynamic plus one static transaction
answers:
  - "does FSMGen generate mixed dynamic/static read RID/RLAST same-ID issue-order queue behavior?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.509 implement?"
  - "does mixed dynamic/static read burst-last issue-order queue dequeue only on RLAST?"
  - "does mixed dynamic/static read RID/RLAST issue-order queue depend on sv2v?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, mixed-dynamic-static, same-id-ordering, issue-order-queue, read-rid, rlast, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue.ppif | rg 'bounded_mixed_dynamic_static_read_rid_rlast_issue_order_queue_demux_contract|generated_mixed_dynamic_static_issue_order_queue_demux_last_beat|axi0_rlast|generated_mixed_dynamic_static_read_rid_rlast_issue_order_queue|read_rid_rlast_one_dynamic_one_static_transaction'
---

FSMGen generates mixed dynamic/static read burst-last `RID && RLAST` same-ID
issue-order queue behavior for exactly one dynamic read transaction and one
concrete static read transaction.

The public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue.ppif`,
registered as
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue`.

The generated report keeps the top-level response-demux mode as
`bounded_response_demux_contract` and reports the read-family mode as
`bounded_mixed_dynamic_static_read_rid_rlast_issue_order_queue_demux_contract`.
It also reports
`generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`,
`earliest_matching_captured_or_static_runtime_id_and_last_signal`,
`captured_or_static_request_id`, `axi0_rlast`, and
`mixed_dynamic_static_issue_order_earliest_matching_slot`. Static/dynamic
runtime-ID overlap is allowed and ordered by queue position, and matching
non-final beats do not dequeue the queue.

The implementation is FSMGen-owned and does not depend on `sv2v`.
