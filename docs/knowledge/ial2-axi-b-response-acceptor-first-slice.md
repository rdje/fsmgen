---
id: ial2-axi-b-response-acceptor-first-slice
title: The bounded AXI B acceptor ships one explicitly armed response capture
answers:
  - "does FSMGen ship an AXI B write-response acceptor?"
  - "what does ppif/axi_b_response_acceptor.ppif generate?"
  - "does the AXI B acceptor drive BREADY before BVALID?"
  - "does one AXI B arm accept exactly one response?"
  - "when are BID and BRESP captured?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.14 implement?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, b, response, acceptor, ppif, isf, exactly-once]
evidence: ppif/axi_b_response_acceptor.ppif; perl/FSM/IAL2/ProtocolIntent/AxiBResponseAcceptor.pm; t/1501-ial2-axi-b-response-acceptor.t; docs/book/src/16a-ial2-axi.md; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: prove -Iperl t/1501-ial2-axi-b-response-acceptor.t
---

FSMGen ships `ppif/axi_b_response_acceptor.ppif`, an additive bounded AXI4
manager-side B write-response acceptor. It lowers through generated
`axi_b_response_acceptor.isf` and `axi_b_response_acceptor.fsm` to module
`axi_b_response_acceptor`, with report schema
`fsmgen.ial2.protocol_intent.axi_b_response_acceptor.v1` and support ID
`intent.ppif_axi_b_response_acceptor`.

Each accepted one-shot `b_accept_cmd_valid` arm asserts `BREADY` without
waiting for `BVALID`. Exactly one `BVALID && BREADY` handshake captures
four-bit `BID` into `response_bid` and two-bit `BRESP` into `response_bresp`,
clears `BREADY`/`b_busy`, and produces one later `b_done` pulse. Unarmed
`BVALID` cannot handshake, and captured outputs remain stable until replaced by
a later accepted response. The generated schedule has six states, zero compile
issues, and three `accept_b`-over-`arm_b` priority resolutions.

`t/1501` proves the public/report/fail-closed/CLI/Verilator/Yosys surfaces and
executes generated HDL for unarmed `BVALID`, already-high held `BVALID`, and a
second response delayed four cycles after arming. Totals are exactly two
handshakes and two done pulses, with correct stable captures and final
ready/busy low.

AW/W coordination, automatic capacity-core integration, back-to-back buffering,
outstanding or extended responses, complete write transactions, transaction-
interface activation, aliases, verification output, backend variants/VHDL,
and AHB/APB remain deferred. Selected contract:
[[ial2-axi-b-response-acceptor-contract-selection]].
