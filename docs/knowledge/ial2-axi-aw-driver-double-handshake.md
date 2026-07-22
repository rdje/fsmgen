---
id: ial2-axi-aw-driver-double-handshake
title: Before the .7 correction the AXI AW driver could accept twice under held READY
answers:
  - "does one AXI AW driver command produce exactly one AW transfer?"
  - "why can axi_aw_driver produce two AW handshakes?"
  - "what blocks implementation of the AXI W driver?"
  - "is --verify-hdl enough to prove AXI transfer cardinality?"
date: 2026-07-23
status: superseded
tags: [ial2, axi, initiator, aw, valid-ready, handshake, correctness]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_POST_AW_NEXT_INCREMENT_SELECTION.md; docs/IAL2_AXI_MANAGER_INITIATOR_SINGLE_TRANSFER_CORRECTNESS_READINESS_AUDIT.md
reverify: rg -n 'HANDSHAKES=2|registered.*clears one edge|Root cause' docs/IAL2_AXI_MANAGER_INITIATOR_POST_AW_NEXT_INCREMENT_SELECTION.md docs/IAL2_AXI_MANAGER_INITIATOR_SINGLE_TRANSFER_CORRECTNESS_READINESS_AUDIT.md
---

Before `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.7`, one accepted `aw_cmd_valid`
could produce two rising-edge `AWVALID && AWREADY` transfers when `AWREADY`
remained high. The generated READY decision entered a separate deassert state,
and registered `AWVALID` cleared only on the following edge. The full
historical root-cause trace is in
`docs/IAL2_AXI_MANAGER_INITIATOR_POST_AW_NEXT_INCREMENT_SELECTION.md`.

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.6` selected the correction and `.7`
implemented it with an executable exactly-once regression before a W driver
could reuse the old timing pattern. Related architectural context:
[[ial2-axi-manager-initiator-pivot]]. Selected correction shape:
[[ial2-axi-aw-single-transfer-correction-shape]].
