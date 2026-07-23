---
id: ial2-axi-full-read-transaction-composition-readiness-audit
title: The bounded AXI fixed-single-beat full-read composition is ready for contract selection
answers:
  - "is the AXI AR R full-read composition ready for contract selection?"
  - "what topology should the bounded AXI full-read composition use?"
  - "when does the bounded AXI full-read composition arm R?"
  - "how does the AXI full-read composition handle RID mismatch or missing RLAST?"
  - "what does reset do between AR completion and R response?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.32 conclude?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.33?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, ar, r, composition, transaction, c4, readiness]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_FULL_READ_TRANSACTION_COMPOSITION_READINESS_AUDIT.md; docs/IAL2_AXI_MANAGER_INITIATOR_POST_R_BEAT_ACCEPTOR_NEXT_INCREMENT_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AxiArDriver.pm; perl/FSM/IAL2/ProtocolIntent/AxiRBeatAcceptor.pm; perl/FSM/IAL2/ProtocolIntent/AxiWriteTransactionComposition.pm; t/1503-ial2-axi-write-transaction-composition.t; t/1504-ial2-axi-ar-driver.t; t/1505-ial2-axi-r-beat-acceptor.t; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: rg -n 'flat three-child C4|composition_child_count.*3|PASS ar=5 r=4|RID mismatch|missing RLAST|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.33' docs/IAL2_AXI_MANAGER_INITIATOR_FULL_READ_TRANSACTION_COMPOSITION_READINESS_AUDIT.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.32` finds the bounded AXI4
fixed-single-beat AR+R full-read composition ready for exact contract
selection. It uses a flat three-child C4 top: unchanged AR driver and R beat
acceptor plus one zero-state, seven-rule transaction coordinator. Public
address32/ID4 is four-byte aligned; private AR metadata is exactly LEN0,
SIZE2, INCR.

The coordinator starts AR once, pulses request done and R arm only after AR
acceptance, and keeps aggregate busy until one owned R beat retires. Raw
RID4/RDATA32/RRESP2/RLAST1 is re-exported. Captured RID is compared with
retained ARID and captured RLAST with the fixed-one-beat expectation. Either
mismatch is assertion/status-visible but terminal; raw non-OKAY RRESP never
becomes an implicit success or suppresses completion.

Scratch evidence is clean: 18 coordinator ports, zero states, seven rules with
assignment counts 6/1/3/1/1/6/1 and four realized pulse priorities; the top
strict-checks at 27 public signals, three FSM children, 41 nets, and 44 links;
Verilator and Yosys pass. Executable HDL finishes at AR/R/request/transaction
counts 5/4/5/4, with the one-count difference proving reset cancellation after
AR completion without a phantom R or transaction completion. `.33` owns exact
public-contract selection and `.34` owns the later atomic implementation.
