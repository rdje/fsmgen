---
id: ial2-ahb-subordinate-default-phase-output-arbitration-behavior
title: Generated AHB subordinate output arbitration is assertion-clean
answers:
  - "is generated AHB subordinate output arbitration assertion-clean?"
  - "what did IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.3 implement?"
  - "which generated AHB subordinate output writes were removed?"
  - "do paired AHB BUSY compositions now run with assertions enabled?"
  - "does the AHB endpoint repair weaken generic selector assertions?"
  - "why does direct AHB seed t1520 still use no-assert?"
date: 2026-07-29
status: current
tags: [ial2, ahb, subordinate, selector, assertion, arbitration, ial1, behavior]
evidence: docs/IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_BEHAVIOR.md; docs/IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md; docs/tasks/IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.md; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; t/1475-ial2-ahb-subordinate.t; t/1513-ial2-ahb-paired-busy-composition.t; t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t; t/1519-ial2-ahb-pipelined-active-transfer-audit.t; t/1523-ial2-ahb-exact-two-paired-busy-composition.t; t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t
reverify: prove -Iperl t/1211-isf-runtime-selector-conflict-instrumentation.t t/1219-isf-rule-transaction-priority.t t/1475-ial2-ahb-subordinate.t t/1513-ial2-ahb-paired-busy-composition.t t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t t/1519-ial2-ahb-pipelined-active-transfer-audit.t t/1523-ial2-ahb-exact-two-paired-busy-composition.t t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t
---

`AhbSubordinate.pm` removes exactly capture/hold HRESP+HRDATA and retirement
HRDATA writes. Capture/hold keep not-ready; retirement keeps ready+OKAY; idle,
enter/read/write, and two-cycle ERROR ownership remain unchanged. Generic
same-value and multi-value selector assertions stay enabled.

Base and richest direct `t/1519` pass with assertions enabled. One-/two-window,
generic/alias, exact-one/exact-two paired `t/1513`-`t/1516`, `t/1523`, and
`t/1525` also pass without `--no-assert`. The separately hand-authored direct
IAL0 seed remains owned by proposed
`IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION` and keeps its `t/1520`
boundary.
