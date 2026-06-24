---
id: ial2-two-dynamic-one-static-read-rlast-read-data-contract
title: Two-dynamic/one-static mixed read RLAST read-data contract selected
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.349 select?"
  - "which sample did .349 select for two-dynamic-plus-static mixed read RLAST read-data?"
  - "is two-dynamic-plus-static mixed read RLAST read-data ready for implementation?"
  - "what is the next task after two-dynamic-plus-static mixed read RLAST read-data contract selection?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, read-response-demux, rlast, contract]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.349|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_CONTRACT_SELECTION|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data|intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data|mixed_dynamic_static_read_data_multi_dynamic_last_beat|IAL2-FEATURE-COMPLETENESS-FRONTIER\.350' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.349` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.350`, direct generated behavior for scalar
last-beat read-data over the two-dynamic-plus-one-static mixed dynamic/static
read burst-last `RID`/`RLAST` response-demux.

The selected public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data.ppif`
with support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data`,
coverage key
`ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_pipeline_cli`,
and behavior label `mixed_dynamic_static_read_data_multi_dynamic_last_beat`.

The selected read-data contract is scalar last-beat only: dynamic reads
`r0`/`r1`, static read `r2`, generated `axi0_rdata`/`axi0_rresp` inputs,
`axi0_r*_last_rdata`/`axi0_r*_last_rresp` outputs, and completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`.
Raw `ARLEN`, runtime validation, multi-beat output banks, and the single-beat
read-data sibling remain future exact-owner work.
