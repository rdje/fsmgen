---
id: ial2-ahb-subordinate-default-phase-output-arbitration-gap
title: Generated AHB subordinate idle and phase-capture outputs overlap
answers:
  - "why can paired AHB tests not enable assertions after the interconnect repair?"
  - "which AHB subordinate selectors overlap on the first captured phase?"
  - "what does subordinate HRDATA_REGS enables 01100000 mean?"
  - "which task owns the generated AHB subordinate output arbitration audit?"
date: 2026-07-29
status: current
tags: [ial2, ahb, subordinate, selector, assertion, phase-capture, arbitration, gap]
evidence: docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md; docs/tasks/IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.md; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; t/1513-ial2-ahb-paired-busy-composition.t; t/1519-ial2-ahb-pipelined-active-transfer-audit.t
reverify: rg -n 'HRDATA_REGS|ahb_phase_capture|ahb_phase_hold|--no-assert' perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm t/1513-ial2-ahb-paired-busy-composition.t t/1519-ial2-ahb-pipelined-active-transfer-audit.t docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md
---

A disposable one-window paired run suppressed only the generated fabric
assertion block and kept requester/subordinate assertions enabled. At cycle
345 it stopped in `dut.regs` with `selector same-value conflict: HRDATA_REGS 0
enables=01100000`.

The ordered enable vector proves two active generated sources: the subordinate
transaction's idle-state output default `HRDATA_REGS <- 0` and the generated
`ahb_phase_capture` rule's explicit `HRDATA_REGS <- 0`. The overlap is
independent of the interconnect defect. Its complete selector set and smallest
repair owner remain to be audited by proposed task
`IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION`; generic assertions
must not be disabled in lieu of that audit.
