---
id: ial2-post-axi-r-beat-acceptor-next-increment-selection
title: The next bounded AXI manager increment after the R-beat acceptor is fixed-single-beat full-read composition
answers:
  - "what comes after the shipped AXI R-beat acceptor?"
  - "what does IAL2-AXI-MANAGER-INITIATOR-FRONTIER.31 select?"
  - "is AXI AR and R full-read composition selected next?"
  - "why is a separate AXI AR legality slice not required first?"
  - "what will fixed-single-beat AXI read completion mean?"
  - "why not integrate the physical AXI read path with capacity status next?"
  - "does the next AXI read composition activate decision 0020?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, initiator, ar, r, read, composition, single-beat, selection, pnt]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_POST_R_BEAT_ACCEPTOR_NEXT_INCREMENT_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AxiArDriver.pm; perl/FSM/IAL2/ProtocolIntent/AxiRBeatAcceptor.pm; perl/FSM/IAL2/ProtocolIntent/AxiWriteRequestComposition.pm; perl/FSM/IAL2/ProtocolIntent/AxiWriteTransactionComposition.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/decisions/0020-ial2-layered-composable-transactor-roles.md
reverify: rg -n 'fixed-single-beat AXI4 manager full-read|IAL2-AXI-MANAGER-INITIATOR-FRONTIER.32|ARLEN=0|RID mismatch or missing `RLAST` is terminal' docs/IAL2_AXI_MANAGER_INITIATOR_POST_R_BEAT_ACCEPTOR_NEXT_INCREMENT_SELECTION.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.31` selects a bounded
fixed-single-beat AXI4 manager full-read composition after the standalone AR
driver and explicitly armed R-beat acceptor. `.32` owns the behavior-neutral
readiness audit.

The selected composition will reuse both channel actors unchanged under a new
read coordinator and a flat three-child C4 top. One aligned address32/ID4
command privately fixes `ARLEN=0`, `ARSIZE=2`, and `ARBURST=INCR`, so the one
owned RID4/RDATA32/RRESP2/RLAST1 beat is an honest fixed-request transaction
boundary. Request-done means AR acceptance; transaction-done means the owned R
beat retired. RRESP remains raw and does not imply success.

Fixed metadata and a four-byte alignment guard absorb the needed request
legality into composition, just as the shipped write composition uses sized
C4 constants. The standalone dynamic AR driver remains unchanged. RID mismatch
or missing RLAST must be assertion/status-visible but terminal after the
already-consumed beat; non-OKAY RRESP is raw and terminal.

Multi-beat reception, dynamic AR metadata, capacity/status adapter wiring,
outstanding/back-to-back reads, ID queues/demux/interleaving, broader burst and
address generation, aliases, verification output, direct/backend/VHDL, AHB,
and APB remain deferred. Decision 0020 is preserved as a director-gated North
Star and is not activated.
