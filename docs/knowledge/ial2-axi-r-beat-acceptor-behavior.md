---
id: ial2-axi-r-beat-acceptor-behavior
title: The bounded AXI R-beat acceptor ships one explicitly armed raw beat capture
answers:
  - "does FSMGen ship an AXI R read-data beat acceptor?"
  - "what does ppif/axi_r_beat_acceptor.ppif generate?"
  - "does the AXI R acceptor drive RREADY before RVALID?"
  - "does one AXI R arm accept exactly one beat?"
  - "when are RID RDATA RRESP and RLAST captured?"
  - "what does r_beat_done mean?"
  - "does the bounded R acceptor complete an AXI read?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, initiator, r, read-data, acceptor, ppif, isf, exactly-once]
evidence: ppif/axi_r_beat_acceptor.ppif; perl/FSM/IAL2/ProtocolIntent/AxiRBeatAcceptor.pm; t/1505-ial2-axi-r-beat-acceptor.t; docs/book/src/16a-ial2-axi.md; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: prove -Iperl t/1505-ial2-axi-r-beat-acceptor.t
---

FSMGen ships `ppif/axi_r_beat_acceptor.ppif`, an additive bounded AXI4
manager-side R read-data beat acceptor. It lowers through generated
`axi_r_beat_acceptor.isf` and `axi_r_beat_acceptor.fsm` to module
`axi_r_beat_acceptor`, with report schema
`fsmgen.ial2.protocol_intent.axi_r_beat_acceptor.v1` and support ID
`intent.ppif_axi_r_beat_acceptor`.

Each idle one-shot `r_accept_cmd_valid` arm asserts `RREADY` without waiting
for `RVALID`. Exactly one `RVALID && RREADY` handshake captures four-bit `RID`,
32-bit `RDATA`, two-bit `RRESP`, and scalar `RLAST` raw into the corresponding
`response_*` outputs, clears `RREADY`/`r_busy`, and produces one later
`r_beat_done` pulse. Unarmed `RVALID` cannot handshake, and captured outputs
remain stable until replaced by a later accepted beat. A command presented
while the receiver is busy does not add a second ownership window.

The mandatory IAL2 -> generated IAL1 -> IAL0 -> HDL path exposes 13 ports and
six transaction states. Its `arm_r` and `accept_r` rules have exactly 3 and 7
assignments, no compile issues, and three `accept_r`-over-`arm_r` priority
resolutions.

The four-subtest `t/1505` proves the exact report, ordered residue, fail-closed
width/reset/object/binding behavior, support/strict/semantic/schedule/outdir
surfaces, Verilator and Yosys, and executable HDL. Runtime cases cover unarmed,
already-high held-valid with later input mutation, four-cycle delayed-valid,
busy-command ignore, idle and active reset, post-reset recovery, and one-cycle
valid. Totals are exactly three handshakes and three beat-done pulses; the last
raw capture is `RID=5`, `RDATA=0x0badc0de`, `RRESP=0`, `RLAST=1`.

`r_beat_done` means only that one owned R beat was accepted. It does not imply
`RLAST`, successful `RRESP`, ID matching, ARLEN satisfaction, or complete read
transaction retirement. AR coordination, repeated/multi-beat reception,
length/last validation, response interpretation, capacity integration,
outstanding/back-to-back operation, extended sidebands, profile aliases,
verification output, and backend variants remain explicit residue. Selected
contract: [[ial2-axi-r-beat-acceptor-contract-selection]].
