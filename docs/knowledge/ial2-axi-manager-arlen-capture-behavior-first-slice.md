---
id: ial2-axi-manager-arlen-capture-behavior-first-slice
title: AXI ARLEN capture behavior ships generated raw-ARLEN storage
answers:
  - "does burst-length metadata generate ARLEN capture?"
  - "does AXI read-data burst-length emit axi0_arlen?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.66 ship?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.66?"
  - "does generated burst-length capture store raw ARLEN or beat count?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, read-data, burst-length, arlen, capture, behavior, task-tree]
evidence: docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; ppif/axi_manager_capacity_status_read_data_burst_length.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.66|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.67|generated raw-ARLEN|generated_burst_length_inputs|generated_burst_length_storage|generated_burst_length_rules|axi0_r0_burst_length_capture|burst_length_generated_behavior.*true' docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.66` ships generated raw-ARLEN capture for
explicit last-beat `read-data` `burst-length source arlen` contracts.

The generated IAL1 now includes width-8 `axi0_arlen`, one width-8 raw-ARLEN
storage variable per covered read transaction (`axi0_r0_arlen_q`,
`axi0_r1_arlen_q`), and request-event guarded capture rules
(`axi0_r0_burst_length_capture`, `axi0_r1_burst_length_capture`). The `.fsm`
and SystemVerilog outputs lower those same input/storage/rules while existing
last-beat `RDATA`/`RRESP` capture remains intact.

Schedule JSON reports `burst_length_generated_behavior: true`, generated
burst-length input/storage/rule fields, general `generated_inputs` including
`axi0_arlen`, and residue without `generated_burst_length_capture`.
`burst_length_validation` remains `report_only`.

The stored value is raw `ARLEN`, not `ARLEN + 1`. The next selected leaf is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.67`, a beat-count/RLAST validation
readiness audit before expected-beat arithmetic, validation counters,
payload storage/reassembly, per-beat outputs, `RRESP` aggregation, direct
backend lowering, or VHDL work.
