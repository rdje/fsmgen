---
id: ial2-multiple-mixed-dynamic-static-read-data-burst-length-readiness
title: Multiple mixed dynamic/static read-data burst-length audit selects direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.309 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.310?"
  - "is multiple mixed dynamic/static raw ARLEN burst-length capture ready?"
  - "which sample should cover multiple mixed dynamic/static burst-length read-data?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, burst-length, readiness]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.309|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.310|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_READINESS_AUDIT|multi_static_burst_last_read_data_burst_length|generated report-only raw-`?ARLEN`?' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.309` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.310`, direct bounded implementation of
report-only raw-`ARLEN` burst-length capture over generated multiple mixed
dynamic/static read burst-last response-demux and scalar last-beat read-data.

The selected public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length.ppif
```

The audit found the generic burst-length machinery is already
transaction-list driven. Once the multiple mixed read-data coverage branch
admits last-beat `validation report-only` burst metadata, normalization can
attach per-transaction raw-`ARLEN` storage and request-guarded capture rules
for `r0`, `r1`, and `r2`, while scalar data/status capture remains guarded by
the generated multiple mixed last-beat completion pulses.
