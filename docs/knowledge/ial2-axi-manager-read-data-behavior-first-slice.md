---
id: ial2-axi-manager-read-data-behavior-first-slice
title: AXI read-data capture behavior is generated for explicit single-beat contracts
answers:
  - "does read_data generate RDATA capture behavior?"
  - "does read-data generate RDATA capture yet?"
  - "does AXI read-data capture generate HDL now?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.47 ship?"
  - "what does read_data.generated_behavior true mean?"
  - "are AXI RDATA and RRESP captured structurally?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, read-data, rdata, rresp, capture, behavior, systemverilog, task-tree]
evidence: docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; ppif/axi_manager_capacity_status_read_data.ppif; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.47` shipped generated single-beat AXI
read-data capture behavior for explicit `read-data` contracts with generated
read response-demux metadata.

The generator now adds width-bearing `RDATA`/`RRESP` IAL1 inputs, generated
per-transaction data/status IAL1 outputs, and one normal guarded capture rule
per covered read transaction. The guard is the generated read-demux completion
pulse, and the actions are ordinary held assignments rather than `(pulse ...)`
actions.

Schedule JSON now reports `read_data.generated_behavior: true` with
machine-readable `generated_inputs`, `generated_outputs`, and
`generated_rules`. `read_data.residue` removes `generated_read_data_capture`
and retains `rlast_completion`, `bursts`, and
`multi_beat_read_data_reassembly`.

The checked-in sample is:

```bash
ppif/axi_manager_capacity_status_read_data.ppif
```

The focused generator and PPIF/CLI tests prove generated `.isf`, `.fsm`, and
SystemVerilog reachability, including `--verify-hdl`. VHDL remains deferred
until the SystemVerilog-backed IAL path is feature-complete.
