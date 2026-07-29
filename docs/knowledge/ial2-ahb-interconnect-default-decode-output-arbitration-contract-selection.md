---
id: ial2-ahb-interconnect-default-decode-output-arbitration-contract-selection
title: AHB interconnect arbitration uses complementary window and response modes
answers:
  - "what contract repairs AHB interconnect output selector overlaps?"
  - "what is the AHB interconnect ordinary default predicate?"
  - "will the AHB interconnect repair priority mask multiple owners?"
  - "will the interconnect repair remove no assert from paired AHB tests?"
  - "what did the paired assertion feasibility probe find after suppressing fabric assertions?"
date: 2026-07-29
status: current
tags: [ial2, ahb, interconnect, selector, assertion, arbitration, contract, ial0]
evidence: docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md; docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_AUDIT.md; docs/tasks/IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.md; docs/tasks/IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.md; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; t/1513-ial2-ahb-paired-busy-composition.t
reverify: rg -n 'subordinate_idle_lines|subordinate_hit_blocks|subordinate_owner_mux_blocks|ahb_phase_capture|--no-assert|ordinary-default' perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm t/1513-ial2-ahb-paired-busy-composition.t docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md
---

Each generated subordinate window must choose exactly one mapped-hit or
not-hit `HSEL_*`/`HADDR_*` family. Global `HREADY`/`HRESP`/`HRDATA` must choose
one retained owner, first-cycle unmapped error, or ordinary default. The
ordinary predicate is `!any_owner && !unmapped_address`. Owner blocks remain
independent so an impossible multiple-owner state still trips generated
assertions.

The interconnect repair does not remove `--no-assert` from paired tests. With
only the disposable fabric assertion block suppressed, an assertion-enabled
paired run stops in the generated subordinate at cycle 345. Enable vector
`01100000` proves its transaction idle-state `HRDATA_REGS <- 0` overlaps the
`ahb_phase_capture` rule's same assignment. Proposed separate subordinate task
`IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION` owns that audit.

Proposed interconnect child `.3` instead instantiates generated fabric modules
directly in focused t1530 and keeps generic assertion analysis unchanged.
