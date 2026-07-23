---
id: ial2-axi-r-beat-acceptor-readiness
title: The bounded explicitly armed AXI R beat acceptor is ready for contract selection
answers:
  - "is the AXI R beat acceptor ready for contract selection?"
  - "what widths should the first AXI R beat acceptor use?"
  - "what schedule should the first AXI R beat acceptor use?"
  - "does R beat done mean read transaction complete?"
  - "what does IAL2-AXI-MANAGER-INITIATOR-FRONTIER.28 establish?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.29?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, initiator, r, read-data, acceptor, readiness]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_R_BEAT_ACCEPTOR_READINESS_AUDIT.md; docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf; perl/FSM/IAL2/ProtocolIntent/AxiBResponseAcceptor.pm; perl/FSM/IAL2/ProtocolIntent/AxiArDriver.pm
reverify: rg -n '13 ports|six states|handshakes=3 done_pulses=3|includes_read_completion|IAL2-AXI-MANAGER-INITIATOR-FRONTIER.29' docs/IAL2_AXI_MANAGER_INITIATOR_R_BEAT_ACCEPTOR_READINESS_AUDIT.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.28` establishes that the selected bounded
AXI4 manager R receiver is ready for public-contract selection in `.29`.

The safe baseline is one explicit arm, one `RVALID && RREADY` handshake, raw
RID4/RDATA32/RRESP2/RLAST1 capture, stable captured outputs, and one later
beat-done pulse. The proven direct-IAL1 prototype has 13 ports, six states,
three arm assignments, seven accept assignments, and three accept-over-arm
priority resolutions; strict, Verilator, Yosys, and executable 3/3 proof pass.

Beat-done never claims full read completion. AR/R composition, ARLEN/RLAST
validation, RID/ARID matching, response interpretation, repeated/multi-beat
reception, capacity integration, outstanding/queues/demux, aliases, decision
0020, and backend variants remain explicit later owners.
