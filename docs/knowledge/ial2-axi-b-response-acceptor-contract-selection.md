---
id: ial2-axi-b-response-acceptor-contract-selection
title: The bounded AXI B response acceptor public contract is selected
answers:
  - "what is the public AXI B response acceptor PPIF syntax?"
  - "what does axi-b-response-acceptor mean?"
  - "what generator and schema own the AXI B response acceptor?"
  - "what will t/1501 test?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.13 select?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.14?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, b, response, acceptor, contract, task-tree]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_B_RESPONSE_ACCEPTOR_CONTRACT_SELECTION.md; docs/IAL2_AXI_MANAGER_INITIATOR_B_RESPONSE_ACCEPTOR_READINESS_AUDIT.md; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: rg -n 'axi-b-response-acceptor|axi_b_response_acceptor|AxiBResponseAcceptor|t/1501|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.13|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.14' docs/IAL2_AXI_MANAGER_INITIATOR_B_RESPONSE_ACCEPTOR_CONTRACT_SELECTION.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.13` selects the additive
`(axi-b-response-acceptor ...)` public contract. The parser kind is
`axi_b_response_acceptor`; generator
`FSM::IAL2::ProtocolIntent::AxiBResponseAcceptor`; result kind
`protocol_intent.axi_b_response_acceptor`; schema
`fsmgen.ial2.protocol_intent.axi_b_response_acceptor.v1`; source/module
`ppif/axi_b_response_acceptor.ppif` / `axi_b_response_acceptor`; support ID
`intent.ppif_axi_b_response_acceptor`; focused test t/1501.

The exact source uses role `subordinate-to-manager`, command
`(arm b_accept_cmd_valid)`, B-channel `bvalid`/`bready`/`bid` width 4/`bresp`
width 2, distinct captured `response_bid` width 4 / `response_bresp` width 2,
and `b_busy`/`b_done`.

The generated six-state ISF uses `accept_b over arm_b`. One arm raises BREADY
without waiting for BVALID; exactly one handshake captures ID/status and clears
ready/busy; captured outputs remain stable; one later done pulse retires the
operation. `.14` owns the atomic parser/generator/source/support/manifest/test/
book implementation. All composition, capacity, outstanding/extended response,
read, alias, verification-output, direct/backend/VHDL, AHB, and APB work stays
deferred.
