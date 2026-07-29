---
id: ial2-ahb-interconnect-default-decode-output-arbitration-gap
title: Generated AHB interconnect mapped outputs overlap their state defaults
answers:
  - "why do paired AHB generated selector assertions fail?"
  - "why is HADDR_REGS reported as a selector multi value conflict?"
  - "are AHB paired BUSY assertions enabled?"
  - "does the requester single BUSY repair cause the interconnect selector conflict?"
date: 2026-07-24
status: current
tags: [ial2, ahb, interconnect, selector, assertion, haddr, arbitration, lowering]
evidence: docs/IAL2_POST_EXACT_THREE_REQUESTER_ALIAS_NEXT_OWNER_SELECTION.md; docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_AUDIT.md; docs/tasks/IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.md; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; t/1513-ial2-ahb-paired-busy-composition.t; t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t
reverify: rg -n 'subordinate_idle_lines|subordinate_hit_blocks|subordinate_owner_mux_blocks|--no-assert|IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION' perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm t/1513-ial2-ahb-paired-busy-composition.t t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_AUDIT.md docs/tasks/IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.md
---

The generated AHB interconnect idle state drives `HADDR_REGS <- 0`
unconditionally and also drives `HADDR_REGS <- HADDR` inside every mapped
active-transfer branch. Generated HDL therefore enables both RHS selector
families together and assertion-enabled paired simulation stops with
`selector multi-value conflict: HADDR_REGS` on the first mapped transfer.

This overlap exists in the unchanged base interconnect generator and is not
caused by the requester single-BUSY repair. The requester-only generated HDL
passes with assertions enabled. Existing aggregate runtime tests compile with
`--no-assert`; current requester BUSY work retains that boundary while adding
ready-qualified BUSY edge counts. Parent selector
`IAL2-FEATURE-COMPLETENESS-FRONTIER.813` selected tree
`IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION` for the separate
audit and repair-owner selection. Clean selector commit `347a85f80` satisfied
the boundary. Child `.1` now confirms the five one-window and seven two-window
conflicting-output sets and selects proposed generator-local contract leaf
`.2`; generic selector assertions remain correct and mandatory.
