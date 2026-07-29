---
id: ial2-ahb-interconnect-default-decode-output-arbitration-behavior
title: Generated AHB interconnect output modes are now assertion-clean
answers:
  - "is generated AHB interconnect output arbitration assertion-clean?"
  - "what did IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.3 implement?"
  - "how does the AHB interconnect select HSEL and HADDR defaults?"
  - "when does the AHB interconnect drive its ordinary response default?"
  - "does the AHB interconnect repair hide impossible multiple owners?"
  - "why do paired AHB tests still use no-assert after the interconnect repair?"
date: 2026-07-29
status: current
tags: [ial2, ahb, interconnect, selector, assertion, arbitration, ial0, behavior]
evidence: docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_BEHAVIOR.md; docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md; docs/tasks/IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.md; docs/tasks/IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.md; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; t/1478-ial2-ahb-interconnect.t; t/1480-ial2-ahb-interconnect-two-subordinate.t; t/1530-ial2-ahb-interconnect-output-arbitration.t
reverify: prove -Iperl t/1478-ial2-ahb-interconnect.t t/1480-ial2-ahb-interconnect-two-subordinate.t t/1530-ial2-ahb-interconnect-output-arbitration.t && rg -n 'subordinate_decode_blocks|ordinary_default|mapped_zero|two-window' perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm t/1530-ial2-ahb-interconnect-output-arbitration.t docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_BEHAVIOR.md
---

Generated AHB interconnect IAL0 now uses complementary mapped-hit/not-hit
`HSEL_*`/`HADDR_*` modes. Global `HREADY`/`HRESP`/`HRDATA` choose a retained
owner, first-cycle unmapped ERROR, or ordinary default; the ordinary predicate
is `!any_owner && !unmapped_address`.

Independent owner blocks remain visible to generic selector assertions, so an
impossible multiple-owner state is not priority-masked. Assertion-enabled
direct-fabric `t/1530` passes one- and two-window mapped-zero/nonzero, local
translation, wait, success, subordinate ERROR, same-edge replacement, and
two-cycle unmapped ERROR behavior.

The later generated-subordinate repair retires the paired `--no-assert`
boundary; paired aggregates now run with fabric and endpoint assertions
enabled. Public syntax, ports, reports, support, artifacts, semantic/MCP
surfaces, and AHB transaction behavior are unchanged.
