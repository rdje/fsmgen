---
id: ial2-two-dynamic-one-static-read-rlast-read-data-burst-length-behavior
title: Two-dynamic/one-static mixed read RLAST read-data burst-length shipped
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.353 ship?"
  - "is two-dynamic-plus-static mixed read RLAST read-data burst-length implemented?"
  - "which sample implements two-dynamic-plus-static mixed read RLAST read-data burst-length?"
  - "what is the next task after two-dynamic-plus-static mixed read RLAST read-data burst-length?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, read-response-demux, rlast, burst-length, behavior]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BURST_LENGTH_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.353|IAL2-FEATURE-COMPLETENESS-FRONTIER\.354|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BURST_LENGTH_BEHAVIOR|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length|mixed_dynamic_static_read_data_multi_dynamic_burst_length|generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BURST_LENGTH_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.353` ships generated report-only
raw-`ARLEN` burst-length capture over generated two-dynamic-plus-one-static
mixed dynamic/static read burst-last response-demux and scalar last-beat
read-data.

The public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length.ppif`
with support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length`,
coverage key
`ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_pipeline_cli`,
and behavior label `mixed_dynamic_static_read_data_multi_dynamic_burst_length`.

The generated behavior adds `axi0_arlen`, per-transaction raw-`ARLEN` storage
and request-guarded capture rules for `r0`, `r1`, and `r2`, while keeping
runtime beat-count/`RLAST` validation and multi-beat output banks as explicit
future exact owners. The next task is `IAL2-FEATURE-COMPLETENESS-FRONTIER.354`,
runtime-validation readiness over this shipped boundary.
