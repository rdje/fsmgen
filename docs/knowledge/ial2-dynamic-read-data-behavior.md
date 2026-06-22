---
id: ial2-dynamic-read-data-behavior
title: Dynamic read-data capture ships for one generated dynamic read transaction
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.234 ship?"
  - "does dynamic read-data routing work?"
  - "which dynamic read-data PPIF samples are supported?"
  - "what is the dynamic read-data completion validity vocabulary?"
  - "what follows dynamic read-data behavior?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-data, response-demux, systemverilog]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_FOCUSED_SUITE_CLEANUP.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; ppif/axi_manager_capacity_status_dynamic_read_data.ppif; ppif/axi_manager_capacity_status_dynamic_read_data_last_beat.ppif; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/248-regression-corpus-accounting.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.234|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.236|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.237|generated_dynamic_read_response_demux_completion_pulse|generated_dynamic_read_response_demux_last_beat_completion_pulse|t/1438-axi-ial2-manager-dynamic-transaction-id-focused|dynamic burst-length capture|axi_manager_capacity_status_dynamic_read_data' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md docs/AXI_IAL2_MANAGER_DYNAMIC_FOCUSED_SUITE_CLEANUP.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.234` ships bounded scalar dynamic
read-data capture over generated single-active dynamic read response-demux on
the SystemVerilog-backed path.

The supported public samples are:

- `ppif/axi_manager_capacity_status_dynamic_read_data.ppif`
- `ppif/axi_manager_capacity_status_dynamic_read_data_last_beat.ppif`

Both samples reuse existing `read-data.read` syntax with
`completion-source response-demux`, exactly one transaction-local dynamic read
transaction, and a generated `response-demux.read` completion pulse. The
single-beat shape captures scalar `RDATA`/`RRESP` under
`generated_dynamic_read_response_demux_completion_pulse`; the burst-last shape
captures scalar last-beat `RDATA`/`RRESP` under
`generated_dynamic_read_response_demux_last_beat_completion_pulse`.

The generated capture rule consumes the generated completion pulse from the
dynamic read response-demux. It does not add a second raw `RID` or `RLAST`
match path inside read-data behavior.

`.234` intentionally keeps dynamic burst-length capture, runtime validation,
multi-beat output banks, multiple dynamic read/write transactions, mixed
dynamic/static demux, same-cycle recapture, dynamic same-ID ordering, queues,
scoreboards, direct backend behavior, HDL behavior outside the selected
SystemVerilog path, and VHDL as explicit residue.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.236` later added bounded focused
validation for the shipped dynamic family. The active follow-on is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.237`, readiness audit for dynamic
burst-length capture over generated dynamic last-beat read-data.
