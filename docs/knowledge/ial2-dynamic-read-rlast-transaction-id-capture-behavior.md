---
id: ial2-dynamic-read-rlast-transaction-id-capture-behavior
title: Dynamic read RLAST response-demux behavior is generated
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.231 ship?"
  - "does dynamic read RLAST response-demux generate behavior?"
  - "what is bounded_dynamic_read_rid_rlast_demux_contract?"
  - "what PPIF sample covers dynamic read RLAST demux?"
  - "how does dynamic read RLAST matching complete?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-response-demux, rlast, generated-behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif; env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.231` ships generated bounded dynamic read
burst-last/`RLAST` transaction-ID capture and response matching.

The public sample is
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif`.
It uses one transaction-local `(id dynamic)` read transaction plus explicit
`response-demux.read` with `response-scope burst-last`, one-bit `last-signal`,
and generated transaction completion.

FSMGen captures admitted `ARID` into generated selected-ID storage, keeps a
single-active dynamic read busy bit across non-last beats, pulses the generated
completion only on raw read response event plus `RID == captured_id && RLAST`,
and releases busy from that completion. The report mode is
`bounded_dynamic_read_rid_rlast_demux_contract` with
`transaction_completion_semantics: matched_dynamic_id_and_last_signal`.
