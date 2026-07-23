---
id: ial2-axi-w-burst4-driver-readiness-audit
title: The additive fixed-four AXI W burst driver is ready for contract selection
answers:
  - "is the fixed-four AXI W burst driver ready to implement?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.40?"
  - "should the fixed-four AXI W payload use explicit fields, packed banks, or streaming?"
  - "how should WLAST progress across a four-beat AXI write burst?"
  - "what is the exact generated schedule for the fixed-four W driver?"
  - "why is AxiWBurst4Driver additive instead of generalizing AxiWDriver?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, w, burst4, wlast, valid-ready, readiness, audit]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_W_BURST4_DRIVER_READINESS_AUDIT.md; docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf; ppif/axi_w_driver.ppif; perl/FSM/IAL2/ProtocolIntent/AxiWDriver.pm; t/1500-ial2-axi-w-driver.t; perl/FSM/IAL2/ProtocolIntent/AxiReadBurst4TransactionComposition.pm; t/1507-ial2-axi-read-burst4-transaction-composition.t
reverify: rg -n 'Upstream payload-shape decision|Exact public boundary|Exact transfer and event lifecycle|Exact generated-IAL1 schedule|Public tooling and executable proof' docs/IAL2_AXI_MANAGER_INITIATOR_W_BURST4_DRIVER_READINESS_AUDIT.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.40` establishes that a separate bounded
AXI4 fixed-four W driver is ready for behavior-neutral public-contract
selection. It atomically captures four explicitly named data32/strobe4 tuples,
keeps WVALID high across the burst, preserves the current tuple under WREADY
backpressure, drives WLAST `0/0/0/1`, emits a beat event/index for each of
exactly four transfers, and emits final done with index three. All-zero strobes
remain legal.

Explicit fields are selected over packed data128/strobe16 banks and a streaming
producer because they preserve field-oriented PPIF reviewability and avoid a
second handshake/buffering contract. Beat zero is retained directly in the
driven WDATA/WSTRB registers; only beats one through three need private payload
storage.

The additive `AxiWBurst4Driver` preserves shipped `AxiWDriver`, whose sole beat
must continue to assert WLAST. The proven target has 18 ports, zero states,
seven rules with assignment counts `13/6/6/6/6/1/1`, seven declared private
storage registers, five realized priorities, and no compile issues. Strict
check, Verilator, Yosys, and executable HDL pass with exact totals
`handshakes=14 beat=14 done=3 busy_ignored=1 reset_abort=1`.

AW/address/4-KiB coupling, AW/W composition, B completion, dynamic/general
bursts, packed/streaming payloads, capacity integration, outstanding/queues,
aliases, decision 0020, verification output, backend variants/VHDL, AHB, and
APB remain deferred. `.41` owns exact contract selection and `.42` the atomic
implementation.

Related prerequisite selector:
[[ial2-post-axi-burst4-read-next-increment-selection]].
