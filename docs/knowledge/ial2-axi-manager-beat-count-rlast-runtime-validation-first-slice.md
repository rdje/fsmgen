---
id: ial2-axi-manager-beat-count-rlast-runtime-validation-first-slice
title: AXI beat-count/RLAST runtime validation ships generated assertions
answers:
  - "does validation runtime-assertion generate AXI beat-count checks?"
  - "does AXI read-data burst-length runtime assertion generate HDL?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.69 ship?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.69?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.70?"
  - "what is ppif/axi_manager_capacity_status_read_data_burst_length_runtime_assertion.ppif?"
  - "does validation report-only generate runtime checks now?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, burst-length, arlen, rlast, beat-count, validation, runtime-assertion, behavior, task-tree]
evidence: docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION.md; ppif/axi_manager_capacity_status_read_data_burst_length_runtime_assertion.ppif; ppif/axi_manager_capacity_status_read_data_burst_length.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.69` ships generated beat-count and
`RLAST` runtime validation for explicit last-beat AXI read-data
`burst-length` contracts that use `(validation runtime-assertion)`.

The public runtime fixture is
`ppif/axi_manager_capacity_status_read_data_burst_length_runtime_assertion.ppif`.
It parses through `.ppif`, strict check JSON, normalized semantic JSON, and
`--verify-hdl`.

The generated behavior adds per-read-transaction expected-beat storage,
matched-read-beat counters, request-time initialization rules, matched-beat
increment rules, and runtime assertions for ARLEN bounds, extra beats, early
`RLAST`, and missing final `RLAST`.

Schedule JSON reports `burst_length_validation: runtime_assertion`,
`beat_count_validation_generated_behavior: true`,
`expected_beat_count_encoding: arlen_plus_one`,
`beat_count_match_source: response_demux_matched_read_beat`, generated
expected-count storage, generated beat-count storage/rules, and generated
assertion names. Runtime-validation residue removes
`generated_beat_count_validation` and keeps multi-beat reassembly, per-beat
outputs, and `RRESP` aggregation deferred.

Existing `(validation report-only)` still generates no beat-count/RLAST
runtime checks and keeps `generated_beat_count_validation` in read-data
residue.

The next selected leaf after `.69` was
`IAL2-FEATURE-COMPLETENESS-FRONTIER.70`, a selector for the next exact AXI
manager feature-completeness owner after generated beat-count/RLAST runtime
validation. That selector has since selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.71`, public AXI multi-beat read-data
reassembly/output contract selection.
