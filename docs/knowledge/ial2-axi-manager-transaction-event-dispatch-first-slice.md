---
id: ial2-axi-manager-transaction-event-dispatch-first-slice
title: AXI manager transaction event dispatch is shipped
answers:
  - "is AXI transaction event dispatch shipped?"
  - "how does AXI transaction event dispatch work?"
  - "what sample covers AXI transaction event dispatch?"
  - "what does transaction_event_dispatch report?"
  - "does AXI transaction event dispatch implement ID allocation?"
  - "does IAL1 support the OR fan-in guards for AXI transaction events?"
date: 2026-06-12
status: current
tags: [ial2, ial1, axi, manager, transaction-envelope, event-dispatch, systemverilog]
evidence: docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md; ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'transaction_event_dispatch|per_transaction_event_fanin|axi_manager_capacity_status_transaction_event_dispatch|bounded OR|OR fan-in|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.15' docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Scheduler/ISF/LoweringIR.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

AXI manager transaction event dispatch is shipped under the existing public
`.ppif` `manager-capacity-status` object.

The checked-in sample is
`ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif`, support
accounted as
`intent.ppif_axi_manager_capacity_status_transaction_event_dispatch`.

Distinct transaction request/completion events become generated IAL1 inputs.
One-event direction groups stay scalar. Multi-event direction groups lower as
OR fan-in guards and reach generated `.fsm` plus SystemVerilog through the
existing IAL2 -> IAL1 -> IAL0 path.

Schedule/report JSON keeps schema
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1` and additively
emits `transaction_event_dispatch` with mode
`per_transaction_event_fanin`, per-direction request/completion event lists,
and request/completion fan-in expressions.

This slice also widened the IAL1 rule-conflict proof to understand the bounded
OR/negated-OR generated guard shape used by the capacity/status matrix.

It does not implement ID allocation, dynamic user-ID validation, response
matching, ordering, interleaving, bursts, queued/blocking policy, full AXI
manager syntax, aliases, or VHDL.
