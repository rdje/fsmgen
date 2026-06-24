---
id: ial2-three-static-mixed-dynamic-static-runtime-validation-behavior
title: Three-static mixed read-data runtime validation behavior ships
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.335 ship?"
  - "does three-static mixed read-data runtime validation work?"
  - "which PPIF sample covers three-static mixed read-data runtime validation?"
  - "how many assertions does three-static mixed runtime validation generate?"
  - "what remains after three-static mixed read-data runtime validation?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, burst-length, runtime-validation, behavior]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length_runtime_assertion.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env FSMGEN_DYNAMIC_CASE_FILTER=mixed_dynamic_static_read_data_multi_static3_burst_length_runtime_assertion FSMGEN_DYNAMIC_SKIP_CLI_JSON=1 prove -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.335` ships generated runtime
beat-count/`RLAST` validation over generated one-dynamic plus
three-concrete-static mixed dynamic/static raw-`ARLEN` last-beat read-data.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length_runtime_assertion.ppif
```

The generated behavior covers ordered transactions `r0`, `r1`, `r2`, and
`r3`; adds per-transaction raw `ARLEN`, expected-beat, and read-beat-count
storage; emits request-time expected-count initialization and matched-beat
counting rules; and reports four runtime assertions per transaction, sixteen
assertions total. Three-static multi-beat output banks remain deferred.
