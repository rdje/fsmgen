---
id: ial2-axi-read-burst4-transaction-composition-contract-selection
title: The fixed-four AXI manager read transaction public contract is selected
answers:
  - "what is the selected fixed-four AXI read PPIF contract?"
  - "what are the AXI burst4 read generator and report identities?"
  - "what is the exact fixed-four AXI read coordinator schedule?"
  - "what does response beat index mean in the AXI burst4 composition?"
  - "what artifacts does the AXI burst4 read composition generate?"
  - "what support counts will the AXI burst4 read composition use?"
  - "what must t 1507 prove?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.37 select?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.38?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, initiator, ar, r, burst4, multi-beat, composition, contract]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_BURST4_READ_TRANSACTION_COMPOSITION_CONTRACT_SELECTION.md; docs/IAL2_AXI_MANAGER_INITIATOR_BURST4_READ_TRANSACTION_COMPOSITION_READINESS_AUDIT.md; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: rg -n 'axi-read-burst4-transaction-composition|AxiReadBurst4TransactionComposition|20 ports|48 composition nets|305 -> 306|PASS ar=4 r=13|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.38' docs/IAL2_AXI_MANAGER_INITIATOR_BURST4_READ_TRANSACTION_COMPOSITION_CONTRACT_SELECTION.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.37` selects the exact additive
`(axi-read-burst4-transaction-composition ...)` contract. Its generator is
`FSM::IAL2::ProtocolIntent::AxiReadBurst4TransactionComposition`; parser and
result kinds, schema v1, source/top/coordinator, support identity, and t/1507
are frozen without changing the shipped fixed-single object.

The exact thirteen-anchor source exposes legal address32/ID4 command, full AR,
raw RID4/RDATA32/RRESP2/RLAST1, request/beat/transaction pulses, beat index2,
and sticky ID plus RLAST-sequence match. Metadata is LEN3/SIZE2/INCR. The
aligned 16-byte span must stay within 4 KiB. Count is authoritative: RID
mismatch, early RLAST, and non-OKAY RRESP drain through beat index 3; missing
final RLAST retires there with last-match false. RRESP stays raw per event.

The top reuses unchanged AR and one explicitly re-armed R child plus a new
20-port zero-state ten-rule coordinator. Assignment counts are
10/1/3/2/1/1/6/8/1/1 with ten authored/eight realized priorities. The flat
29-port C4 top has three FSM children, 48 nets, and 46 links. Support targets
are 306/347/347. The four-subtest t/1507 generated-HDL proof must end at exact
AR/R/request/beat/transaction counts 4/13/4/13/3. `.38` owns the atomic
parser/generator/source/support/manifest/test/book/fact implementation.
