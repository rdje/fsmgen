---
id: ial2-multiple-dynamic-read-burst-length-runtime-behavior
title: IAL2 multiple dynamic read burst-length runtime validation ships
answers:
  - "does multiple dynamic read runtime burst-length validation work?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.264?"
  - "which PPIF sample covers multiple dynamic read runtime burst-length validation?"
  - "does FSMGen generate beat-count assertions for multiple dynamic read demux?"
  - "does multiple dynamic read runtime validation remove generated beat-count residue?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, read-data, burst-length, runtime-validation]
evidence: >-
  docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t;
  t/248-regression-corpus-accounting.t
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.264|MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR|dynamic_read_data_multi_burst_length_runtime_assertion|generated_beat_count_storage|generated_beat_count_assertions|runtime_assertion' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md docs/REGRESSION_CORPUS.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.264` ships generated runtime
beat-count/`RLAST` validation over generated multiple dynamic read burst-last
response-demux and scalar last-beat read-data.

The public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif
```

FSMGen emits per-transaction raw-`ARLEN` storage, expected-beat storage,
read-beat counter storage, request-time expected-count initialization,
matched-read-beat counter increments, and four runtime assertions per covered
all-dynamic read transaction.

The report records `burst_length_validation: runtime_assertion`,
`beat_count_validation_generated_behavior: true`,
`expected_beat_count_encoding: arlen_plus_one`, and
`beat_count_match_source: response_demux_matched_read_beat`; it removes
`generated_beat_count_validation` from read-data residue while leaving
multi-beat output-bank residue for later owners.
