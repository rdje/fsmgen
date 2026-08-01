---
id: ial2-dynamic-runtime-validation-behavior
title: Dynamic runtime beat-count and RLAST validation is generated
answers:
  - "does dynamic runtime beat-count validation work?"
  - "which dynamic runtime validation PPIF sample is supported?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.240 ship?"
  - "does dynamic read-data runtime assertion support raw matched RID beats?"
  - "what remains deferred after dynamic runtime validation?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-data, burst-length, runtime-validation, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; ppif/axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion.ppif; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t
reverify: >-
  env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.240|DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR|axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion|beat_count_validation_generated_behavior|response_demux_matched_read_beat|generated_beat_count_assertions' docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm ppif/axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion.ppif
  t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.240` ships generated runtime
beat-count/`RLAST` validation for exactly one single-active dynamic read
transaction using generated burst-last dynamic response demux and scalar
last-beat dynamic read-data capture.

The supported public PPIF sample is
`ppif/axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion.ppif`,
with support-accounting entry
`intent.ppif_axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion`.

The generated path adds expected-beat storage, read-beat counter storage,
request-time initialization from `ARLEN + 1`, raw matched dynamic
`RID == captured_id` beat-count increments, and four generated assertions:
`arlen_within_max`, `read_beat_before_expected_count`,
`rlast_on_expected_beat`, and `expected_final_beat_has_rlast`.

The `.238` report-only dynamic burst-length sample remains supported and
unchanged. Dynamic multi-beat output banks, multiple/mixed dynamic demux,
same-cycle recapture, dynamic same-ID ordering, queues, scoreboards, direct
backend behavior, backend-language variants outside the selected
SystemVerilog path, and VHDL remain deferred.
