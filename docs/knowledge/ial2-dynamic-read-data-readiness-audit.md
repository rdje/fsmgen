---
id: ial2-dynamic-read-data-readiness-audit
title: Dynamic read-data audit selects scalar dynamic read-data implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.233 select?"
  - "what comes after the dynamic read-data readiness audit?"
  - "can dynamic read-data routing be implemented directly?"
  - "what is the first dynamic read-data implementation boundary?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-data, read-response-demux, selector]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RLAST_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/knowledge/ial2-dynamic-read-data-behavior.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Adapter/IAL2/PPIF.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.233|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.234|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.235|DYNAMIC_READ_DATA_READINESS_AUDIT|DYNAMIC_READ_DATA_BEHAVIOR|scalar dynamic read-data|generated_dynamic_demux|generated_dynamic_demux_last_beat|generated_dynamic_read_response_demux_completion_pulse|generated_dynamic_read_response_demux_last_beat_completion_pulse' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.233` selects `.234`, direct bounded
implementation of scalar dynamic read-data capture over generated
single-active dynamic read response-demux.

The implementation boundary reuses existing `read-data.read` syntax. It covers
exactly one transaction-local dynamic read transaction under generated dynamic
`response-demux.read`, with scalar `capture-scope single-beat` and scalar
`capture-scope last-beat` only. The generated dynamic completion pulse is the
guard for `RDATA`/`RRESP` capture.

The audit found no public syntax or lower cleanup prerequisite. Dynamic read
single-beat and burst-last response-demux reports already expose one dynamic
transaction plus one generated completion signal; existing scalar read-data
behavior already captures from generated completion pulses.

`.234` must keep dynamic `burst_length`, runtime validation, multi-beat output
banks, multiple dynamic read/write transactions, mixed dynamic/static demux,
same-cycle recapture, dynamic same-ID ordering, queues, scoreboards, direct
backend behavior, HDL behavior outside the selected SystemVerilog path, and
VHDL fail-closed.

The selected `.234` implementation later shipped that scalar dynamic
read-data boundary. Its behavior contract is recorded in
`docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md` and
`docs/knowledge/ial2-dynamic-read-data-behavior.md`; `.235` is the next exact
owner selector.
