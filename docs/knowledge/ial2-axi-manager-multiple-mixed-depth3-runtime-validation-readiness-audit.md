---
id: ial2-axi-manager-multiple-mixed-depth3-runtime-validation-readiness-audit
title: Multiple/mixed depth-3 runtime-validation audit selects direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.185 decide?"
  - "can multiple/mixed depth-3 runtime validation be implemented directly?"
  - "what comes after multiple/mixed depth-3 queue-head runtime validation audit?"
  - "is a lower-layer prerequisite needed for multiple/mixed depth-3 beat-count validation?"
date: 2026-06-18
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3, runtime-validation, readiness]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.185|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.186|MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT|read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion|read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion|beat_count_validation_generated_behavior|generated_beat_count_validation' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.185` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.186`, direct bounded implementation of
generated beat-count/`RLAST` runtime validation over multiple/mixed depth-3
read burst-last queue-head scalar last-beat read-data.

No lower-layer prerequisite was found. The remaining blocker is local to
`_read_data_response_demux_transaction_coverage`: runtime-assertion
last-beat coverage admits all-depth-2 groups and exactly one depth-3 group,
but not yet the already-shipped depth `3,3` and `3,2` report-only raw-`ARLEN`
transaction lists.

Below that gate, the runtime-validation machinery is already
transaction-list driven. It emits raw-`ARLEN` storage, expected-beat storage,
read-beat counters, request-time initialization rules, matched-read-beat
increment rules, four beat-count/`RLAST` assertions per transaction, report
fields, and removes `generated_beat_count_validation` residue for generated
runtime-validation shapes.

The selected implementation samples are:

- `ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif`
- `ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion.ppif`

Multi-beat payload, write-family read-data, same-family mixed auto-ID,
group-local enqueue widening, packed outputs, alternate burst assembly,
direct backend, verification-output generation, VHDL, and backend-language
variants remain deferred behind separate owned leaves.
