---
id: ial2-axi-aw-w-request-composition-first-slice
title: The bounded AXI AW plus W single-beat request composition is shipped
answers:
  - "does FSMGen ship an AXI AW W write request composition?"
  - "what does ppif/axi_write_request_composition.ppif generate?"
  - "what does write_done mean for the AXI write request composition?"
  - "how are independent AW and W completion orders joined?"
  - "does the AXI write request composition allow zero WSTRB?"
  - "what does t/1502 prove?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.18 implement?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, aw, w, composition, single-beat, ppif, c4]
evidence: ppif/axi_write_request_composition.ppif; perl/FSM/IAL2/ProtocolIntent/AxiWriteRequestComposition.pm; t/1502-ial2-axi-write-request-composition.t; docs/book/src/16a-ial2-axi.md; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: prove -Iperl t/1502-ial2-axi-write-request-composition.t
---

FSMGen ships `ppif/axi_write_request_composition.ppif`, an additive bounded
AXI4 manager-side single-beat AW+W request composition. It lowers through three
generated IAL1 actors and three child FSMs—unchanged `axi_aw_driver`, unchanged
`axi_w_driver`, and `axi_write_request_coordinator`—into selected three-child
C4 structural top `axi_write_request_composition`. The report schema is
`fsmgen.ial2.protocol_intent.axi_write_request_composition.v1`; support ID is
`intent.ppif_axi_write_request_composition`.

One aligned idle command atomically captures 32-bit AWADDR, four-bit AWID,
32-bit WDATA, and four-bit WSTRB, then starts AW and W once. AWLEN is fixed to
zero, AWSIZE to two, AWBURST to INCR, WLAST to one, and every WSTRB value
including zero remains legal. Misaligned address bits `[1:0]` guard both child
launches and have a generated assertion. A one-cycle command while aggregate
busy is ignored; no queue is implied.

The coordinator remembers AW and W child completion independently, so either
channel may handshake first under arbitrary backpressure. `write_done` pulses
once only after both request-channel handshakes; it does not mean B response or
full write-transaction completion. The checked-in B acceptor remains separate.
Both child busy outputs terminate at coordinator inputs and defensively guard
launch; this internal C4 refinement is behavior-neutral for the reachable idle
schedule and prevents the structural compiler from rejecting unconnected
realized child ports.

`t/1502-ial2-axi-write-request-composition.t` proves the public/report,
fail-closed, support/CLI/artifact, Verilator/Yosys, and generated structural-top
contracts. Its executable top covers misaligned no-launch, atomic capture,
simultaneous-ready, AW-first, W-first, four-cycle stalls, ignored busy command,
zero strobe, fixed metadata, and exact totals of three AW handshakes, three W
handshakes, and three aggregate done pulses with final outputs idle.

B integration, capacity-core integration, full transaction completion,
multi-beat and narrow/unaligned behavior, outstanding queues, AR/R, `.axi`
aliasing, verification output, backend variants/VHDL, direct lowering, AHB,
and APB remain deferred. Selected contract:
[[ial2-axi-aw-w-request-composition-contract-selection]].
