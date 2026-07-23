---
id: ial2-axi-read-burst4-transaction-composition-behavior
title: The fixed-four AXI manager read transaction composition ships
answers:
  - "does FSMGen ship a multi-beat AXI read initiator composition?"
  - "how does the fixed-four AXI read composition handle RLAST mismatch?"
  - "how does the AXI burst4 read composition reuse the R acceptor?"
  - "what does AXI burst4 read beat done report?"
  - "does the AXI burst4 read composition aggregate RRESP?"
  - "what counts does the AXI burst4 generated HDL proof establish?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.38 ship?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, initiator, ar, r, burst4, multi-beat, composition, behavior]
evidence: perl/FSM/IAL2/ProtocolIntent/AxiReadBurst4TransactionComposition.pm; perl/FSM/Adapter/IAL2/PPIF.pm; ppif/axi_read_burst4_transaction_composition.ppif; t/1507-ial2-axi-read-burst4-transaction-composition.t; t/data/axi_read_burst4_transaction_composition_tb.svt; docs/book/src/16a-ial2-axi.md
reverify: prove -Iperl t/1507-ial2-axi-read-burst4-transaction-composition.t && ./bin/fsmgen --quiet --strict --check --json ppif/axi_read_burst4_transaction_composition.ppif && ./bin/fsmgen --verify-hdl ppif/axi_read_burst4_transaction_composition.ppif
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.38` ships the additive
`(axi-read-burst4-transaction-composition ...)` source and
`FSM::IAL2::ProtocolIntent::AxiReadBurst4TransactionComposition`. It fixes
LEN3/SIZE2/INCR for four full-width beats and admits only four-byte-aligned
16-byte spans contained within one 4-KiB region. The existing fixed-single
source and generator remain unchanged.

The three-child C4 top reuses the unchanged AR driver and explicitly re-arms
one unchanged single-beat R acceptor four times. Request, raw beat, and
transaction events are distinct; a two-bit beat index identifies the captured
tuple. RID and expected RLAST-sequence match are sticky. Count is authoritative:
RID mismatch, early RLAST, and non-OKAY RRESP drain through the fourth accepted
beat, while missing final RLAST retires there with last-match false. RRESP is
raw per beat and is not aggregated.

The coordinator has 20 ports, zero states, ten rules, and eight realized
priorities. The 29-port top has three children, 48 nets, and 46 resolved links.
Support accounting is 306 protocol fixtures and 347 supported/strict-supported
fixtures. `t/1507` proves parser/report/schedule/CLI/semantic/outdir/HDL behavior,
Verilator and Yosys validation, and exact generated-HDL counts
AR/R/request/beat/transaction = 4/13/4/13/3 across illegal commands, a busy
ignore, an error drain, reset abort, and recovery.
