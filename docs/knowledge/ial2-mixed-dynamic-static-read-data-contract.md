---
id: ial2-mixed-dynamic-static-read-data-contract
title: Mixed dynamic/static read-data contract selects implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.283 select?"
  - "what is the selected public contract for mixed dynamic/static read-data over generated read demux?"
  - "what samples should implement mixed dynamic/static scalar read-data over read response-demux?"
  - "what completion validity strings should mixed dynamic/static read-data use?"
  - "what remains residue after the mixed dynamic/static read-data contract selection?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, contract-selection]
answer: "IAL2-FEATURE-COMPLETENESS-FRONTIER.283 selected .284, direct generated behavior for bounded scalar read-data over generated mixed dynamic/static read response-demux. The selected future public samples are ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif and ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif. Read-data coverage must consume generated_mixed_dynamic_static_read_demux or generated_mixed_dynamic_static_read_demux_last_beat completion sources, cover the ordered dynamic transaction list followed by the ordered static transaction list exactly once, and report generated_mixed_dynamic_static_read_response_demux_completion_pulse or generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse. Burst-length/runtime validation, multi-beat output banks, multiple mixed transactions, same-cycle widening, queues, scoreboards, direct backend behavior, backend-language variants, and VHDL remain future owners."
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.283|IAL2-FEATURE-COMPLETENESS-FRONTIER\.284|AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data|generated_mixed_dynamic_static_read_response_demux_completion_pulse|generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse|No parser, generator, PPIF sample, support-accounting catalog, validation behavior, generated artifact, test, schedule/check/semantic JSON, or HDL behavior changed' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.283` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.284`, direct generated behavior for
bounded scalar read-data over generated mixed dynamic/static read
response-demux.

The selected future samples are:

- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif`
- `ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif`

The selected completion-validity strings are:

- `generated_mixed_dynamic_static_read_response_demux_completion_pulse`
- `generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`

The selector changes no parser, generator, sample, support-accounting catalog,
validation behavior, generated artifact, test, JSON, or HDL behavior.
