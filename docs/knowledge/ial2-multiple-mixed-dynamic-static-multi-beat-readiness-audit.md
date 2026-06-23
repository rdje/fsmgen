---
id: ial2-multiple-mixed-dynamic-static-multi-beat-readiness-audit
title: Multiple mixed dynamic/static multi-beat audit selects direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.313 select?"
  - "can multiple mixed dynamic/static multi-beat output banks be implemented directly?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.314?"
  - "which sample should cover multiple mixed dynamic/static multi-beat output banks?"
  - "what follows the .313 multiple mixed dynamic/static multi-beat readiness audit?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, multi-beat, readiness]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.313|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.314|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT|multi_static_burst_last_read_data_multi_beat|generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse|bounded_multi_beat_read_data_contract' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-multiple-mixed-dynamic-static-multi-beat-readiness-audit.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.313` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.314`, direct bounded implementation of
generated multiple mixed dynamic/static multi-beat output banks over the
generated multiple mixed runtime-validation boundary.

The selected public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_multi_beat.ppif
```

The audit found the public multi-beat syntax, output-bank report vocabulary,
runtime-assertion `ARLEN` metadata, and transaction-list-driven output-bank
helpers are already present. The `.314` implementation should admit only the
exact one-dynamic plus two-static generated burst-last demux shape, add
multiple mixed multi-beat residue recognition, and preserve broader mixed
cardinalities and backend variants as later exact owners.
