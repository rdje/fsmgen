---
id: ial2-post-axi-ar-next-increment-selection
title: The next bounded AXI manager increment after AR is an armed R-beat acceptor
answers:
  - "what comes after the shipped AXI AR driver?"
  - "what does IAL2-AXI-MANAGER-INITIATOR-FRONTIER.27 select?"
  - "why is an AXI R acceptor next?"
  - "does the planned R acceptor complete a full read?"
  - "why not compose full AXI read immediately?"
  - "why not integrate AXI AR with capacity status next?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, initiator, r, read-data, acceptor, selection, pnt]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_POST_AR_NEXT_INCREMENT_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AxiArDriver.pm; perl/FSM/IAL2/ProtocolIntent/AxiBResponseAcceptor.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/AXI_VALID_READY_INTENT_PROBE.md
reverify: rg -n 'one-transfer AXI4 manager R|beat accepted|IAL2-AXI-MANAGER-INITIATOR-FRONTIER.28' docs/IAL2_AXI_MANAGER_INITIATOR_POST_AR_NEXT_INCREMENT_SELECTION.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.27` selects a bounded, explicitly armed
one-transfer AXI4 manager R channel acceptor after the AR driver. `.28` owns the
behavior-neutral readiness audit.

One arm will own one `RVALID && RREADY` transfer and capture raw RID, RDATA,
RRESP, and RLAST. The done event means one R beat was accepted. It does not
assert RLAST, validate ARLEN, match RID to ARID, interpret RRESP, or claim full
read completion.

This is the next missing physical primitive and can reuse the shipped B
acceptor's arm/accept six-state architecture while preserving R-specific beat
semantics. Full AR+R composition, fixed-single-beat coupling, multi-beat
validation/storage, capacity integration, outstanding reads, aliases, and
decision `0020` remain later owners.
