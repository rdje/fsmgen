---
id: ial2-dynamic-read-burst-last-same-id-issue-order-queue-behavior
title: Dynamic read burst-last same-ID queue behavior ships
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.463 ship?"
  - "is dynamic read burst-last same-ID issue-order queue behavior generated?"
  - "what public PPIF sample covers dynamic read RID RLAST issue-order queue behavior?"
  - "how does the dynamic read burst-last issue-order queue treat non-final beats?"
  - "what remains unsupported after dynamic read burst-last queue behavior?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, read-rid, rlast, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.463|bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract|generated_dynamic_issue_order_queue_demux_last_beat|generated_dynamic_read_rid_rlast_issue_order_queue|read_rid_rlast_two_dynamic_transactions|axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue|axi0_read_dynamic_same_id_issue_order_nonlast_no_dequeue|earliest_matching_captured_runtime_id_and_last_signal' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t docs/REGRESSION_CORPUS.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.463` ships generated bounded
two-transaction all-dynamic read burst-last `RID && RLAST` dynamic same-ID
`issue-order-queue` behavior.

The public support-accounted sample is
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue.ppif`.
It requires exactly two dynamic read transactions, `same-id-ordering.read
(dynamic-id-reuse issue-order-queue)`, explicit generated
`response-demux.read` with `response-scope burst-last`, one-bit
`last-signal axi0_rlast`, read ID-family metadata with request `ARID` and
response `RID`, and `read-max-pending >= 2`.

FSMGen generates compact runtime-ID issue-order slots with slot-local captured
`ARID`, raw earliest matching `RID` response ownership, final completion and
dequeue only on earliest matching captured runtime ID plus `RLAST`,
same-cycle selected final dequeue plus one enqueue, queue-specific assertions
including `axi0_read_dynamic_same_id_issue_order_nonlast_no_dequeue`, report
mode `bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract`,
completion source `generated_dynamic_issue_order_queue_demux_last_beat`,
same-ID policy status `generated_dynamic_read_rid_rlast_issue_order_queue`,
and `first_generated_scope: read_rid_rlast_two_dynamic_transactions`.

Read-data over generated dynamic read queues, raw `ARLEN`, runtime
validation, multi-beat output banks, broader queue cardinality, mixed
dynamic/static queues, dynamic scoreboards, direct backend behavior,
backend-language variants, and VHDL remain future exact owners.
