---
id: ial2-axi-full-write-transaction-composition-contract-selection
title: Exact bounded AXI full-write transaction composition contract
answers:
  - "what is the exact AXI full-write transaction composition public contract?"
  - "what does axi-write-transaction-composition mean?"
  - "what names and widths does the AXI full-write composition use?"
  - "what artifacts will axi_write_transaction_composition generate?"
  - "what does IAL2-AXI-MANAGER-INITIATOR-FRONTIER.22 implement?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, aw, w, b, composition, transaction, contract, c4]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_FULL_WRITE_TRANSACTION_COMPOSITION_CONTRACT_SELECTION.md; docs/IAL2_AXI_MANAGER_INITIATOR_FULL_WRITE_TRANSACTION_COMPOSITION_READINESS_AUDIT.md; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: rg -n 'axi-write-transaction-composition|axi_write_transaction_composition|AxiWriteTransactionComposition|flat_single_beat_aw_w_b_transaction|t/1503|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.22' docs/IAL2_AXI_MANAGER_INITIATOR_FULL_WRITE_TRANSACTION_COMPOSITION_CONTRACT_SELECTION.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.21` selects additive object
`(axi-write-transaction-composition ...)`, kind
`axi_write_transaction_composition`, generator
`FSM::IAL2::ProtocolIntent::AxiWriteTransactionComposition`, schema
`fsmgen.ial2.protocol_intent.axi_write_transaction_composition.v1`, public
source/top `axi_write_transaction_composition`, coordinator
`axi_write_transaction_coordinator`, support id
`intent.ppif_axi_write_transaction_composition`, and focused `t/1503`.

The public AXI4 `manager` object has atomic address32/AWID4/WDATA32/WSTRB4
command fields, the shipped AW/W bus, BVALID/BREADY/BID4/BRESP2 plus stable
captured BID/BRESP, and status `write_busy`, `write_request_done`,
`write_transaction_done`, and `response_id_match`. AW is fixed LEN0/SIZE2/INCR;
W is one final beat and zero strobe remains legal.

Generation extracts the unchanged AW/W/request-coordinator leaves from a
private-binding `AxiWriteRequestComposition` result, omits its nested top,
reuses the unchanged B acceptor, adds one exact zero-state seven-rule
transaction coordinator, and selects one flat five-child C4 top. B arms only
after request done. Captured BID is compared with retained AWID; mismatch sets
match status zero, asserts, and still terminally completes. Raw BRESP is not
equated with success. The result has five IAL1 schedules and six IAL0 artifacts
(five leaf FSMs plus the top).

`.22` owns end-to-end implementation, public source, counts 302/343/343,
manifest, exact four-subtest t/1503 proof, mdBook, and durable synchronization.
