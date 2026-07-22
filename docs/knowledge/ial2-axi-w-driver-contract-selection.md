---
id: ial2-axi-w-driver-contract-selection
title: The first AXI W driver contract is axi-w-driver with a fixed one-beat schedule
answers:
  - "what is the selected AXI W driver PPIF syntax?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.9?"
  - "what module and schema will the AXI W driver use?"
  - "what does IAL2-AXI-MANAGER-INITIATOR-FRONTIER.10 implement?"
  - "how are WDATA WSTRB and WLAST represented in the first W driver?"
  - "what test owns the first AXI W driver?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, w, valid-ready, contract, ppif, isf]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_W_DRIVER_CONTRACT_SELECTION.md; docs/IAL2_AXI_MANAGER_INITIATOR_W_DRIVER_READINESS_AUDIT.md; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: rg -n 'Selected public source|Exact generated IAL1 target|Exact report contract|Implementation owner' docs/IAL2_AXI_MANAGER_INITIATOR_W_DRIVER_CONTRACT_SELECTION.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.9` selects an additive public
`(axi-w-driver ...)` contract: parser kind `axi_w_driver`, generator
`FSM::IAL2::ProtocolIntent::AxiWDriver`, result kind
`protocol_intent.axi_w_driver`, report schema
`fsmgen.ial2.protocol_intent.axi_w_driver.v1`, source
`ppif/axi_w_driver.ppif`, actor/module `axi_w_driver`, support id
`intent.ppif_axi_w_driver`, and focused owner
`t/1500-ial2-axi-w-driver.t`.

The source has distinct command inputs (`w_cmd_valid`, `cmd_wdata[31:0]`,
`cmd_wstrb[3:0]`, `wready`) and driven outputs (`wvalid`, `wdata[31:0]`,
`wstrb[3:0]`, scalar `wlast`, `w_busy`, `w_done`). `WLAST` is fixed high for
the one valid beat and all-zero WSTRB remains legal. The exact IAL1 target is
the six-state priority-resolved `launch_w`/`accept_w` schedule with a latched
`active_q` wait, guaranteeing one acceptance per command.

`.10` owns implementation across the PPIF adapter, new generator/source,
support accounting, capability manifest, focused generated-HDL cardinality
test, and mdBook. AW/W composition, B completion, multi-beat/outstanding
writes, capacity integration, transaction-interface activation, aliases,
verification output, backend variants/VHDL, and AHB/APB remain deferred.

Readiness evidence: [[ial2-axi-w-driver-readiness-audit]].
