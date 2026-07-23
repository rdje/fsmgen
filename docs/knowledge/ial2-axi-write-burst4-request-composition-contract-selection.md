---
id: ial2-axi-write-burst4-request-composition-contract-selection
title: The exact fixed-four AXI AW plus W request composition contract is selected
answers:
  - "what is the exact AXI write burst4 request composition syntax?"
  - "what generator implements the fixed-four AXI write request?"
  - "what is the exact AXI write burst4 request coordinator?"
  - "what are the exact AXI write burst4 request report and residue policies?"
  - "what will t/1509 prove?"
  - "what does IAL2-AXI-MANAGER-INITIATOR-FRONTIER.46 implement?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, aw, w, burst4, composition, contract]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_BURST4_WRITE_REQUEST_COMPOSITION_CONTRACT_SELECTION.md; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: rg -n 'Selected identity|Exact public source|Exact coordinator IAL1|Exact flat C4 top|Exact t/1509 proof' docs/IAL2_AXI_MANAGER_INITIATOR_BURST4_WRITE_REQUEST_COMPOSITION_CONTRACT_SELECTION.md
---

The exact additive contract is `(axi-write-burst4-request-composition ...)`,
kind `axi_write_burst4_request_composition`, generator
`FSM::IAL2::ProtocolIntent::AxiWriteBurst4RequestComposition`, schema
`fsmgen.ial2.protocol_intent.axi_write_burst4_request_composition.v1`, and
generic source `ppif/axi_write_burst4_request_composition.ppif`.

One idle command atomically captures address32, ID4, four data32, and four
strobe4 fields. The top reuses unchanged AW and W-burst4 children, fixes
LEN3/SIZE2/INCR, uses the exhaustively equivalent renderer-safe aligned
16-byte/4-KiB predicate, exposes the W child's beat event/index directly, and
joins AW plus final-W completion into request-only done.

The exact coordinator is a 29-port, 57-signal, zero-state, six-rule actor with
assignment counts `16/2/1/1/5/1`, seven authored priority declarations, five
realized resolutions, and two compatible completion-history fan-ins. The flat
top has 29 public signals, three children, 66 nets, 46 declared links, and 52
resolved links. t/1509 will hold support at exact targets 308/349/349 and prove
`AW/W/beat/done=5/18/18/4` in assertion-disabled and assertion-enabled runs.
Implementation owner is `.46`.
