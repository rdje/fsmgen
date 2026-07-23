---
id: ial2-axi-manager-post-w-next-increment
title: The bounded AXI B write-response acceptor is selected after AW and W
answers:
  - "what comes after the shipped AXI AW and W drivers?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.11 select?"
  - "why is AXI B response acceptance selected before AW W composition?"
  - "should a future AXI AW W composition reuse generated child modules?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.12?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, b, response, acceptor, composition, task-tree]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_POST_W_NEXT_INCREMENT_SELECTION.md; docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT.md; ppif/axi_aw_driver.ppif; ppif/axi_w_driver.ppif; ppif/axi_manager_capacity_status_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiAwDriver.pm; perl/FSM/IAL2/ProtocolIntent/AxiWDriver.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: rg -n 'B write-response-channel acceptor|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.11|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.12|generated `axi_aw_driver` and `axi_w_driver` child modules|write-complete|response-event' docs/IAL2_AXI_MANAGER_INITIATOR_POST_W_NEXT_INCREMENT_SELECTION.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md ppif/axi_manager_capacity_status_response_demux.ppif
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.11` selects a bounded AXI manager B
write-response-channel acceptor as the smallest safe increment after the
independent AW and single-beat W drivers.

The B acceptor fills the physical response gap: the shipped capacity/status
core consumes an abstract accepted-response event plus `BID`, but does not
drive `BREADY` or define that event as `BVALID && BREADY`. A standalone B
receiver is one legal independent channel and advances the existing write path
without first adding AW/W coordination.

`.12` is the behavior-neutral readiness audit. It must decide explicit-arm
versus bounded continuously-ready policy, response ID/status widths and
capture timing, exactly-once/event cardinality, generated schedule, integration
seam, fail-closed rules, and every implementation owner before contract
selection.

Future AW/W composition should reuse generated `axi_aw_driver` and
`axi_w_driver` child modules under a generated structural top, plus a distinct
coordination actor for independent completion history. It should not duplicate
the two proven handshake state machines in a monolithic actor. Complete
AW+W+B transacting, multi-beat/burst coupling, AR/R, capacity integration, the
future protocol-neutral transaction interface, aliases, verification output,
backend variants/VHDL, and AHB/APB remain deferred.
