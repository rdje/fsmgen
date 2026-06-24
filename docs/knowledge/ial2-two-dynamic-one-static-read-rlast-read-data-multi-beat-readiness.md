---
id: ial2-two-dynamic-one-static-read-rlast-read-data-multi-beat-readiness
title: Two-dynamic/one-static mixed read RLAST read-data multi-beat readiness selects direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.356 decide?"
  - "can two-dynamic-plus-static mixed read RLAST read-data multi-beat output banks be implemented directly?"
  - "which sample is planned for two-dynamic-plus-static mixed read RLAST read-data multi-beat output banks?"
  - "what comes after two-dynamic-plus-static runtime validation?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, read-response-demux, rlast, burst-length, runtime-validation, multi-beat, output-bank, readiness]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.356|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.357|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_MULTI_BEAT_READINESS_AUDIT|multi_dynamic_burst_last_read_data_multi_beat|mixed_dynamic_static_read_data_multi_dynamic_multi_beat|two dynamic reads plus one concrete static read|_multi_mixed_dynamic_static_read_response_demux_covers_multi_beat_boundary' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.356` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.357`, direct bounded implementation of
generated multi-beat output banks over generated two-dynamic-plus-one-static
mixed dynamic/static runtime-validation read-data.

The selected public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat.ppif
```

The audit found the public multi-beat syntax, output-bank report vocabulary,
runtime-assertion `ARLEN` metadata, and transaction-list-driven output-bank
helpers are already shipped. The implementation gap is local to admitting
`capture-scope multi-beat` for exactly `r0`/`r1` dynamic reads plus static
`r2`, and to recognizing that same boundary for response-demux residue
cleanup.

The next implementation should add the public PPIF sample, support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat`,
coverage key
`ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat_pipeline_cli`,
and focused behavior label
`mixed_dynamic_static_read_data_multi_dynamic_multi_beat`.
