---
id: ial2-axi-w-burst4-driver-behavior
title: FSMGen ships an additive fixed-four AXI manager W burst driver
answers:
  - "does FSMGen ship a multi-beat AXI W driver?"
  - "how do I use axi w burst4 driver ppif?"
  - "how does AxiWBurst4Driver drive WLAST?"
  - "does the AXI W burst4 driver keep WVALID high between beats?"
  - "what do w beat done and w beat index mean?"
  - "what does t 1508 prove?"
  - "what are the AXI W burst4 support counts?"
  - "what shipped in IAL2-AXI-MANAGER-INITIATOR-FRONTIER.42?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, initiator, w, burst4, wlast, driver, shipped]
evidence: ppif/axi_w_burst4_driver.ppif; perl/FSM/IAL2/ProtocolIntent/AxiWBurst4Driver.pm; perl/FSM/Adapter/IAL2/PPIF.pm; t/1508-ial2-axi-w-burst4-driver.t; t/data/axi_w_burst4_driver_tb.svt; docs/book/src/16a-ial2-axi.md
reverify: prove -Iperl t/1508-ial2-axi-w-burst4-driver.t
---

FSMGen ships the additive `(axi-w-burst4-driver ...)` PPIF object through
`FSM::IAL2::ProtocolIntent::AxiWBurst4Driver`. One idle command atomically
captures four explicit data32/strobe4 tuples. The generated zero-state actor
keeps WVALID high through exactly four accepted transfers, preserves the
presented tuple during WREADY stalls, and drives WLAST `0/0/0/1`.

Every acceptance produces a level-high `w_beat_done` event with
`w_beat_index=0/1/2/3`; adjacent continuous-ready transfers can produce
adjacent high event cycles. `w_done` coincides with index three and clears
WVALID/busy. All-zero strobes are legal. A busy-time one-shot command is
ignored, and asynchronous reset aborts without fabricated events before clean
index-zero recovery.

The exact generated boundary has 18 ports, 30 signals, zero states, seven rules
at `13/6/6/6/6/1/1`, seven declared private registers, five priority
resolutions, one generated ISF, and one generated FSM/HDL entry. t/1508 passes
contract, fail-closed, CLI/artifact/Verilator/Yosys, and generated-HDL proof at
`handshakes=14 beat=14 done=3 busy_ignored=1 reset_abort=1`. Support accounting
is 307 protocol fixtures, 348 supported fixtures, and 348 strict-supported
fixtures.

The shipped single-beat `AxiWDriver` and all existing write compositions remain
unchanged. AW/address/4-KiB coupling, B completion, dynamic/general bursts,
packed/streaming payload supply, queues/outstanding, capacity integration,
aliases, decision 0020, verification output, backend variants/VHDL, AHB, and
APB remain deferred.

Selected contract:
[[ial2-axi-w-burst4-driver-contract-selection]].
