---
id: ial2-axi-manager-read-data-burst-readiness-audit
title: AXI read-data readiness selects public contract first
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.43 decide?"
  - "what comes after the AXI read-data readiness audit?"
  - "is read-data payload behavior implemented after read response demux?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.44?"
  - "what must happen before AXI read-data payload behavior?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, read-data, rdata, rresp, rlast, bursts, interleaving, public-contract, task-tree]
evidence: docs/AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.43|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.44|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.45|AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION|AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT' docs/AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.43` audited AXI read-data payload,
burst/`RLAST`, and per-ID ordering/reassembly readiness after generated read
`RID` response-demux behavior.

The audit did not implement parser, generator, `.isf`, `.fsm`, HDL, check
JSON, or semantic JSON behavior. It selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.44` as the next owner.

`.44` later selected the bounded public read-data payload/status contract:
explicit `(read-data (read ...))` syntax for single-beat `RDATA`/`RRESP`
capture layered on the shipped generated read `RID` demux. `RLAST`, bursts,
and multi-beat reassembly remain deferred. The next owner is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.45`, parser/report metadata and static
validation for that contract.

The existing IAL1/IAL0/SystemVerilog substrate likely can carry the bounded
single-beat payload/status shape because IAL1 already supports width-bearing
inputs, outputs, variables, and rule assignments, and generated read demux
already provides per-transaction completion pulses.

Burst assembly, `RLAST`-driven completion, different-ID read-data reassembly,
same-ID concrete issue-order queues, subordinate read-data reordering-depth
modeling, queued/blocking policy, profile aliases, full-manager behavior,
direct backend lowering, and VHDL remain future exact-owner work.
