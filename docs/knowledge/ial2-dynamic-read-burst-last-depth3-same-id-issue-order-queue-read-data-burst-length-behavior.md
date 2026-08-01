---
id: ial2-dynamic-read-burst-last-depth3-same-id-issue-order-queue-read-data-burst-length-behavior
title: Depth-3 dynamic RLAST queue read-data supports report-only raw ARLEN
answers:
  - "does depth-3 dynamic RLAST queue read-data support report-only raw ARLEN?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.494 ship?"
  - "which PPIF sample covers depth-3 dynamic RLAST queue read-data raw ARLEN?"
  - "does depth-3 dynamic RLAST queue raw ARLEN depend on sv2v?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, rlast, read-data, burst-length, arlen, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: >-
  rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.494|axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length|generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse|axi0_r2_arlen_q|sv2v' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t docs/REGRESSION_CORPUS.md
  docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`.494` ships report-only raw-`ARLEN` burst-length capture over the generated
all-dynamic read burst-last `RID && RLAST` depth-3 same-ID
`issue-order-queue` scalar read-data behavior from `.491`.

The public sample is
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length.ppif`.
It covers exactly `r0`, `r1`, and `r2`; queue depth 3; one-bit `axi0_rlast`;
`generated_dynamic_issue_order_queue_demux_last_beat`; and `read-data.read`
last-beat syntax with `burst-length` source `arlen`, signal `axi0_arlen`
width 8, `axlen-plus-one`, request capture, max-beats 16, and validation
`report-only`.

FSMGen generates `axi0_arlen`, `axi0_r0_arlen_q`,
`axi0_r1_arlen_q`, `axi0_r2_arlen_q`, and per-transaction
`axi0_r*_burst_length_capture` request rules. It does not generate
beat-count state or runtime `RLAST` assertions for this report-only shape.
Runtime validation, multi-beat output banks, mixed dynamic/static queues,
arbitrary cardinality, direct backend behavior, backend-language variants,
external converters such as `sv2v`, and VHDL remain deferred.
