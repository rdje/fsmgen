---
id: ial2-axi-aw-w-request-composition-contract-selection
title: The bounded AXI AW plus W request composition public contract is selected
answers:
  - "what is the public AXI write request composition clause?"
  - "what names and schema does the AXI AW W composition use?"
  - "what fixed AW metadata does the AXI write request composition emit?"
  - "what artifacts does axi_write_request_composition generate?"
  - "what does t/1502 prove?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.18?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, aw, w, composition, contract, single-beat, task-tree]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_AW_W_REQUEST_COMPOSITION_CONTRACT_SELECTION.md; docs/IAL2_AXI_MANAGER_INITIATOR_AW_W_REQUEST_COMPOSITION_READINESS_AUDIT.md; ppif/axi_aw_driver.ppif; ppif/axi_w_driver.ppif; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: rg -n 'axi-write-request-composition|axi_write_request_composition|AxiWriteRequestComposition|axi_write_request_coordinator|t/1502|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.18' docs/IAL2_AXI_MANAGER_INITIATOR_AW_W_REQUEST_COMPOSITION_CONTRACT_SELECTION.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.17` selects the exact additive
`(axi-write-request-composition ...)` contract. The public sample will be
`ppif/axi_write_request_composition.ppif`; parser kind
`axi_write_request_composition`; generator
`FSM::IAL2::ProtocolIntent::AxiWriteRequestComposition`; result kind
`protocol_intent.axi_write_request_composition`; report schema
`fsmgen.ial2.protocol_intent.axi_write_request_composition.v1`; structural top
`axi_write_request_composition`; and coordinator
`axi_write_request_coordinator`.

The aggregate captures aligned address32/AWID4/WDATA32/WSTRB4 atomically,
starts unchanged `axi_aw_driver` and `axi_w_driver` children once, fixes AWLEN
to 0, AWSIZE to 2, AWBURST to INCR, preserves arbitrary WSTRB including zero,
and joins independent child completion history into aggregate busy/done.
Aggregate done means both request channels accepted; B remains separate.

The result has three IAL1 items and full schedules, three child IAL0 artifacts,
and one selected C4 structural top. Support id is
`intent.ppif_axi_write_request_composition`, coverage is
`ial2_ppif_axi_write_request_composition_pipeline_cli`, predicted accounting is
301 protocol fixtures and 342 supported/strict entries, and focused owner
`t/1502-ial2-axi-write-request-composition.t` must prove aligned/misaligned
admission, atomic capture, simultaneous/AW-first/W-first handshakes, long
stalls, zero strobe, busy-command rejection, fixed metadata, and exact
cardinality. `.18` owns implementation; behavior has not changed yet.
