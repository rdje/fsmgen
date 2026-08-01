---
id: ial2-multiple-mixed-dynamic-static-runtime-validation-behavior
title: Multiple mixed dynamic/static runtime validation ships
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.312 ship?"
  - "does multiple mixed dynamic/static runtime validation work?"
  - "does multiple mixed dynamic/static runtime validation emit beat counters?"
  - "which sample covers multiple mixed dynamic/static runtime validation?"
  - "how many runtime assertions does the multiple mixed dynamic/static runtime sample emit?"
  - "what comes after multiple mixed dynamic/static runtime validation?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, burst-length, runtime-validation, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length_runtime_assertion.ppif; docs/REGRESSION_CORPUS.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length_runtime_assertion.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.312|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR|multi_static_burst_last_read_data_burst_length_runtime_assertion|generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse|generated_beat_count_assertions|beat_count_validation_generated_behavior' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md docs/REGRESSION_CORPUS.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
  perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.312` ships generated runtime
beat-count/`RLAST` validation over generated multiple mixed dynamic/static
raw-`ARLEN` last-beat read-data.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length_runtime_assertion.ppif
```

FSMGen emits raw `ARLEN` storage, expected-beat storage, read-beat counters,
request-time beat-count initialization, raw matched-read-beat increment rules,
and four runtime assertions for each of `r0`, `r1`, and `r2`. The public
sample therefore reports twelve generated beat-count assertions. Scalar
`RDATA`/`RRESP` capture remains guarded by generated multiple mixed
`RID && RLAST` completion pulses.

`.312` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.313`, readiness audit for
generated multiple mixed dynamic/static multi-beat output banks over this
runtime-validation boundary.
