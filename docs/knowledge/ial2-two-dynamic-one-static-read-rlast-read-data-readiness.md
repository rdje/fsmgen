---
id: ial2-two-dynamic-one-static-read-rlast-read-data-readiness
title: Two-dynamic/one-static mixed read RLAST read-data readiness audited
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.348 decide?"
  - "is scalar read-data over two-dynamic-plus-static mixed read RLAST demux ready?"
  - "which sample is planned for two-dynamic-plus-static mixed read RLAST read-data?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, read-response-demux, rlast, readiness]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.348|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_READINESS_AUDIT|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data|mixed_dynamic_static_read_data_multi_dynamic_last_beat|generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.348` audits scalar last-beat read-data over
the `.347` two-dynamic-plus-one-static mixed dynamic/static read burst-last
`RID`/`RLAST` response-demux and selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.349`,
public contract selection, as the next exact owner.

The planned public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data.ppif`
with support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data`
and focused behavior label `mixed_dynamic_static_read_data_multi_dynamic_last_beat`.

A scratch guarded strict-check probe reached the local read-data transaction
coverage gate and failed closed because current multiple mixed dynamic/static
read-data coverage still requires one dynamic plus two static reads, or the
selected one-dynamic plus three-static variants. The audit changed no behavior.
