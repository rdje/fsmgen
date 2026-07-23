---
id: ial2-axi-aw-w-request-composition-readiness-audit
title: The bounded AXI AW plus W request composition is ready for contract selection
answers:
  - "what exact single-beat policy should AXI AW W composition use?"
  - "how does the AXI AW W coordinator join independent completion pulses?"
  - "why must the AXI AW W coordinator capture command payload?"
  - "how are misaligned AXI write commands rejected?"
  - "what artifacts should the AXI AW W composition generate?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.17?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, aw, w, composition, coordinator, single-beat, readiness]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_AW_W_REQUEST_COMPOSITION_READINESS_AUDIT.md; docs/IAL2_AXI_MANAGER_INITIATOR_POST_B_NEXT_INCREMENT_SELECTION.md; ppif/axi_aw_driver.ppif; ppif/axi_w_driver.ppif; perl/FSM/IAL2/ProtocolIntent/AxiAwDriver.pm; perl/FSM/IAL2/ProtocolIntent/AxiWDriver.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: rg -n 'AWLEN = 8.d0|AWSIZE = 3.d2|AWBURST = 2.b01|atomic command-payload capture|rule-only IAL1 actor|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.17' docs/IAL2_AXI_MANAGER_INITIATOR_AW_W_REQUEST_COMPOSITION_READINESS_AUDIT.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.16` proves that the selected bounded AXI
AW+W request composition is ready for exact contract selection. The safe
single-beat policy fixes AWLEN=0, AWSIZE=2 (four bytes), and AWBURST=INCR; keeps
a 32-bit byte address and four-bit AWID; requires four-byte alignment; carries
one 32-bit W beat with WLAST=1; and preserves arbitrary four-bit WSTRB,
including zero.

A distinct generated rule-only coordinator must atomically capture address,
ID, data, and strobe on idle admission before pulsing both unchanged child
drivers. It tracks AW and W completion history independently, so simultaneous,
AW-first, and W-first completion each yield exactly one aggregate done after
both request handshakes. Direct aggregate-to-child payload wiring is unsafe
because registered child starts are observed after a one-shot caller may have
changed its inputs.

Misalignment is fail-closed twice: the launch rule requires address bits
`[1:0]` both zero, and a generated assertion reports an unaligned idle
admission attempt. Indexed bits are used because the scratch modulo-equals-zero
form exposed the already-known current HDL width-warning pattern. Scratch
strict/schedule/lint and executable proofs passed payload capture, misaligned
no-launch, simultaneous/AW-first/W-first joins, three child starts per side,
and three done pulses.

The generated result must aggregate three IAL1 items and schedules (AW, W,
coordinator), three child IAL0 artifacts, and one selected structural-top IAL0
artifact. B response acceptance and full transaction completion remain
separate. `.17` owns exact public spelling/report selection; behavior still has
not changed.
