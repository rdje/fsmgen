---
id: ial2-post-axi-full-write-next-increment-selection
title: The next bounded AXI manager increment after full write is an AR driver
answers:
  - "what comes after the shipped AXI full-write composition?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.23 select?"
  - "why is an AXI AR driver next?"
  - "why not integrate AXI full write with capacity status next?"
  - "why not implement an AXI R acceptor or full read composition next?"
  - "is the full-write .axi alias next?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, initiator, ar, read-address, selection, pnt]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_POST_FULL_WRITE_NEXT_INCREMENT_SELECTION.md; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md; docs/AXI_VALID_READY_INTENT_PROBE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; ppif/axi_write_transaction_composition.ppif
reverify: rg -n 'Select a bounded.*read-address|Standalone bounded AR driver|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.24' docs/IAL2_AXI_MANAGER_INITIATOR_POST_FULL_WRITE_NEXT_INCREMENT_SELECTION.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.23` selects a bounded AXI4 manager
read-address (AR) channel driver as the next increment after the shipped
single-beat full-write composition. `.24` owns the behavior-neutral readiness
audit before any public contract or implementation.

AR is the next missing bus-side primitive and mirrors the proven corrected AW
driver shape: one idle local command, atomic payload capture, ARVALID asserted
independently of ARREADY, stable payload through arbitrary backpressure,
exactly one handshake, and one request-issued done pulse. It does not accept R
data and does not mean read-transaction completion.

The alternatives are larger or non-behavioral. R acceptance must choose
RID/RDATA/RRESP/RLAST and single-/multi-beat ownership before any AR source
exists. A full read composition requires both primitives plus coordination.
Capacity/status integration needs a physical-to-abstract event/ID adapter and
adds little at the current one-outstanding depth. Multi-beat or outstanding
writes need queues/counters/ID ordering. `.axi` surfacing adds syntax rather
than capability. Decision 0020's protocol-neutral transaction interface
remains director-gated.

The `.24` audit must fix the source anchors, address32/ID4/LEN8/SIZE3/BURST2 or
other bounded payload decision, exact names/role/reset, corrected six-state
schedule reuse, report/artifacts/diagnostics, generated-HDL proof, every
implementation owner, and all R/capacity/multi-beat/outstanding/alias/backend
deferrals before a contract-selection leaf may proceed.
