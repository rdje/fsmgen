---
id: ial2-axi-read-burst4-transaction-composition-readiness-audit
title: The fixed-four AXI manager read transaction composition is ready for contract selection
answers:
  - "is the fixed-four AXI multi-beat read composition ready?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.36 conclude?"
  - "why is fixed four beats selected before dynamic ARLEN?"
  - "how should the AXI read composition handle early RLAST?"
  - "does RID mismatch terminate a multi-beat AXI read?"
  - "does non-OKAY RRESP stop or drain the fixed-four AXI read?"
  - "how is an AXI fixed-four read kept within 4 KiB?"
  - "can the unchanged one-beat R acceptor be reused for four beats?"
  - "what are the fixed-four AXI read topology and schedule counts?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.37?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, initiator, ar, r, burst4, multi-beat, rlast, drain, c4, readiness]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_BURST4_READ_TRANSACTION_COMPOSITION_READINESS_AUDIT.md; docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf; perl/FSM/IAL2/ProtocolIntent/AxiReadTransactionComposition.pm; perl/FSM/IAL2/ProtocolIntent/AxiRBeatAcceptor.pm; t/1506-ial2-axi-read-transaction-composition.t; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: rg -n 'fixed four|Beat count is authoritative|signal_count.*29|composition_net_count.*48|PASS ar=4 r=13|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.37' docs/IAL2_AXI_MANAGER_INITIATOR_BURST4_READ_TRANSACTION_COMPOSITION_READINESS_AUDIT.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.36` finds a fixed four-beat,
full-width INCR AXI4 manager read ready for exact contract selection. It uses
fixed `ARLEN=3`, `ARSIZE=2`, and `ARBURST=INCR`, retained ID4, a two-bit beat
index, and an aligned 16-byte admission span that cannot cross 4 KiB. Dynamic
ARLEN is deferred because it combines repeated receive proof with a new
command API, range/counter semantics, and dynamic boundary arithmetic.

The exact architecture is a flat three-child C4 top: unchanged AR driver,
unchanged explicitly re-armed one-beat R acceptor, and a new zero-state
20-port/ten-rule coordinator. The public top has 29 signals, three generated
FSM children, 48 nets, and 46 resolved links. Coordinator assignment counts
are 10/1/3/2/1/1/6/8/1/1 with ten authored and eight realized priorities.

Beat count is authoritative. Early RLAST and RID mismatch set sticky match
status false but still drain all four expected transfers. Missing final RLAST
retires at the fourth transfer with last-match false. Non-OKAY RRESP never
changes control: every raw RRESP is sampled with `read_beat_done`; sticky
response aggregation and output banks remain capacity/status responsibilities.
Continuous RVALID is safe across the ready-low re-arm bubble because the AXI
subordinate holds valid/payload until handshake.

Temporary strict IAL1/C4 checks, Verilator, Yosys, and executable HDL pass at
`ar=4 r=13 request=4 beat=13 transaction=3`, including illegal-address
rejection, busy-command ignore, four-beat error drain, reset abort, and
recovery. `.37` owns behavior-neutral exact contract selection and `.38` the
later atomic implementation.
