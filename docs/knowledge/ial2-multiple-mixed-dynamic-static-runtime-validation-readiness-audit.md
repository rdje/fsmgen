---
id: ial2-multiple-mixed-dynamic-static-runtime-validation-readiness-audit
title: Multiple mixed dynamic/static runtime-validation audit selects direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.311 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.312?"
  - "can multiple mixed dynamic/static runtime beat-count validation be implemented directly?"
  - "does multiple mixed dynamic/static runtime validation need a public contract selection?"
  - "what comes after multiple mixed dynamic/static report-only burst-length?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, burst-length, runtime-validation, readiness]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.311|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.312|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT|multi_static_burst_last_read_data_burst_length_runtime_assertion|generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse|response_demux_matched_read_beat' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.311` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.312`, direct bounded implementation of
runtime beat-count/`RLAST` validation over generated multiple mixed
dynamic/static raw-`ARLEN` last-beat read-data.

The selected public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length_runtime_assertion.ppif
```

The audit found the runtime-validation machinery is already
transaction-list driven. Once the multiple mixed last-beat read-data coverage
branch admits `validation runtime-assertion`, normalization can attach
expected-beat storage, read-beat counters, request-time initialization, raw
matched-read-beat increment rules, and four beat-count/`RLAST` assertions for
`r0`, `r1`, and `r2`, while scalar data/status capture remains guarded by the
generated multiple mixed `RID && RLAST` completion pulses.
