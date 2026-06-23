---
id: ial2-multiple-mixed-dynamic-static-read-data-burst-length-behavior
title: Multiple mixed dynamic/static read-data burst-length behavior ships report-only ARLEN capture
answers:
  - "does multiple mixed dynamic/static read-data burst-length capture work?"
  - "which PPIF sample covers multiple mixed dynamic/static read-data burst-length?"
  - "does multiple mixed dynamic/static report-only ARLEN emit runtime beat counters?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.310 ship?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, burst-length, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.310|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR|multi_static_burst_last_read_data_burst_length|generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse|generated_burst_length_storage|burst_length_validation' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md docs/REGRESSION_CORPUS.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.310` ships generated report-only
raw-`ARLEN` burst-length capture over generated multiple mixed dynamic/static
read burst-last response-demux and scalar last-beat read-data.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length.ppif
```

The generated behavior covers ordered transactions `r0`, `r1`, and `r2`,
adds generated `axi0_arlen` input, per-transaction raw ARLEN storage
`axi0_r0_arlen_q`, `axi0_r1_arlen_q`, `axi0_r2_arlen_q`, and request-guarded
capture rules for each transaction. It reports
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`
as completion validity and keeps runtime beat-count/`RLAST` validation
deferred.
