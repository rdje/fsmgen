---
id: ial2-dynamic-burst-length-behavior
title: Dynamic read-data report-only burst-length capture is generated
answers:
  - "does dynamic read-data burst-length capture work?"
  - "which dynamic burst-length PPIF sample is supported?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.238 ship?"
  - "is dynamic burst-length runtime validation supported?"
  - "what follows dynamic burst-length behavior?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-data, burst-length, arlen, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; ppif/axi_manager_capacity_status_dynamic_read_data_burst_length.ppif; ppif/axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion.ppif; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.238|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.240|DYNAMIC_BURST_LENGTH_BEHAVIOR|DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR|axi_manager_capacity_status_dynamic_read_data_burst_length|axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion|generated_dynamic_read_response_demux_last_beat_completion_pulse|generated_burst_length_inputs|dynamic runtime beat-count' docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_BEHAVIOR.md docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm ppif/axi_manager_capacity_status_dynamic_read_data_burst_length.ppif ppif/axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion.ppif t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.238` ships generated report-only
raw-`ARLEN` burst-length capture for exactly one dynamic read transaction
using generated dynamic burst-last/`RLAST` response demux plus scalar
last-beat dynamic read-data capture.

The supported public PPIF sample is
`ppif/axi_manager_capacity_status_dynamic_read_data_burst_length.ppif`, with
support-accounting entry
`intent.ppif_axi_manager_capacity_status_dynamic_read_data_burst_length`.

The generated path adds `axi0_arlen` as a width-8 input, captures it into
transaction-local storage such as `axi0_r0_arlen_q` under the request event,
keeps scalar `RDATA`/`RRESP` capture guarded by the generated dynamic
last-beat completion pulse, and reports generated burst-length input,
storage, and rule fields.

Dynamic runtime beat-count/`RLAST` validation for this same single-active
dynamic last-beat shape shipped later in
`IAL2-FEATURE-COMPLETENESS-FRONTIER.240` through
`ppif/axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion.ppif`.
The `.238` report-only sample remains supported and unchanged.

Dynamic multi-beat output banks, multiple/mixed dynamic demux, same-cycle
recapture, dynamic same-ID ordering, queues, scoreboards, direct backend
behavior, and VHDL remain deferred.
