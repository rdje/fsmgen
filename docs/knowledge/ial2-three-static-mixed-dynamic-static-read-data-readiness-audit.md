---
id: ial2-three-static-mixed-dynamic-static-read-data-readiness-audit
title: Three-static mixed read-data readiness selects contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.328 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.329?"
  - "is three-static mixed dynamic/static read-data ready?"
  - "why select a contract before three-static mixed read-data implementation?"
  - "which PPIF samples should cover three-static mixed read-data?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read, read-data, readiness]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.328|IAL2-FEATURE-COMPLETENESS-FRONTIER\.329|THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT|multi_static3_read_data|multi_static3_burst_last_read_data|generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse' docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.328` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.329`, public contract selection for
bounded scalar read-data over generated one-dynamic plus
three-concrete-static mixed dynamic/static read response-demux.

The audit found that scalar read-data helper code is already transaction-list
driven after coverage admission, but the current multiple mixed
dynamic/static read-data coverage branch still requires exactly one dynamic
read transaction and exactly two concrete static read transactions. A public
contract selector should lock sample names, support identities, transaction
order `r0, r1, r2, r3`, completion-validity vocabulary, diagnostics,
validation, docs, and residue before implementation.

The likely public sample stems are:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_read_data.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data.ppif
```
