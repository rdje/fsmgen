---
id: ial2-axi-manager-read-data-capture-readiness-audit
title: AXI read-data capture behavior can implement directly
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.46 decide?"
  - "does generated RDATA capture need an IAL1 prerequisite?"
  - "does generated AXI read-data capture need an IAL0 prerequisite?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.47?"
  - "what is the next read-data capture behavior slice?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, read-data, rdata, rresp, capture, readiness, task-tree]
evidence: docs/AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.46|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.47|AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT|AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE|generated single-beat AXI read-data|read_data.generated_behavior' docs/AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.46` audited generated single-beat AXI
read-data capture behavior after the shipped parser/report metadata slice.
It concluded that generated `RDATA`/`RRESP` capture can be implemented
directly; no smaller IAL1, IAL0, or SystemVerilog prerequisite is required.

The selected next owner was `IAL2-FEATURE-COMPLETENESS-FRONTIER.47`, and it
is now shipped by
`docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md`. That slice added
width-bearing generated IAL1 inputs for `RDATA` and `RRESP`, width-bearing
per-transaction data/status outputs, and one normal guarded rule assignment
per read transaction under the generated read response-demux completion pulse.
The payload/status outputs use ordinary rule assignments, not `(pulse ...)`,
because the captured values are held until the next matching completion pulse
updates them.

The shipped report sets `read_data.generated_behavior: true`, reports
generated input/output/rule artifacts, removes
`generated_read_data_capture` residue, and keeps `RLAST`, bursts, and
multi-beat read-data reassembly as residue. VHDL remains deferred until the
SystemVerilog-backed IAL path is feature-complete.
