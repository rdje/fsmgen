---
id: ial2-two-dynamic-one-static-read-rlast-read-data-behavior
title: Two-dynamic/one-static mixed read RLAST read-data shipped
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.350 ship?"
  - "is two-dynamic-plus-static mixed read RLAST read-data implemented?"
  - "which sample implements two-dynamic-plus-static mixed read RLAST read-data?"
  - "what is the next task after two-dynamic-plus-static mixed read RLAST read-data?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, read-response-demux, rlast, behavior]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.350|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BEHAVIOR|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data|intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data|mixed_dynamic_static_read_data_multi_dynamic_last_beat|IAL2-FEATURE-COMPLETENESS-FRONTIER\.351' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
  t/248-regression-corpus-accounting.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.350` ships scalar last-beat read-data over
the generated two-dynamic-plus-one-static mixed dynamic/static read burst-last
`RID`/`RLAST` response-demux.

The implemented public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data.ppif`
with support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data`,
coverage key
`ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_pipeline_cli`,
and behavior label `mixed_dynamic_static_read_data_multi_dynamic_last_beat`.

The generated read-data surface adds `axi0_rdata`/`axi0_rresp` inputs,
`axi0_r0_last_rdata`/`axi0_r0_last_rresp`,
`axi0_r1_last_rdata`/`axi0_r1_last_rresp`, and
`axi0_r2_last_rdata`/`axi0_r2_last_rresp` outputs, with capture rules
`axi0_r0_read_data_capture`, `axi0_r1_read_data_capture`, and
`axi0_r2_read_data_capture` guarded by the generated final-beat completion
pulses. The next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.351`, report-only
raw-`ARLEN` burst-length readiness selection over this boundary.
