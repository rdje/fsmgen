---
id: ial2-axi-manager-read-burst-last-depth3-multi-beat-read-data-behavior
title: Read burst-last depth-3 queue-head multi-beat read-data output banks ship
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.168 ship?"
  - "does read burst-last depth-3 queue-head multi-beat read-data generate output banks?"
  - "what PPIF sample covers depth-3 queue-head multi-beat read-data?"
  - "what is the next IAL2 frontier after depth-3 multi-beat output-bank behavior?"
date: 2026-06-17
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3, multi-beat, output-bank]
evidence: docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.168|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.169|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.170|READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR|POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION|axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data|per_beat_output_bank|generated_multi_beat_capture_rules|read_data.residue' docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.168` shipped generated multi-beat
read-data output-bank behavior over exactly one read burst-last depth-3
queue-head runtime-validation group.

The public support-accounted sample is
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif`.
It covers `r0`/`r1`/`r2` sharing concrete `RID` `3`, computed queue depth `3`,
`response-scope burst-last`, `capture-scope multi-beat`, per-beat status,
worst-observed `RRESP` aggregation, multi-beat-by-RID interleaving, and
runtime-assertion `ARLEN` burst-length metadata.

Generated artifacts include per-transaction output-bank clearing, 16 `RDATA`
lanes and 16 `RRESP` lanes per transaction, 48 generated lane capture rules,
valid-mask outputs, read-length outputs, scalar worst-observed `RRESP`
aggregate outputs, raw `ARLEN` capture, expected-beat storage, read-beat
counters, beat-count rules, and beat-count/`RLAST` assertions. Schedule JSON
reports `read_data.mode: bounded_multi_beat_read_data_contract`,
`output_shape: per_beat_output_bank`, `beat_count_match_source:
response_demux_matched_read_beat`, empty `read_data.residue`, and empty
`response_demux.residue` for the covered sample.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.169` selected the next IAL2 frontier:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.170`, readiness audit for generated
write-family depth-3 concrete same-ID queue-head response-demux. Multiple or
mixed depth-3 groups, mixed auto-ID, group-local enqueue widening, packed
burst-vector outputs, alternate burst assembly, direct backend,
verification-output generation, VHDL, and backend-language variants remain
deferred behind future owned leaves.
