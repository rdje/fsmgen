---
id: ial2-two-dynamic-one-static-read-rlast-read-data-runtime-validation-behavior
title: Two-dynamic/one-static mixed read RLAST read-data runtime validation ships
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.355 ship?"
  - "is runtime validation over two-dynamic-plus-static mixed read RLAST read-data supported?"
  - "which sample covers two-dynamic-plus-static mixed read RLAST read-data runtime validation?"
  - "what remains after two-dynamic-plus-static runtime validation?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, read-response-demux, rlast, burst-length, runtime-validation, behavior]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.355|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.356|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR|multi_dynamic_burst_last_read_data_burst_length_runtime_assertion|mixed_dynamic_static_read_data_multi_dynamic_burst_length_runtime_assertion|beat_count_validation_generated_behavior|response_demux_matched_read_beat' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.355` ships generated runtime
beat-count/`RLAST` validation over generated two-dynamic-plus-one-static
mixed dynamic/static raw-`ARLEN` scalar last-beat read-data.

The public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion.ppif
```

The generated surface preserves the `.353` raw-`ARLEN` capture, `.350`
scalar last-beat `RDATA`/`RRESP` capture, and `.347` generated final
`RID && RLAST` completion pulses. It adds per-transaction expected-beat
storage, read-beat counters, request-time initialization from `ARLEN + 1`,
matched-read-beat counter increments, and four beat-count/`RLAST` assertions
for each of `r0`, `r1`, and `r2`.

Schedule JSON reports `burst_length_validation: runtime_assertion`,
`beat_count_validation_generated_behavior: true`,
`expected_beat_count_encoding: arlen_plus_one`, and
`beat_count_match_source: response_demux_matched_read_beat`. The residue
removes `generated_beat_count_validation` and keeps multi-beat reassembly,
per-beat outputs, and `RRESP` aggregation for later owners.

The next exact owner is `.356`, readiness audit for generated
two-dynamic-plus-one-static mixed dynamic/static multi-beat output banks over
this runtime-validation boundary.
