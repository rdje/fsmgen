---
id: ial2-two-dynamic-one-static-read-single-beat-read-data-readiness
title: Two-dynamic/one-static mixed read single-beat read-data readiness selects contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.359 decide?"
  - "is scalar single-beat read-data over .344 ready for implementation?"
  - "which sample is planned for two-dynamic-plus-static mixed read single-beat read-data?"
  - "why does two-dynamic-plus-static single-beat read-data need contract selection?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, read-response-demux, single-beat, readiness]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.359|IAL2-FEATURE-COMPLETENESS-FRONTIER\.360|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT|multi_dynamic_read_data|mixed_dynamic_static_read_data_multi_dynamic|generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse|bounded_single_beat_read_data_contract' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.359` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.360`, public contract selection for
scalar single-beat read-data over the `.344` generated
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
response-demux.

The selected candidate public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif
```

The candidate support identity is
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data`,
the candidate coverage key is
`ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data_pipeline_cli`,
and the candidate focused behavior label is
`mixed_dynamic_static_read_data_multi_dynamic`.

The audit found the current coverage gate already supports the
two-dynamic-plus-one-static set for last-beat, raw-`ARLEN`, runtime, and
multi-beat output-bank paths, but still fails closed for scalar single-beat
capture over `.344`. Contract selection should settle the exact public shape
before any behavior widening.
