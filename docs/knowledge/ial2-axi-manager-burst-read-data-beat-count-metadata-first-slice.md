---
id: ial2-axi-manager-burst-read-data-beat-count-metadata-first-slice
title: AXI burst read-data beat-count metadata ships report-only ARLEN contracts
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.63 ship?"
  - "is burst-length parsed in PPIF?"
  - "did IAL2-FEATURE-COMPLETENESS-FRONTIER.63 generate ARLEN capture?"
  - "what is ppif/axi_manager_capacity_status_read_data_burst_length.ppif?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.63?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, read-data, burst-length, arlen, beat-count, metadata, ppif, task-tree]
evidence: docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md; ppif/axi_manager_capacity_status_read_data_burst_length.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.63|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.66|axi_manager_capacity_status_read_data_burst_length|burst_length_generated_behavior|generated_burst_length_capture|generated_beat_count_validation' docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md ppif/axi_manager_capacity_status_read_data_burst_length.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.63` shipped parser/report metadata and
static validation for optional ARLEN-based `burst-length` clauses under
last-beat `read-data`.

The checked-in sample is
`ppif/axi_manager_capacity_status_read_data_burst_length.ppif`, support
accounted as
`intent.ppif_axi_manager_capacity_status_read_data_burst_length`.

Schedule JSON reports `burst_length_source: arlen_signal`, width `8`,
`burst_length_encoding: axlen_plus_one`, `max_beats: 16`,
`burst_length_generated_behavior: false`, and `burst_length_validation:
report_only`. `axi0_arlen` is not emitted as a generated `.isf` input, `.fsm`
signal, or HDL port in this slice.

The `.64` selector chose `IAL2-FEATURE-COMPLETENESS-FRONTIER.65`, a
readiness audit before generated ARLEN burst-length capture.
Generated raw-ARLEN capture later shipped in
`IAL2-FEATURE-COMPLETENESS-FRONTIER.66`.
The `.67` audit preserved `validation report-only` as no-runtime-check
behavior and selected `.68`, public runtime-validation contract selection,
before any generated beat-count/RLAST validation behavior.
