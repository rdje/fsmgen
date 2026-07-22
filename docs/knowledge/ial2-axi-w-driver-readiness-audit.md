---
id: ial2-axi-w-driver-readiness-audit
title: The bounded single-beat AXI W driver is ready for contract selection
answers:
  - "is the AXI W write-data driver ready to implement?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.8?"
  - "what signals belong in the first AXI W driver?"
  - "how should an AXI W driver guarantee exactly one transfer per command?"
  - "is an all-zero WSTRB legal?"
  - "what comes after the corrected AXI AW driver?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, w, valid-ready, handshake, readiness, audit]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_W_DRIVER_READINESS_AUDIT.md; docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf; ppif/axi_aw_w_valid_ready_bundle.ppif; perl/FSM/IAL2/ProtocolIntent/AxiAwDriver.pm; t/1499-ial2-axi-aw-driver.t
reverify: rg -n 'Safe first behavior boundary|Exact behavioral invariant|Target generated-ISF shape|Exact next leaf' docs/IAL2_AXI_MANAGER_INITIATOR_W_DRIVER_READINESS_AUDIT.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.8` establishes that a bounded AXI4
single-beat W driver is ready for a behavior-neutral contract selection. The
safe primitive has distinct upstream inputs (`w_cmd_valid`, 32-bit
`cmd_wdata`, four-bit `cmd_wstrb`, and `wready`) and driven outputs (`wvalid`,
32-bit `wdata`, four-bit `wstrb`, fixed-valid-beat `wlast = 1`, `w_busy`, and
one-cycle `w_done`). All four strobe bits low is a legal command.

The driver must reuse the corrected AW rule-pair shape: inline launch,
priority-resolved `launch_w`/`accept_w`, and a transaction wait on latched
`active_q`. This guarantees exactly one rising-edge `WVALID && WREADY`
acceptance and one done pulse per accepted command, even with continuously-high
READY, while holding `WDATA`, `WSTRB`, and `WLAST` stable under backpressure.

The audit selects `.9` to fix the exact public contract before implementation.
AW/W coordination, B completion, multi-beat sequencing, outstanding writes,
capacity-core integration, the decision-0020 transaction interface, aliases,
verification output, backend variants/VHDL, and AHB/APB remain deferred.

Related shipped scheduling fact:
[[ial2-axi-aw-single-transfer-correction-shape]].
