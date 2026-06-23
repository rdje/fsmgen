---
id: ial2-multiple-mixed-dynamic-static-read-data-contract-selection
title: Multiple mixed dynamic/static read-data contract selects implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.306 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.307?"
  - "what is the public contract for multiple mixed dynamic/static scalar read-data?"
  - "which PPIF samples should cover multiple mixed dynamic/static read-data?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, contract]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_CONTRACT_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.306|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.307|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION|multi_static_read_data|generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse|generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.306` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.307`, direct generated behavior for
bounded scalar read-data over generated multiple mixed dynamic/static read
response-demux.

The selected public samples are:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data.ppif
```

The contract covers exactly one dynamic read transaction and exactly two
pairwise-distinct concrete static read transactions. The covered read-data
transaction order is dynamic transactions followed by static transactions:
`r0, r1, r2`. Scalar read-data consumes generated response-demux completion
pulses and does not re-match raw `RID` or `RID && RLAST`. The selected
completion-validity strings are
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`
and
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`.
