---
id: ial2-axi-manager-last-beat-read-data-capture-readiness-audit
title: AXI last-beat read-data capture can be generated directly
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.59 decide?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.59?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.60?"
  - "does AXI last-beat RDATA capture need an IAL1 prerequisite?"
  - "can generated last-beat read-data capture be implemented directly?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, read-data, rdata, rresp, burst, rlast, last-beat, readiness, behavior, task-tree]
evidence: docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.59|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.60|LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT|_read_data_capture_rule_lines|generated_last_beat_read_data_capture' docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.59` audited generated AXI last-beat
read-data capture readiness and found no new IAL1, IAL0/SystemVerilog,
static-validation, support-accounting, or report-schema prerequisite.

The existing single-beat read-data behavior already has generic helpers for
declaring `RDATA`/`RRESP` inputs, per-transaction data/status outputs, guarded
capture rules, and generated-artifact report lists. The generated burst-last
response-demux behavior already creates the last-beat completion pulses. The
`.58` metadata contract binds each last-beat transaction to those pulses.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.60` used that readiness result to ship
generated last-beat `RDATA`/`RRESP` capture behavior for the existing
last-beat sample. The active frontier is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.61`, which selects the next exact AXI
manager feature-completeness owner while keeping full multi-beat reassembly,
per-beat outputs, `RRESP` aggregation, `ARLEN`/beat-count validation, per-ID
queues, direct backend lowering, and VHDL deferred until explicitly selected.
