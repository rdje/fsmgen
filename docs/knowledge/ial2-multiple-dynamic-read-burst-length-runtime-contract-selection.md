---
id: ial2-multiple-dynamic-read-burst-length-runtime-contract-selection
title: IAL2 multiple dynamic read burst-length runtime contract splits implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.262 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.262?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.263?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.264?"
  - "does multiple dynamic burst-length runtime ship together?"
  - "what sample names were selected for multiple dynamic burst-length runtime?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, read-data, burst-length, runtime-validation, selector]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.262|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.263|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.264|MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_CONTRACT_SELECTION|MULTIPLE_DYNAMIC_READ_BURST_LENGTH_BEHAVIOR|MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR|dynamic_read_data_multi_burst_length|dynamic_read_data_multi_burst_length_runtime_assertion' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_CONTRACT_SELECTION.md docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_BEHAVIOR.md docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.262` selected a split implementation for
bounded burst-length/runtime validation over generated multiple dynamic read
response-demux.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.263` was the report-only implementation
owner and now ships direct generated report-only raw-`ARLEN` burst-length
capture over the `.259` scalar last-beat multiple dynamic read-data shape.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.264` now ships the runtime
beat-count/`RLAST` assertion sibling after `.263`.

The selected public PPIF sample names are:

```text
ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length.ppif
ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif
```

Both shapes require generated dynamic burst-last read response-demux, two or
more all-dynamic read transactions, scalar last-beat read-data with complete
transaction coverage, and one family-level width-8 `ARLEN` signal captured per
transaction at that transaction's request event. Single-beat burst-length,
multiple dynamic multi-beat output banks, mixed dynamic/static demux,
same-cycle widening, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain later exact owners.

The `.262` selector changed no parser, generator, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check or semantic JSON, or HDL behavior. The split contract is now
implemented by `.263` for report-only capture and `.264` for runtime
beat-count/`RLAST` validation.
