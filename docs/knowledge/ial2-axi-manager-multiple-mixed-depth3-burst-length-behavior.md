---
id: ial2-axi-manager-multiple-mixed-depth3-burst-length-behavior
title: Multiple/mixed depth-3 queue-head report-only ARLEN burst-length behavior is shipped
answers:
  - "did IAL2-FEATURE-COMPLETENESS-FRONTIER.183 ship?"
  - "does IAL2 support report-only ARLEN over multiple depth-3 queue-head last-beat read-data?"
  - "does IAL2 support report-only ARLEN over mixed depth-3/depth-2 queue-head last-beat read-data?"
  - "what samples cover multiple/mixed depth-3 queue-head burst-length behavior?"
date: 2026-06-18
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3, burst-length, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md; ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length.ppif; ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.183|MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR|read_burst_last_multi_depth3_same_id_queue_head_burst_length|read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length|generated_beat_count_validation' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/Support/RegressionCorpus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.183` shipped generated report-only
raw-`ARLEN` burst-length capture over multiple/mixed depth-3 read burst-last
queue-head scalar last-beat read-data.

The public samples are:

- `ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length.ppif`
- `ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length.ppif`

The generated behavior adds width-8 `axi0_arlen`, per-transaction raw-`ARLEN`
storage, and request-guarded burst-length capture rules while preserving the
generated queue-head `RID`/`RLAST` completion source and scalar last-beat
`RDATA`/`RRESP` capture.

Because validation is `report-only`, expected-beat storage, read-beat
counters, beat-count rules, and beat-count/`RLAST` assertions are not
generated. Runtime validation, multi-beat payload, write-family read-data,
same-family mixed auto-ID, group-local enqueue widening, packed outputs,
alternate burst assembly, direct backend, verification-output generation,
VHDL, and backend-language variants remain deferred behind separate owned
leaves.
