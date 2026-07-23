---
id: ial2-axi-r-beat-acceptor-contract-selection
title: The bounded AXI R beat acceptor public contract is selected
answers:
  - "what is the exact axi-r-beat-acceptor contract?"
  - "what does IAL2-AXI-MANAGER-INITIATOR-FRONTIER.29 select?"
  - "what report schema will the AXI R beat acceptor use?"
  - "what is the planned ppif/axi_r_beat_acceptor.ppif interface?"
  - "which test owns AXI R beat acceptor implementation proof?"
  - "what does the AXI R bounded_beat report mean?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, initiator, r, read-data, acceptor, contract]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_R_BEAT_ACCEPTOR_CONTRACT_SELECTION.md; docs/IAL2_AXI_MANAGER_INITIATOR_R_BEAT_ACCEPTOR_READINESS_AUDIT.md
reverify: rg -n 'axi-r-beat-acceptor|axi_r_beat_acceptor.v1|bounded_beat|t/1505|IAL2-AXI-MANAGER-INITIATOR-FRONTIER.30' docs/IAL2_AXI_MANAGER_INITIATOR_R_BEAT_ACCEPTOR_CONTRACT_SELECTION.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.29` selects the exact additive
`(axi-r-beat-acceptor ...)` public contract for implementation by `.30`.

The fixed AXI4 source uses one arm, RVALID/RREADY, RID4/RDATA32/RRESP2/RLAST1,
four stable captured outputs, busy, and beat-done. Its generated IAL1 is the
proven 13-port/six-state `arm_r`/`accept_r` receiver. The
`fsmgen.ial2.protocol_intent.axi_r_beat_acceptor.v1` report exposes
`bounded_beat.done_event = r_beat_accepted` and
`includes_read_completion = false`.

The implementation owner is `AxiRBeatAcceptor`, public source
`ppif/axi_r_beat_acceptor.ppif`, support id
`intent.ppif_axi_r_beat_acceptor`, coverage key
`ial2_ppif_axi_r_beat_acceptor_pipeline_cli`, and exact focused test t/1505.
AR/R composition and every transaction-level interpretation remain deferred.
