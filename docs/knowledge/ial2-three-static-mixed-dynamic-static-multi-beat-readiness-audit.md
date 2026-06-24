---
id: ial2-three-static-mixed-dynamic-static-multi-beat-readiness-audit
title: Three-static mixed read-data multi-beat audit selects direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.336 select?"
  - "can three-static mixed dynamic/static multi-beat output banks be implemented directly?"
  - "which sample should cover three-static mixed dynamic/static multi-beat output banks?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.337?"
  - "what remains after the three-static mixed runtime-validation audit?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, multi-beat, readiness]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.336|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.337|THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT|multi_static3_burst_last_read_data_multi_beat|mixed_dynamic_static_read_data_multi_static3_multi_beat' docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-three-static-mixed-dynamic-static-multi-beat-readiness-audit.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.336` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.337`, direct bounded implementation of
generated multi-beat output banks over the generated one-dynamic plus
three-concrete-static mixed dynamic/static runtime-validation read-data
boundary.

The selected public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_multi_beat.ppif
```

The audit found the public multi-beat syntax, output-bank report vocabulary,
runtime-assertion `ARLEN` metadata, and transaction-list-driven output-bank
helpers are already present. The `.337` implementation should admit only the
exact one-dynamic plus three-static generated burst-last demux shape, extend
multi-mixed multi-beat residue recognition to that cardinality, and preserve
two-dynamic-plus-static shapes, broader mixed cardinalities, queues,
scoreboards, backend variants, and VHDL as later exact owners.
