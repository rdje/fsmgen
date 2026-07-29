---
id: ial2-ahb-interconnect-default-decode-output-arbitration-audit
title: AHB interconnect output overlaps are generator-local and affect five or seven outputs
answers:
  - "what is the complete generated AHB interconnect selector conflict set?"
  - "does address zero still trigger the HADDR_REGS selector conflict?"
  - "how many selector targets does the one-window AHB interconnect have?"
  - "how many selector targets does the two-window AHB interconnect have?"
  - "does HGRANT belong to the AHB interconnect arbitration defect?"
  - "should generic selector assertions be weakened for the AHB interconnect?"
  - "which layer owns the AHB interconnect default decode arbitration repair?"
date: 2026-07-29
status: current
tags: [ial2, ahb, interconnect, selector, assertion, arbitration, ial0, lowering, audit]
evidence: docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_AUDIT.md; docs/tasks/IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.md; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/IR/LoweredRTLIRBuilder.pm; perl/FSM/Backend/GeneratedModuleEmitter.pm; ppif/ahb_interconnect.ppif; ppif/ahb_interconnect_two_subordinate.ppif
reverify: rg -n 'subordinate_idle_lines|subordinate_hit_blocks|subordinate_owner_mux_blocks|selector_conflict_targets|selector .* conflict' perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm perl/FSM/IR/LoweredRTLIRBuilder.pm perl/FSM/Backend/GeneratedModuleEmitter.pm docs/IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_AUDIT.md
---

Fresh assertion-enabled base runs at mapped addresses zero and two both stop
at `selector multi-value conflict: HADDR_REGS`. Address zero proves the defect
is independently enabled selector ownership, not merely unequal runtime
values.

The one-window interconnect has eight instrumented selector targets and five
conflicting outputs: `HADDR_REGS`, `HSEL_REGS`, `HRDATA`, `HREADY`, and
`HRESP`. The two-window interconnect has eleven targets and seven conflicting
outputs: per-window `HADDR_*`/`HSEL_*` plus the same three global response
outputs. `HGRANT`, owner bits, and `next_state` are instrumented but exclusive
and are not part of the defect.

`AhbInterconnect.pm` owns the repair because it authors unconditional defaults
together with mapped-hit, retained-owner, and unmapped drives. Generic
lowering accurately preserves those families and emits the assertions; it
must remain unchanged. Proposed child `.2` owns an exact mutually exclusive
generated-IAL0 arbitration contract before implementation.
