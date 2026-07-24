---
id: ial2-ahb-requester-single-busy-event-cardinality-repair-contract-selection
title: Single requester BUSY means exactly one grant-and-ready-qualified event
answers:
  - "what does busy_insertion beats single mean?"
  - "how will the AHB requester single BUSY cardinality be repaired?"
  - "what did IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.2 select?"
  - "does the single BUSY repair add a counter or new syntax?"
  - "how does BUSY hand off to the pending SEQ?"
  - "what ready and grant stalls must t 1498 prove?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, busy, htrans, hready, hgrant, cardinality, contract, repair]
evidence: docs/IAL2_AHB_REQUESTER_SINGLE_BUSY_EVENT_CARDINALITY_REPAIR_CONTRACT_SELECTION.md; docs/IAL2_AHB_REQUESTER_MULTI_BUSY_INSERTION_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; t/1498-ial2-ahb-requester-busy-insert.t; t/data/ahb_requester_busy_insert_tb.svt; docs/tasks/IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.md
reverify: rg -n 'ahb_busy_accept|HGRANT && HREADY|continue-when.*HREADY.*HTRANS|IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT\.3' docs/IAL2_AHB_REQUESTER_SINGLE_BUSY_EVENT_CARDINALITY_REPAIR_CONTRACT_SELECTION.md docs/tasks/IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.md
---

`busy_insertion.beats=single` is selected to mean exactly one rising edge with
`HGRANT && HREADY && HTRANS==BUSY`. BUSY visible while ready or grant is low is
a held pending presentation and does not retire an event.

The repair adds no public syntax/report and no single-event counter. Conditional
generated IAL1 adds `ahb_busy_accept` priority/rule, reusing
`ahb_address_pending_q` to present the same pending SEQ on the next clock, plus
an outer ready/BUSY loop gate. Existing `busy_inserted_q`, the registered BUSY
output, the pre-existing no-grant gate, and address-pending state own the full
single-event lifecycle.

Assertion-enabled disposable proofs passed continuously-ready, 32-clock
ready-low, and 32-clock grant-low scenarios with exactly one qualified BUSY
event, one resumed SEQ, four data beats, stable pending fields/counters, and no
requester selector conflict. `.3` now ships the selected contract; fact
`ial2-ahb-requester-single-busy-event-cardinality-repair` owns current runtime
behavior. Multiple-BUSY syntax, counter behavior, and policy remain deferred.
