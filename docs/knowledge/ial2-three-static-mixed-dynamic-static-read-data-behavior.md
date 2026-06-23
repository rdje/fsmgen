---
id: ial2-three-static-mixed-dynamic-static-read-data-behavior
title: Three-static mixed read-data behavior ships
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.330 ship?"
  - "does AXI IAL2 support one dynamic plus three static mixed read-data?"
  - "is three-static mixed dynamic/static read-data implemented?"
  - "which samples cover three-static mixed read-data behavior?"
  - "which three-static mixed read-data shapes remain fail-closed?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read, read-data, behavior]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_read_data.ppif; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env FSMGEN_DYNAMIC_CASE_FILTER=read_data_multi_static3 FSMGEN_DYNAMIC_SKIP_CLI_JSON=1 prove -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.330` ships generated scalar read-data
capture over generated one-dynamic plus three-concrete-static mixed
dynamic/static read response-demux.

The support-accounted public samples are:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_read_data.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data.ppif
```

The shipped boundary covers dynamic read `r0` plus concrete static reads
`r1`, `r2`, and `r3` with concrete IDs `3`, `5`, and `7`. Single-beat
capture reports completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`;
last-beat capture reports
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`.
Both reports list `r0`, `r1`, `r2`, and `r3`, generated completion signals
`axi0_r0_complete` through `axi0_r3_complete`, and generated capture rules
`axi0_r0_read_data_capture` through `axi0_r3_read_data_capture`.

Three-static raw `ARLEN` burst-length capture, runtime beat-count/`RLAST`
validation, and multi-beat output banks remain fail-closed. The existing
one-static and two-static mixed read-data owners remain unchanged.
