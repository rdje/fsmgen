---
id: ial2-axi-full-read-transaction-composition-first-slice
title: The bounded AXI AR R fixed-single-beat full-read composition is shipped
answers:
  - "does FSMGen ship a complete fixed-single-beat AXI read transaction composition?"
  - "what does ppif/axi_read_transaction_composition.ppif generate?"
  - "when does the AXI full-read composition arm RREADY?"
  - "what is the difference between read_request_done and read_transaction_done?"
  - "how does the AXI full-read composition handle RID mismatch missing RLAST and RRESP?"
  - "what does t/1506 prove?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.34 implement?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, ar, r, composition, transaction, single-beat, ppif, c4]
evidence: ppif/axi_read_transaction_composition.ppif; perl/FSM/IAL2/ProtocolIntent/AxiReadTransactionComposition.pm; t/1506-ial2-axi-read-transaction-composition.t; docs/book/src/16a-ial2-axi.md; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: prove -Iperl t/1506-ial2-axi-read-transaction-composition.t
---

FSMGen ships `ppif/axi_read_transaction_composition.ppif`, an additive
bounded AXI4 manager fixed-single-beat AR+R composition. The reference
generator reuses the unchanged `AxiArDriver` and `AxiRBeatAcceptor`, adds
`axi_read_transaction_coordinator`, and selects flat C4 top
`axi_read_transaction_composition`. Its report schema is
`fsmgen.ial2.protocol_intent.axi_read_transaction_composition.v1`; support ID
is `intent.ppif_axi_read_transaction_composition`.

One aligned idle address32/ID4 command is captured atomically. The coordinator
privately drives ARLEN zero, ARSIZE two, and ARBURST INCR, launches one AR
request, and arms the R child only after that request accepts. `read_busy`
spans admission through response retirement. `read_request_done` pulses when
AR completion arms R; `read_transaction_done` pulses only after the owned R
beat is captured and retires the transaction. A command while busy is ignored
rather than queued.

The accepted raw RID4/RDATA32/RRESP2/RLAST1 tuple remains observable. RID is
compared with the admitted ARID and RLAST with the fixed-one-beat expectation.
A mismatch is assertion-visible and leaves its stable match output low, but
the already-consumed beat terminally completes rather than waiting for an
impossible replacement. RRESP remains uninterpreted raw status, including
non-OKAY values; transaction completion does not claim protocol success.

The lowering path emits three IAL1 actors and schedules, three leaf FSMs, and
one selected structural-top FSM. The top has 27 public signals, three direct
children, 41 nets, and 44 resolved links. The coordinator has 18 ports, zero
procedural states, seven rule decision trees with assignment counts
6/1/3/1/1/6/1, six authored priorities, four realized resolutions, and three
alignment/RID/RLAST assertions.

`t/1506-ial2-axi-read-transaction-composition.t` has exactly four top-level
subtests for report/artifact identity, fail-closed grammar and widths, public
CLI plus Verilator/Yosys surfaces, and executable generated-top behavior. Its
runtime matrix proves misaligned no-launch, fixed AR metadata, continuous and
stalled ARREADY, stable retained payload, busy-command ignore, already-high
and delayed RVALID, raw non-OKAY capture, terminal RID and RLAST mismatches,
reset during stalled AR and armed R phases, post-reset recovery, and final
idle. Exact totals are five AR handshakes, four R handshakes, five request-done
pulses, and four transaction-done pulses; the one-event difference proves that
reset after AR acceptance cancels response ownership without fabricating R or
full completion.

Dynamic and multi-beat reads, ARLEN/RLAST counters, response aggregation,
capacity/status adapter wiring, outstanding queues, dynamic ID ordering and
demux/interleaving, extended sidebands, `.axi` aliasing, verification output,
backend variants/VHDL, direct lowering, AHB, APB, and decision 0020's
protocol-neutral transaction interface remain deferred. Contract source:
[[ial2-axi-full-read-transaction-composition-contract-selection]].
