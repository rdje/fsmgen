---
id: ial2-axi-manager-last-beat-read-data-behavior-first-slice
title: AXI last-beat read-data capture now generates bounded RDATA and RRESP behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.60 ship?"
  - "does AXI last-beat read-data capture generate behavior?"
  - "does the last-beat read-data sample emit RDATA and RRESP capture logic?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.60?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.61?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, read-data, rdata, rresp, burst, rlast, last-beat, behavior, hdl, task-tree]
evidence: docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md; ppif/axi_manager_capacity_status_read_data_last_beat.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_last_beat.ppif | jq '.read_data | {mode, generated_behavior, generated_inputs, generated_outputs, generated_rules, residue}'
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.60` shipped generated AXI last-beat
`RDATA`/`RRESP` capture behavior for the explicit last-beat read-data
contract.

The public sample
`ppif/axi_manager_capacity_status_read_data_last_beat.ppif` now emits
generated `RDATA`/`RRESP` inputs, per-transaction last-beat data/status
outputs, guarded capture rules driven by generated burst-last completion
pulses, `.fsm` assignments, and reachable SystemVerilog declarations and
next-state assignments.

The report keeps mode `bounded_last_beat_read_data_contract`, now sets
`generated_behavior: true`, lists the generated inputs, outputs, and rules,
and removes `generated_last_beat_read_data_capture` from read-data residue.
Deferred residue remains full multi-beat reassembly, per-beat outputs,
`RRESP` aggregation, `ARLEN` or beat-count validation, per-ID queues, direct
backend lowering, and VHDL.

The active frontier is `IAL2-FEATURE-COMPLETENESS-FRONTIER.61`: select the
next exact AXI manager feature-completeness owner after generated last-beat
read-data capture.
