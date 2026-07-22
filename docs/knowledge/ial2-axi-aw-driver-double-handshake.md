---
id: ial2-axi-aw-driver-double-handshake
title: The shipped AXI AW driver can accept twice when AWREADY stays high
answers:
  - "does one AXI AW driver command produce exactly one AW transfer?"
  - "why can axi_aw_driver produce two AW handshakes?"
  - "what blocks implementation of the AXI W driver?"
  - "is --verify-hdl enough to prove AXI transfer cardinality?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, aw, valid-ready, handshake, correctness]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_POST_AW_NEXT_INCREMENT_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AxiAwDriver.pm; ppif/axi_aw_driver.ppif
reverify: ./bin/fsmgen --quiet --strict --outdir /tmp/fsmgen-axi-aw-handshake-probe --output /tmp/fsmgen-axi-aw-handshake-probe/axi_aw_driver.sv ppif/axi_aw_driver.ppif
---

One accepted `aw_cmd_valid` can produce two rising-edge `AWVALID && AWREADY`
transfers when `AWREADY` remains high. The generated READY decision enters a
separate deassert state, and registered `AWVALID` clears only on the following
edge. The full root-cause trace and selected corrective audit owner are in
`docs/IAL2_AXI_MANAGER_INITIATOR_POST_AW_NEXT_INCREMENT_SELECTION.md`.

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.6` completed the readiness audit and
selected the correction that `.7` must implement before a W driver reuses this
timing pattern. Related architectural context:
[[ial2-axi-manager-initiator-pivot]]. Selected correction shape:
[[ial2-axi-aw-single-transfer-correction-shape]].
