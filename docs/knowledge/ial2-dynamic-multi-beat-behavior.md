---
id: ial2-dynamic-multi-beat-behavior
title: Dynamic multi-beat read-data output banks are generated
answers:
  - "does dynamic multi-beat read-data output-bank behavior work?"
  - "which dynamic multi-beat PPIF sample is supported?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.243 ship?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.243?"
  - "does dynamic read-data multi-beat capture use raw matched RID beats?"
  - "what remains deferred after dynamic multi-beat output banks?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-data, multi-beat, output-bank, runtime-validation, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; ppif/axi_manager_capacity_status_dynamic_read_data_multi_beat.ppif; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t
reverify: env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data_multi_beat.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.243|DYNAMIC_MULTI_BEAT_BEHAVIOR|axi_manager_capacity_status_dynamic_read_data_multi_beat|dynamic_read_data_multi_beat|bounded_multi_beat_read_data_contract|response_demux_matched_read_beat|generated_status_aggregate_outputs' docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm ppif/axi_manager_capacity_status_dynamic_read_data_multi_beat.ppif t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.243` ships generated dynamic
multi-beat read-data output-bank behavior for exactly one single-active
dynamic read transaction using generated burst-last dynamic response demux and
runtime-assertion `ARLEN` burst-length metadata.

The supported public PPIF sample is
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_beat.ppif`, with
support-accounting entry
`intent.ppif_axi_manager_capacity_status_dynamic_read_data_multi_beat`.

The generated path captures per-beat `RDATA` and `RRESP` lanes from raw
accepted dynamic read beats whose `RID` matches the captured dynamic ID,
maintains the valid mask and length output, and updates a scalar
worst-observed `RRESP` aggregate. It keeps the `.240` generated expected-beat
storage, read-beat counter, and beat-count/`RLAST` runtime assertions.

The `.238` report-only dynamic burst-length sample and `.240` scalar dynamic
runtime-validation sample remain supported. Multiple/mixed dynamic demux,
same-cycle recapture, dynamic same-ID ordering, queues, scoreboards, direct
backend behavior, backend-language variants outside the selected
SystemVerilog path, and VHDL remain deferred.
