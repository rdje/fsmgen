---
id: ial2-axi-full-write-transaction-composition-first-slice
title: The bounded AXI AW W B single-beat full-write composition is shipped
answers:
  - "does FSMGen ship a complete single-beat AXI write transaction composition?"
  - "what does ppif/axi_write_transaction_composition.ppif generate?"
  - "when does the AXI full-write composition arm BREADY?"
  - "what is the difference between write_request_done and write_transaction_done?"
  - "how does the AXI full-write composition handle BID mismatch and BRESP?"
  - "what does t/1503 prove?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.22 implement?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, aw, w, b, composition, transaction, single-beat, ppif, c4]
evidence: ppif/axi_write_transaction_composition.ppif; perl/FSM/IAL2/ProtocolIntent/AxiWriteTransactionComposition.pm; t/1503-ial2-axi-write-transaction-composition.t; docs/book/src/16a-ial2-axi.md; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: prove -Iperl t/1503-ial2-axi-write-transaction-composition.t
---

FSMGen ships `ppif/axi_write_transaction_composition.ppif`, an additive
bounded AXI4 manager single-beat AW+W+B composition. It lowers through five
generated IAL1 actors and schedules into five leaf FSMs and selected flat C4
top `axi_write_transaction_composition`. The report schema is
`fsmgen.ial2.protocol_intent.axi_write_transaction_composition.v1`; support ID
is `intent.ppif_axi_write_transaction_composition`.

The generator invokes `AxiWriteRequestComposition` with private command/status
bindings, retains its unchanged AW driver, W driver, and request-coordinator
leaves, and omits the private nested request top. It reuses the unchanged B
acceptor and adds a zero-state, seven-rule transaction coordinator. The C4 top
therefore has five direct children and 29 public ports rather than nesting one
structural top inside another.

One aligned idle command atomically captures 32-bit AWADDR, four-bit AWID,
32-bit WDATA, and four-bit WSTRB. AWLEN is zero, AWSIZE two, AWBURST INCR,
WLAST one, and zero WSTRB remains legal. B is not armed until both AW and W
have transferred. `write_request_done` pulses when request completion arms B;
`write_transaction_done` pulses only after the B handshake/capture retires the
transaction. `write_busy` remains high across both phases and a command while
busy is ignored rather than queued.

Captured BID is compared with the AWID retained at admission. A match reports
`response_id_match=1`. A mismatch is assertion-visible and reports zero, but
the already-consumed response still terminally completes. Captured BRESP is
the raw two-bit response, including non-OKAY values; full completion does not
claim protocol success.

`t/1503-ial2-axi-write-transaction-composition.t` has exactly four top-level
subtests for report/artifact identity, fail-closed grammar, public CLI and
Verilator/Yosys surfaces, and generated-top behavior. Its executable proof
covers misaligned no-launch, atomic capture, simultaneous/AW-first/W-first
request completion, request stalls, already-high and delayed BVALID, B gating, aggregate busy,
ignored busy command, zero strobe, fixed metadata, raw non-OKAY response,
matched and terminal mismatched IDs, exact 3/3/3 AW/W/B handshakes, distinct
completion pulses, and final idle.

Capacity integration, outstanding queues, dynamic ID allocation/ordering,
multi-beat and narrow/unaligned behavior, extended AXI attributes, AR/R,
`.axi` aliasing, verification output, backend variants/VHDL, direct lowering,
AHB, APB, and decision 0020's protocol-neutral transaction interface remain
deferred. Contract source:
[[ial2-axi-full-write-transaction-composition-contract-selection]].
