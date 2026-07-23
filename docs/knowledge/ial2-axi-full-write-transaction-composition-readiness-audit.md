---
id: ial2-axi-full-write-transaction-composition-readiness-audit
title: The bounded AXI single-beat full-write composition is ready for contract selection
answers:
  - "is the AXI AW W B full-write composition ready for contract selection?"
  - "can the AXI write request composition top be nested as a C4 child?"
  - "what topology should the AXI full-write composition use?"
  - "when should the bounded AXI full-write composition arm B?"
  - "how should the AXI full-write composition handle BID mismatch?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.20 conclude?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.21?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, aw, w, b, composition, transaction, c4, readiness]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_FULL_WRITE_TRANSACTION_COMPOSITION_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AxiWriteRequestComposition.pm; perl/FSM/IAL2/ProtocolIntent/AxiBResponseAcceptor.pm; perl/FSM/Composition/GeneratedChildRealizer.pm; docs/COMPOSITION_LEGACY_MAPPING.md; t/1501-ial2-axi-b-response-acceptor.t; t/1502-ial2-axi-write-request-composition.t; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: rg -n 'flat five-child C4|does not support nested|B only after|BID.*retained|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.20|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.21' docs/IAL2_AXI_MANAGER_INITIATOR_FULL_WRITE_TRANSACTION_COMPOSITION_READINESS_AUDIT.md docs/COMPOSITION_LEGACY_MAPPING.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.20` finds the bounded AXI4
single-beat AW+W+B full-write composition ready for exact contract selection.
It must use a flat five-child C4 top: unchanged AW, W, request-coordinator, and
B actors plus one new rule-only transaction coordinator. The active compiler
rejects the shipped request composition's `?top` artifact as a `?fsmc` child,
so the full generator invokes `AxiWriteRequestComposition`, extracts its three
IAL1/leaf-IAL0 children through a private `_i` handoff namespace, and omits the
nested top from the full result.

The outer coordinator atomically captures the public aligned request/AWID,
starts the private request once, retains aggregate busy, relays a distinct
request-done pulse, and arms B only after both AW and W transfer. An already-
high legal BVALID must be held until the later BREADY. On B done, captured BID
is compared with retained AWID. Match status is held; mismatch is assertion-
visible but still terminally completes because the response was already
consumed. Raw captured BRESP is re-exported and never equated with success.

Scratch evidence passes private-namespace generation, a zero-state seven-rule
coordinator schedule, five-child C4 strict check, and 2,866-line/six-module HDL
emission. RAM-guard false-high readings safely stopped optional Verilator/Yosys
probes; implementation must run them. `.21` owns exact syntax, identities,
wiring, report, diagnostics, proof, and the following implementation leaf.
