---
id: ial2-axi-manager-multiple-mixed-depth3-runtime-validation-behavior
title: Multiple/mixed depth-3 queue-head runtime validation is shipped
answers:
  - "did IAL2-FEATURE-COMPLETENESS-FRONTIER.186 ship?"
  - "does IAL2 support runtime validation over multiple depth-3 queue-head last-beat read-data?"
  - "does IAL2 support runtime validation over mixed depth-3/depth-2 queue-head last-beat read-data?"
  - "what samples cover multiple/mixed depth-3 queue-head runtime-validation behavior?"
date: 2026-06-19
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3, runtime-validation, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md; ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif; ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.186|MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR|read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion|read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion|beat_count_validation_generated_behavior|generated_beat_count_validation' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.186` shipped generated
beat-count/`RLAST` runtime validation over multiple/mixed depth-3 read
burst-last queue-head scalar last-beat read-data.

The public samples are:

- `ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif`
- `ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion.ppif`

The generated behavior preserves request-captured raw-`ARLEN` state and
scalar last-beat `RDATA`/`RRESP` capture, then adds expected-beat storage,
read-beat counters, request-time initialization rules, matched-read-beat
increment rules, and beat-count/`RLAST` assertions for every admitted read
transaction.

The read-data report sets `burst_length_validation: runtime_assertion` and
`beat_count_validation_generated_behavior: true`, removes
`generated_beat_count_validation` residue, and still leaves multi-beat
payload/output banks, scalar `RRESP` aggregation, write-family read-data,
same-family mixed auto-ID, direct backend, VHDL, and backend-language
variants to separate owned leaves.
