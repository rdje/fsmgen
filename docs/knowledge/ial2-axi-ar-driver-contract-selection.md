---
id: ial2-axi-ar-driver-contract-selection
title: The bounded AXI4 manager AR driver contract is selected
answers:
  - "what is the exact axi-ar-driver contract?"
  - "what does IAL2-AXI-MANAGER-INITIATOR-FRONTIER.25 select?"
  - "what report schema will the AXI AR driver use?"
  - "what is the planned ppif/axi_ar_driver.ppif interface?"
  - "which test owns AXI AR driver implementation proof?"
  - "what does the AXI AR request_scope report?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, initiator, ar, read-address, contract, pnt]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_AR_DRIVER_CONTRACT_SELECTION.md; docs/IAL2_AXI_MANAGER_INITIATOR_AR_DRIVER_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AxiAwDriver.pm; t/1499-ial2-axi-aw-driver.t
reverify: rg -n 'axi-ar-driver|axi_ar_driver.v1|request_scope|t/1504|IAL2-AXI-MANAGER-INITIATOR-FRONTIER.26' docs/IAL2_AXI_MANAGER_INITIATOR_AR_DRIVER_CONTRACT_SELECTION.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.25` selects the exact additive
`(axi-ar-driver ...)` contract. Its generator is
`FSM::IAL2::ProtocolIntent::AxiArDriver`, result kind
`protocol_intent.axi_ar_driver`, schema
`fsmgen.ial2.protocol_intent.axi_ar_driver.v1`, public source
`ppif/axi_ar_driver.ppif`, and proof owner `t/1504-ial2-axi-ar-driver.t`.

The interface accepts `ar_cmd_valid`, address32, ID4, LEN8, SIZE3, BURST2, and
ARREADY, then drives ARVALID plus the matching payload and busy/done status.
The corrected six-state launch/accept rule pair provides exactly-once transfer
under held READY and stable payload under stalls.

The report adds a machine-readable `request_scope`: widths 32/4/8/3/2,
`done_event = ar_request_accepted`, and `includes_read_response = false`.
R-channel acceptance, beat accounting, and full read completion remain
explicit residue. `.26` owns implementation; `.25` changes no behavior.
