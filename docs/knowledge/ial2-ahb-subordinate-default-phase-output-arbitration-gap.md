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
evidence: docs/IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_AUDIT.md; docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md; docs/tasks/IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.md; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; t/1513-ial2-ahb-paired-busy-composition.t; t/1519-ial2-ahb-pipelined-active-transfer-audit.t
reverify: rg -n 'HRDATA_REGS|HRDATA 0|ahb_phase_capture|ahb_phase_hold|--no-assert' perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm t/1513-ial2-ahb-paired-busy-composition.t t/1519-ial2-ahb-pipelined-active-transfer-audit.t docs/IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_AUDIT.md
---

A disposable one-window paired run suppressed only the generated fabric
assertion block and kept requester/subordinate assertions enabled. At cycle
345 it stopped in `dut.regs` with `selector same-value conflict: HRDATA_REGS 0
enables=01100000`.

The ordered enable vector proves two active generated sources: the subordinate
transaction's idle-state output default `HRDATA_REGS <- 0` and the generated
`ahb_phase_capture` rule's explicit `HRDATA_REGS <- 0`. Direct endpoint
reproduction fails on the corresponding `HRDATA 0` assertion without any
interconnect.

Audit `.1` maps all five generated variants. Every variant has exactly three
bus selector targets (`HRDATA`, `HREADYOUT`, `HRESP`); base has 2/2/3 RHS
families and all narrow variants have 8/2/3. Runtime additionally proves
idle+hold `HRDATA=0` and final-ERROR retire+capture `HRDATA=0` plus explicit
OKAY `HRESP` overlaps. Generic priority correctly suppresses different-value
losers but intentionally leaves same-value multiple ownership observable.
Therefore completed `.2` selects exactly five redundant-write removals in
`AhbSubordinate.pm`; proposed implementation `.3` owns the repair and generic
assertions remain mandatory. The separate hand-authored IAL0 seed gap is owned
by proposed
`IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION`.
