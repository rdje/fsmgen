---
id: ial2-post-two-dynamic-one-static-read-data-multi-beat-next-slice-selection
title: Post two-dynamic/one-static read-data multi-beat selector chooses single-beat read-data audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.358 select?"
  - "what comes after two-dynamic-plus-static mixed read-data multi-beat output banks?"
  - "why is single-beat read-data over .344 next?"
  - "which sample may cover two-dynamic-plus-static mixed read single-beat read-data?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, read-response-demux, single-beat, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.358|IAL2-FEATURE-COMPLETENESS-FRONTIER\.359|POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION|multi_dynamic_read_data|mixed_dynamic_static_read_data_multi_dynamic|generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse|single-beat read-data over the already shipped .344' docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.358` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.359`, readiness audit for scalar
single-beat read-data over the `.344` generated two-dynamic-plus-one-static
mixed dynamic/static read single-beat `RID` response-demux.

The candidate later public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif
```

The candidate support identity is
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data`,
the candidate coverage key is
`ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data_pipeline_cli`,
and the candidate focused behavior label is
`mixed_dynamic_static_read_data_multi_dynamic`.

The reason for choosing an audit first is that the `.357` chain completed the
two-dynamic-plus-one-static burst-last read-data branch through multi-beat
output banks, while the `.344` single-beat demux still lacks its scalar
single-beat read-data sibling. The current coverage gate admits the same
transaction set for last-beat, raw-`ARLEN`, runtime-validation, and
multi-beat output-bank paths, but not yet for scalar single-beat capture.
