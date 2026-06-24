---
id: ial2-two-dynamic-one-static-read-single-beat-read-data-contract
title: Two-dynamic/one-static mixed read single-beat read-data contract selected
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.360 select?"
  - "which sample should implement two-dynamic-plus-static mixed read single-beat read-data?"
  - "what is the public contract for scalar read-data over .344?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.361?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, read-response-demux, single-beat, contract-selection]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.360|IAL2-FEATURE-COMPLETENESS-FRONTIER\.361|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data|mixed_dynamic_static_read_data_multi_dynamic|generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse|bounded_single_beat_read_data_contract' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.360` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.361`, direct generated behavior for
bounded scalar single-beat read-data over the `.344` generated
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
response-demux.

The selected public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif
```

The selected support identity is
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data`,
the coverage key is
`ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data_pipeline_cli`,
and the focused behavior label is
`mixed_dynamic_static_read_data_multi_dynamic`.

The selected report contract keeps `.344` response-demux mode
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`, read-data mode
`bounded_single_beat_read_data_contract`, completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`,
ordered transactions `r0, r1, r2`, generated inputs `axi0_rdata` and
`axi0_rresp`, scalar outputs `axi0_r0_rdata`/`axi0_r0_rresp` through
`axi0_r2_rdata`/`axi0_r2_rresp`, capture rules
`axi0_r0_read_data_capture` through `axi0_r2_read_data_capture`, and
read-data residue `rlast_completion, bursts, multi_beat_read_data_reassembly`.

