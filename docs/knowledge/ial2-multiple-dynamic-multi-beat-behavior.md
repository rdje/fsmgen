---
id: ial2-multiple-dynamic-multi-beat-behavior
title: IAL2 multiple dynamic multi-beat output banks ship
answers:
  - "does multiple dynamic multi-beat read-data output-bank behavior work?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.268?"
  - "which PPIF sample covers multiple dynamic multi-beat output banks?"
  - "does FSMGen generate output banks for multiple dynamic read transactions?"
  - "does multiple dynamic multi-beat read-data remove read-data residue?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, read-data, multi-beat, output-bank]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; ppif/axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat.ppif; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.268|MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR|dynamic_read_data_multi_transaction_multi_beat|bounded_multi_beat_read_data_contract|multi_beat_reassembly_generated_behavior' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR.md docs/REGRESSION_CORPUS.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm ppif/axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.268` ships generated bounded multiple
dynamic multi-beat read-data output-bank behavior over generated multiple
dynamic read burst-last response-demux and runtime beat-count/`RLAST`
validation.

The public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat.ppif
```

FSMGen emits per-transaction output-bank initialization, per-beat `RDATA` and
`RRESP` lanes, valid masks, length outputs, worst-observed scalar `RRESP`
aggregates, raw matched-beat lane capture, request-captured `ARLEN`, expected
beat state, read-beat counters, and four runtime assertions per covered
all-dynamic read transaction.

The report records `read_data.mode: bounded_multi_beat_read_data_contract`,
`completion_validity:
generated_dynamic_read_response_demux_last_beat_completion_pulse`,
`status_aggregation_generated_behavior: true`,
`multi_beat_reassembly_generated_behavior: true`, and empty read-data
residue for the supported sample. Response-demux residue still keeps
`same_id_ordering`; mixed dynamic/static demux, same-cycle widening,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL remain later exact owners.
