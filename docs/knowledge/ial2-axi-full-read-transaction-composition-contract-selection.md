---
id: ial2-axi-full-read-transaction-composition-contract-selection
title: The bounded AXI fixed-single-beat full-read public contract is selected
answers:
  - "what is the selected AXI full-read composition PPIF contract?"
  - "what are the AXI read transaction composition generator and report identities?"
  - "what is the exact AXI full-read coordinator schedule?"
  - "what artifacts does the AXI full-read composition generate?"
  - "what support counts will the AXI full-read composition use?"
  - "what does t 1506 have to prove?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.33 select?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.34?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, ar, r, composition, transaction, contract]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_FULL_READ_TRANSACTION_COMPOSITION_CONTRACT_SELECTION.md; docs/IAL2_AXI_MANAGER_INITIATOR_FULL_READ_TRANSACTION_COMPOSITION_READINESS_AUDIT.md; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: rg -n 'axi-read-transaction-composition|AxiReadTransactionComposition|axi_read_transaction_coordinator|304 -> 305|PASS ar=5 r=4|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.34' docs/IAL2_AXI_MANAGER_INITIATOR_FULL_READ_TRANSACTION_COMPOSITION_CONTRACT_SELECTION.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.33` selects the exact additive
`(axi-read-transaction-composition ...)` contract. The normalized parser kind
is `axi_read_transaction_composition`; the generated result kind is
`protocol_intent.axi_read_transaction_composition`; the reference generator is
`FSM::IAL2::ProtocolIntent::AxiReadTransactionComposition`; and schema v1,
public source, structural top, coordinator, support identity, and t/1506 are
all frozen.

The thirteen-anchor source exposes manager address32/ID4 command, full fixed AR
bus, raw RID4/RDATA32/RRESP2/RLAST1 bus/capture, aggregate busy, distinct
request/transaction done, and stable ID/last match status. The top has exactly
27 ports, three unchanged/new children, 41 nets, and 44 links. The coordinator
has 18 ports, zero states, seven rules with 6/1/3/1/1/6/1 assignments, six
authored priorities, four realized pulse resolutions, and alignment/RID/RLAST
assertions.

The implementation adds one PPIF support entry, moving counts to 305/346/346.
The exact four-subtest t/1506 proof ends at 5 AR, 4 R, 5 request, and 4
transaction events because one post-AR armed-R wait is deliberately reset-
aborted without phantom completion. `.34` is the atomic parser/generator/
source/support/manifest/test/book/fact implementation owner.
