---
id: ial2-two-dynamic-one-static-read-rlast-read-data-runtime-validation-readiness
title: Two-dynamic/one-static mixed read RLAST read-data runtime-validation readiness audited
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.354 decide?"
  - "is runtime validation over two-dynamic-plus-static mixed read RLAST read-data ready?"
  - "which sample is planned for two-dynamic-plus-static mixed read RLAST read-data runtime validation?"
  - "what comes after two-dynamic-plus-static mixed read RLAST read-data burst-length?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, read-response-demux, rlast, burst-length, runtime-validation, readiness]
evidence: >-
  docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md;
  docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.354|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.355|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT|multi_dynamic_burst_last_read_data_burst_length_runtime_assertion|mixed_dynamic_static_read_data_multi_dynamic_burst_length_runtime_assertion|response_demux_matched_read_beat' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.354` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.355`, direct bounded implementation of
runtime beat-count/`RLAST` validation over generated
two-dynamic-plus-one-static mixed dynamic/static raw-`ARLEN` scalar last-beat
read-data.

The selected public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion.ppif
```

The audit found the runtime-validation machinery is already
transaction-list driven. Once the multiple mixed last-beat read-data coverage
branch admits `validation runtime-assertion` for exactly `r0`/`r1` dynamic
reads plus static `r2`, normalization can attach expected-beat storage,
read-beat counters, request-time initialization, raw matched-read-beat
increment rules, and four beat-count/`RLAST` assertions per transaction while
scalar data/status capture remains guarded by the generated `RID && RLAST`
completion pulses.
