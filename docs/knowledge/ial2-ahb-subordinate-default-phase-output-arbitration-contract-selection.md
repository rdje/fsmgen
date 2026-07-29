---
id: ial2-ahb-subordinate-default-phase-output-arbitration-contract-selection
title: Generated AHB subordinate arbitration removes exactly five redundant output writes
answers:
  - "what contract repairs generated AHB subordinate output selector overlaps?"
  - "which AHB phase capture and hold output writes are redundant?"
  - "which AHB error retirement output write is redundant?"
  - "does the generated AHB endpoint repair weaken selector assertions?"
  - "what assertion-enabled feasibility proof supports the AHB endpoint contract?"
date: 2026-07-29
status: current
tags: [ial2, ahb, subordinate, selector, assertion, arbitration, contract, ial1]
evidence: docs/IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_AUDIT.md; docs/tasks/IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.md; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; t/1519-ial2-ahb-pipelined-active-transfer-audit.t
reverify: rg -n 'ahb_phase_capture|ahb_phase_hold|ahb_error_retire|HREADYOUT|HRESP|HRDATA|--no-assert' perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm t/1513-ial2-ahb-paired-busy-composition.t t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t t/1519-ial2-ahb-pipelined-active-transfer-audit.t docs/IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md
---

The generated-endpoint repair removes exactly five redundant IAL1 writes in
`AhbSubordinate.pm`: HRESP/HRDATA from `ahb_phase_capture`, HRESP/HRDATA from
`ahb_phase_hold`, and HRDATA from `ahb_error_retire`. Capture and hold retain
not-ready ownership; retirement retains ready plus explicit OKAY; idle,
enter/read/write, and two-cycle ERROR drives remain unchanged.

The richest disposable candidate lowered through public `bin/fsmgen` and
passed the existing direct phase-pipeline runtime with every assertion
enabled. It preserved exact active success/SEQ, ERROR continuation, and
ERROR-to-IDLE cancellation counts and storage. Generic same-value and
multi-value selector assertions remain enabled and unchanged. Clean contract
commit `ef14893f5` activates implementation `.3`; the separate hand-authored
IAL0 seed remains outside this repair.
