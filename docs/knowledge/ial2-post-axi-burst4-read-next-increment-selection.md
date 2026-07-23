---
id: ial2-post-axi-burst4-read-next-increment-selection
title: The next AXI initiator increment is a fixed-four W burst driver
answers:
  - "what comes after the shipped AXI burst4 read composition?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.39 select?"
  - "is a multi-beat AXI write selected next?"
  - "why can the one-beat AXI W driver not simply be re-armed four times?"
  - "why select a standalone burst W driver before AW W composition?"
  - "why not integrate AXI physical transactions with capacity status next?"
  - "does the next AXI W burst slice activate decision 0020?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, initiator, w, write, burst4, multi-beat, selection, pnt]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_POST_BURST4_READ_NEXT_INCREMENT_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AxiWDriver.pm; perl/FSM/IAL2/ProtocolIntent/AxiWriteRequestComposition.pm; perl/FSM/IAL2/ProtocolIntent/AxiWriteTransactionComposition.pm; perl/FSM/IAL2/ProtocolIntent/AxiReadBurst4TransactionComposition.pm; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: rg -n 'fixed-four-beat full-width AXI4 manager W burst driver|WLAST=1|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.40|capacity/status' docs/IAL2_AXI_MANAGER_INITIATOR_POST_BURST4_READ_NEXT_INCREMENT_SELECTION.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md perl/FSM/IAL2/ProtocolIntent/AxiWDriver.pm
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.39` selects a bounded standalone
fixed-four-beat full-width AXI4 manager W burst driver as the next functional
increment. `.40` owns the behavior-neutral readiness audit.

The shipped one-beat `AxiWDriver` cannot be re-armed like the R acceptor: it
actively hard-wires WLAST high on every command. Four uses would falsely emit
four final beats under an AWLEN3 request. The new prerequisite must instead own
four WDATA32/WSTRB4 payloads, WLAST low on indices zero through two and high on
index three, stable stalled payload, exactly four accepted transfers, raw beat
events/index, one busy interval, reset, and one final done event.

The leading authoring shape captures four explicit data/strobe tuples
atomically; `.40` must compare that against packed banks and a streaming
producer before freezing it. AW coupling, 4-KiB legality, request joining, and
B completion remain later compositions. Dynamic read length, capacity adapter
wiring, outstanding queues/demux, malformed-subordinate recovery, aliases,
and verification/backend variants remain deferred. Decision 0020 stays
director-gated and is not activated.
