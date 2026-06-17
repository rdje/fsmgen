---
id: ial2-axi-manager-read-burst-last-depth3-runtime-validation-behavior
title: Read burst-last depth-3 queue-head runtime validation ships for one raw-ARLEN group
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.165 ship?"
  - "does read burst-last depth-3 queue-head runtime validation generate beat counters?"
  - "what is the next IAL2 frontier after depth-3 runtime-validation behavior?"
date: 2026-06-17
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3, runtime-validation, burst-length]
evidence: docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif; ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.165|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.166|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.167|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.168|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.169|READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR|READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT|READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR|runtime beat-count|beat_count_match_source|multi_beat_read_data_reassembly|axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion|axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data' docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.165` shipped generated runtime
beat-count/`RLAST` validation over exactly one read burst-last depth-3
queue-head group with raw-`ARLEN` burst-length metadata.

The public support-accounted sample is
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif`.
It covers `r0`/`r1`/`r2` sharing concrete `RID` `3`, computed queue depth `3`,
`response-scope burst-last`, scalar last-beat `RDATA`/`RRESP` capture, and
`burst-length` source `arlen` with `validation runtime-assertion`.

Generated artifacts include `axi0_arlen`, raw `ARLEN` storage for all three
transactions, expected-beat storage, read-beat counters, beat-count init and
matched-read-beat increment rules, and four beat-count/`RLAST` assertions per
transaction. The report records
`beat_count_match_source: response_demux_matched_read_beat`; `read_data`
residue keeps `multi_beat_read_data_reassembly`, `per_beat_outputs`, and
`rresp_aggregation`, while `generated_beat_count_validation` is removed for
this shape.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.166` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.167`, readiness audit for generated
multi-beat output-bank behavior over this depth-3 runtime-validation shape.
`.167` completed that audit and selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.168`, direct bounded implementation over
the same `r0`/`r1`/`r2` group. `.168` shipped the multi-beat output-bank
sample
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif`
and advanced the active frontier to `.169`, the next selector/audit. Write
depth-3, multiple or mixed depth-3 groups, mixed auto-ID, group-local enqueue
widening, packed outputs, alternate burst assembly, direct backend,
verification-output generation, and VHDL remain deferred behind future owned
leaves.
