---
id: ial2-two-dynamic-one-static-read-rlast-read-data-burst-length-readiness
title: Two-dynamic/one-static mixed read RLAST read-data burst-length readiness audited
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.352 decide?"
  - "is report-only raw-ARLEN over two-dynamic-plus-static mixed read RLAST read-data ready?"
  - "which sample is planned for two-dynamic-plus-static mixed read RLAST read-data burst-length?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, read-response-demux, rlast, burst-length, readiness]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.352|IAL2-FEATURE-COMPLETENESS-FRONTIER\.353|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BURST_LENGTH_READINESS_AUDIT|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length|mixed_dynamic_static_read_data_multi_dynamic_burst_length|two-dynamic-plus-one-static report-only raw-ARLEN' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.352` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.353`, direct bounded implementation of
report-only raw-`ARLEN` burst-length capture over the shipped
two-dynamic-plus-one-static mixed dynamic/static read burst-last scalar
last-beat read-data boundary.

The planned public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length.ppif`
with support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length`,
coverage key
`ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_pipeline_cli`,
and behavior label `mixed_dynamic_static_read_data_multi_dynamic_burst_length`.

The audit changed no behavior; `.353` owns the implementation outcome.
