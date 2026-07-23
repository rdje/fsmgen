---
id: ial2-axi-w-driver-first-slice
title: The bounded AXI W driver ships one exactly-once single-beat transfer
answers:
  - "does FSMGen ship an AXI W write-data driver?"
  - "what does ppif/axi_w_driver.ppif generate?"
  - "does the AXI W driver hold WDATA WSTRB and WLAST under backpressure?"
  - "does one AXI W command produce exactly one transfer?"
  - "can the AXI W driver issue an all-zero-strobe transfer?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.10 implement?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, w, driver, ppif, isf, exactly-once]
evidence: ppif/axi_w_driver.ppif; perl/FSM/IAL2/ProtocolIntent/AxiWDriver.pm; t/1500-ial2-axi-w-driver.t; docs/book/src/16a-ial2-axi.md; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: prove -Iperl t/1500-ial2-axi-w-driver.t
---

FSMGen ships `ppif/axi_w_driver.ppif`, an additive bounded AXI4 W
write-data-channel driver. It lowers through generated `axi_w_driver.isf` and
`axi_w_driver.fsm` to module `axi_w_driver`, with report schema
`fsmgen.ial2.protocol_intent.axi_w_driver.v1` and support id
`intent.ppif_axi_w_driver`.

Each accepted one-shot command samples `cmd_wdata[31:0]` and
`cmd_wstrb[3:0]`, asserts `WVALID` with `WLAST=1` independently of `WREADY`,
holds `WDATA`/`WSTRB`/`WLAST` stable under backpressure, accepts exactly one
`WVALID && WREADY` transfer, and emits one `w_done` pulse. All-zero `WSTRB` is
legal. The generated schedule has six states, zero compile issues, and three
accept-over-launch priority resolutions.

`t/1500` proves the public/report/fail-closed/CLI/Verilator/Yosys surfaces and
executes generated HDL for continuous READY with zero strobes plus a stalled
one-cycle-READY command: totals are two handshakes and two done pulses, with
stable stalled payload/last and final valid/busy low.

AW/W composition, B completion, multi-beat/outstanding writes, capacity-core
integration, transaction-interface activation, aliases, verification output,
backend variants/VHDL, and AHB/APB remain deferred. Selected contract:
[[ial2-axi-w-driver-contract-selection]].
