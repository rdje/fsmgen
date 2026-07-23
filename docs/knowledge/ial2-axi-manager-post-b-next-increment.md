---
id: ial2-axi-manager-post-b-next-increment
title: The next AXI initiator increment is a child-reusing AW plus W request composition
answers:
  - "what comes after the shipped AXI AW W and B primitives?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.15 select?"
  - "why is AXI AW W composition selected after the B acceptor?"
  - "why must the AXI AW W composition constrain AWLEN?"
  - "should the AXI AW W composition reuse the existing drivers?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.16?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, aw, w, composition, single-beat, task-tree]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_POST_B_NEXT_INCREMENT_SELECTION.md; ppif/axi_aw_driver.ppif; ppif/axi_w_driver.ppif; ppif/axi_b_response_acceptor.ppif; perl/FSM/IAL2/ProtocolIntent/AxiAwDriver.pm; perl/FSM/IAL2/ProtocolIntent/AxiWDriver.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: rg -n 'AW.W single-beat write-request composition|AWLEN = 0|generated coordinator|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.15|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.16' docs/IAL2_AXI_MANAGER_INITIATOR_POST_B_NEXT_INCREMENT_SELECTION.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.15` selects a bounded single-beat
AW+W write-request composition after the independent AW, W, and B primitives.
The composition must reuse the generated `axi_aw_driver` and `axi_w_driver`
children plus a distinct generated launch/join coordinator under a generated
structural top. It must not duplicate the proven child state machines.

The decisive coherence gate is the mismatch between the AW child's arbitrary
burst metadata and the W child's one beat with `WLAST=1`. Because beats equal
`AWLEN + 1`, an aggregate cannot forward arbitrary `AWLEN` safely. `.16` must
select a fixed or fail-closed single-beat `AWLEN`/`AWSIZE`/`AWBURST` policy,
then prove exactly one AW and one W handshake per aggregate command, independent
AW/W stalls and completion order, remembered child completion pulses, and one
aggregate done only after both transfers.

The B acceptor remains separate: this boundary reports write-request issue
completion, not B response or AXI transaction completion. Capacity-core
integration, AW+W+B transacting, multi-beat/burst coupling, AR/R, the
director-gated transaction interface, aliases, verification output, backend
variants/VHDL, and AHB/APB remain deferred. `.16` is the behavior-neutral
readiness audit before exact contract selection.
