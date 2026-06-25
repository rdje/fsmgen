---
id: ial2-dynamic-read-burst-last-depth3-same-id-issue-order-queue-read-data-runtime-validation-behavior
title: Depth-3 dynamic RLAST queue read-data supports runtime ARLEN validation
answers:
  - "does depth-3 dynamic RLAST queue read-data support runtime beat-count RLAST validation?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.497 ship?"
  - "which PPIF sample covers depth-3 dynamic RLAST queue read-data runtime validation?"
  - "does depth-3 dynamic RLAST queue runtime validation depend on sv2v?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, rlast, read-data, burst-length, arlen, runtime-validation, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.497|axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length_runtime_assertion|generated_expected_beat_count_storage|axi0_r2_read_beat_count_q|axi0_r2_expected_final_beat_has_rlast|sv2v' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t docs/REGRESSION_CORPUS.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`.497` ships runtime beat-count/`RLAST` validation over the generated
all-dynamic read burst-last `RID && RLAST` depth-3 same-ID
`issue-order-queue` scalar read-data raw-`ARLEN` behavior from `.494`.

The public sample is
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif`.
It covers exactly `r0`, `r1`, and `r2`; queue depth 3; one-bit `axi0_rlast`;
`generated_dynamic_issue_order_queue_demux_last_beat`; and `read-data.read`
last-beat syntax with `burst-length` source `arlen`, signal `axi0_arlen`
width 8, `axlen-plus-one`, request capture, max-beats 16, and validation
`runtime-assertion`.

FSMGen generates `axi0_r0_expected_beats_q`,
`axi0_r1_expected_beats_q`, `axi0_r2_expected_beats_q`,
`axi0_r0_read_beat_count_q`, `axi0_r1_read_beat_count_q`,
`axi0_r2_read_beat_count_q`, six beat-count init/increment rules, and
twelve runtime assertions. It remains FSMGen-owned generation/lowering:
external converters such as `sv2v`, backend variants, arbitrary cardinality,
multi-beat output banks over this depth-3 queue, mixed dynamic/static queues,
scoreboards, and VHDL remain deferred.
