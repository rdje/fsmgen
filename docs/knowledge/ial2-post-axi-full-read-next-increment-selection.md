---
id: ial2-post-axi-full-read-next-increment-selection
title: The next bounded AXI manager increment after full read is multi-beat INCR read composition
answers:
  - "what comes after the shipped AXI full-read composition?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.35 select?"
  - "is a multi-beat AXI read composition selected next?"
  - "why is fixed four-beat INCR the leading next AXI read contract?"
  - "why not integrate AXI physical transactions with capacity status next?"
  - "why not implement AXI multi-beat write next?"
  - "is an AXI initiator .axi alias next?"
  - "does the next AXI burst slice activate decision 0020?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, initiator, ar, r, read, burst, multi-beat, selection, pnt]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_POST_FULL_READ_NEXT_INCREMENT_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AxiReadTransactionComposition.pm; perl/FSM/IAL2/ProtocolIntent/AxiRBeatAcceptor.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/decisions/0020-ial2-layered-composable-transactor-roles.md; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: rg -n 'full-width INCR multi-beat|fixed four-beat|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.36|capacity/status adapter|Decision 0020' docs/IAL2_AXI_MANAGER_INITIATOR_POST_FULL_READ_NEXT_INCREMENT_SELECTION.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.35` selects a bounded full-width INCR
multi-beat AXI4 manager read-transaction composition as the next functional
increment after the fixed-single-beat full-read source. `.36` owns the
behavior-neutral readiness audit.

The leading first contract is one outstanding fixed four-beat burst:
`ARLEN=3`, `ARSIZE=2`, `ARBURST=INCR`, aligned address32, retained ID4, repeated
raw RID4/RDATA32/RRESP2/RLAST1 acceptance, one explicit per-beat observation
event, and transaction retirement only under an exact count/`RLAST` policy.
The audit must confirm fixed four beats versus a bounded authored length and
must add the fixed-span AXI 4-KiB legality boundary.

The expected architecture preserves the shipped single-beat source and likely
reuses the unchanged AR driver plus repeated explicitly armed use of the
unchanged one-beat R acceptor under a new coordinator. The audit must prove
that held-high RVALID remains safe across the receive/re-arm bubble and select
exact early/missing RLAST, RID mismatch, raw RRESP, reset, drain, sticky-status,
and per-beat output semantics before public syntax is frozen.

Multi-beat write is larger because it needs an upstream beat-supply/acceptance
interface and WLAST sequencing. Capacity/status integration is larger because
event timing, ID authority, result storage, backpressure, and one exact target
variant are unresolved; its existing output banks and demux should not be
duplicated in the physical composition. Back-to-back/outstanding operation
needs queues and ID ordering/demux. `.axi` adds spelling rather than capability.
Decision 0020 remains director-gated and is not activated.
