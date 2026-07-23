---
id: ial2-axi-ar-driver-readiness-audit
title: The bounded AXI4 manager AR driver readiness boundary is fixed
answers:
  - "what is the audited AXI AR driver interface?"
  - "what does ar_done mean in the planned AXI AR driver?"
  - "which AR payload fields will the bounded driver carry?"
  - "does the AXI AR driver complete a read transaction?"
  - "which schedule will the AXI AR driver use?"
  - "what implements IAL2-AXI-MANAGER-INITIATOR-FRONTIER.24?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, initiator, ar, read-address, readiness, schedule]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_AR_DRIVER_READINESS_AUDIT.md; docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf; docs/AXI_VALID_READY_INTENT_PROBE.md; perl/FSM/IAL2/ProtocolIntent/AxiAwDriver.pm; t/1499-ial2-axi-aw-driver.t
reverify: rg -n 'complete core read-request tuple|request-issued|six states|t/1504' docs/IAL2_AXI_MANAGER_INITIATOR_AR_DRIVER_READINESS_AUDIT.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.24` fixes the safe boundary for a
standalone AXI4 manager AR channel driver. It atomically captures one idle
command carrying address32, ID4, LEN8, SIZE3, and BURST2; asserts ARVALID
without waiting for ARREADY; holds VALID and all payload fields through
backpressure; accepts exactly once; and pulses done once.

The done event means only that one `ARVALID && ARREADY` read-address request
was accepted. It does not mean an R beat arrived or the read transaction
completed. RREADY, RID/RDATA/RRESP/RLAST capture, beat accounting, ID matching,
and full read completion remain future composition owners. A complete manager
must eventually accept all R beats described by the issued request.

The generator will mirror the corrected AW rule-pair schedule: one inline
launch, `accept_ar` priority over `launch_ar`, six transaction states, and
exactly three priority resolutions for active, busy, and valid. Expected
artifacts are one generated `axi_ar_driver.isf`, one
`axi_ar_driver.fsm`, and the selected HDL driver module through the mandatory
IAL2 -> IAL1 -> IAL0 path.

The next leaf, `.25`, owns exact public clause/module/report spelling and the
complete implementation contract. `.24` changes no behavior.
