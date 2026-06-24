---
id: ial2-three-static-mixed-dynamic-static-read-data-burst-length-behavior
title: Three-static mixed read-data burst-length behavior ships report-only ARLEN capture
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.333 ship?"
  - "does three-static mixed read-data support report-only raw ARLEN?"
  - "which PPIF sample covers three-static mixed read-data burst-length?"
  - "does three-static mixed report-only ARLEN emit runtime beat counters?"
  - "what remains after three-static mixed read-data burst-length behavior?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, burst-length, behavior]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env FSMGEN_DYNAMIC_CASE_FILTER=mixed_dynamic_static_read_data_multi_static3_burst_length FSMGEN_DYNAMIC_SKIP_CLI_JSON=1 prove -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.333` ships generated report-only
raw-`ARLEN` burst-length capture over generated one-dynamic plus
three-concrete-static mixed dynamic/static read burst-last response-demux and
scalar last-beat read-data.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length.ppif
```

The generated behavior covers ordered transactions `r0`, `r1`, `r2`, and
`r3`, adds generated `axi0_arlen` input, per-transaction raw ARLEN storage
`axi0_r0_arlen_q` through `axi0_r3_arlen_q`, and request-guarded capture
rules for each transaction. It reports
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`
as completion validity and keeps runtime beat-count/`RLAST` validation and
multi-beat output banks deferred.
