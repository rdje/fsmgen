---
id: ial2-post-interconnect-arbitration-next-owner-selection
title: AHB subordinate output arbitration follows the interconnect repair
answers:
  - "what comes after assertion-clean AHB interconnect arbitration?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.814 select?"
  - "why is the AHB subordinate output-arbitration audit next?"
  - "why is exact-three paired AHB composition not next after the interconnect repair?"
  - "which tests still use no-assert after AHB interconnect arbitration ships?"
date: 2026-07-29
status: current
tags: [ial2, ahb, subordinate, selector, assertion, arbitration, roadmap]
evidence: docs/IAL2_POST_INTERCONNECT_ARBITRATION_NEXT_OWNER_SELECTION.md; docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.md; docs/knowledge/ial2-ahb-subordinate-default-phase-output-arbitration-gap.md; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; t/1513-ial2-ahb-paired-busy-composition.t; t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t; t/1523-ial2-ahb-exact-two-paired-busy-composition.t; t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t
reverify: rg -n -- '--no-assert|ahb_phase_capture|HRDATA_REGS|IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION' t/1513-ial2-ahb-paired-busy-composition.t t/1514-ial2-ahb-paired-busy-composition-profile-alias.t t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t t/1523-ial2-ahb-exact-two-paired-busy-composition.t t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm docs/IAL2_POST_INTERCONNECT_ARBITRATION_NEXT_OWNER_SELECTION.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.814` selects proposed
`IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.1` after the interconnect
repair completed at `6eeac974c`.

Direct fabric assertions now pass, but paired tests t1513-t1516/t1523/t1525
still use `--no-assert`. A fabric-suppressed feasibility run stopped in the
subordinate with `HRDATA_REGS 0 enables=01100000`, identifying overlapping
transaction-idle and `ahb_phase_capture` output families authored by
`AhbSubordinate.pm`. The complete endpoint selector set is not yet known, so
the selected next step is a no-behavior ownership audit.

Exact-three paired composition, larger counts, policy/runtime/multiple-point
insertion, status, broader bursts/signals, generic priority implementation,
and decision 0020 remain deferred until the endpoint boundary is audited.
