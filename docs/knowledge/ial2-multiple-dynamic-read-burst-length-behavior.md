---
id: ial2-multiple-dynamic-read-burst-length-behavior
title: IAL2 multiple dynamic read burst-length behavior ships report-only capture
answers:
  - "does multiple dynamic read burst-length capture work?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.263?"
  - "which PPIF sample covers multiple dynamic read burst-length capture?"
  - "does FSMGen capture ARLEN for multiple dynamic read demux?"
  - "is multiple dynamic read runtime burst-length validation shipped?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, read-data, burst-length, report-only]
evidence: >-
  docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length.ppif; ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t;
  t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t
reverify: >-
  ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.263|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.264|MULTIPLE_DYNAMIC_READ_BURST_LENGTH_BEHAVIOR|MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR|dynamic_read_data_multi_burst_length|generated_burst_length_storage|runtime_assertion' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_BEHAVIOR.md docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md docs/REGRESSION_CORPUS.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md
  ROADMAP_V2.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length.ppif ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.263` ships generated report-only
raw-`ARLEN` burst-length capture over generated multiple dynamic read
burst-last response-demux and scalar last-beat read-data.

The public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length.ppif
```

FSMGen emits a shared generated `axi0_arlen` input, per-transaction raw-`ARLEN`
storage (`axi0_r0_arlen_q`, `axi0_r1_arlen_q` for the public sample), and
request-guarded burst-length capture rules for every generated all-dynamic read
transaction in the scalar last-beat read-data shape.

The report keeps `bounded_last_beat_read_data_contract`, records
`burst_length_validation: report_only`, lists generated burst-length
input/storage/rule artifacts, and keeps `generated_beat_count_validation` as
residue. Multiple dynamic runtime beat-count/`RLAST` validation now ships
under `.264`; multiple dynamic multi-beat output banks and mixed
dynamic/static demux remain later exact owners.
