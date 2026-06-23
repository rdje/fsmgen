---
id: ial2-multiple-mixed-dynamic-static-read-data-behavior
title: Multiple mixed dynamic/static read-data behavior ships
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.307 ship?"
  - "does multiple mixed dynamic/static read-data now generate scalar capture?"
  - "which samples cover multiple mixed dynamic/static read-data behavior?"
  - "what completion validity does multiple mixed dynamic/static read-data use?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data.ppif; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.307|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR|multi_static_read_data|multi_static_burst_last_read_data|generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse|generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.307` ships generated bounded scalar
read-data capture over generated multiple mixed dynamic/static read
response-demux.

The support-accounted public samples are:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data.ppif
```

Both samples cover exactly one dynamic read transaction followed by exactly
two concrete static read transactions: `r0`, `r1`, and `r2`. Scalar read-data
consumes generated response-demux completion pulses and does not re-match raw
`RID` or `RID && RLAST`.

The single-beat completion-validity string is
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`.
The last-beat completion-validity string is
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`.
