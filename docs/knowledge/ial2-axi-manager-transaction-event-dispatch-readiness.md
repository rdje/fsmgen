---
id: ial2-axi-manager-transaction-event-dispatch-readiness
title: AXI manager transaction event dispatch readiness selects additive fan-in
answers:
  - "is the codebase ready for AXI transaction event dispatch?"
  - "does AXI transaction event dispatch need IAL1 or IAL0 prerequisites?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.15?"
  - "how will per-transaction AXI events fan into capacity/status?"
  - "can distinct AXI transaction events reach SystemVerilog?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, transaction-envelope, event-dispatch, readiness, task-tree]
evidence: docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Adapter/ISF/Parser.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/Emitter/FSM.pm; perl/FSM/ExpressionNamer.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'Readiness Conclusion|Selected Implementation Boundary|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.15|OR fan-in|transaction_event_dispatch|bounded OR|AXI transaction event dispatch' docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.14` selected the implementation boundary
for AXI manager transaction event dispatch and direction fan-in.

No separate IAL1, IAL0, or SystemVerilog prerequisite is required first for
this exact slice. A temporary probe verified that an in-memory `.isf` rule
guard shaped as `(& (| req0 req1) (! (| done0 done1)) (== pending_q 0))`
lowers to `.fsm` and SystemVerilog through the existing path.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.15` shipped that implementation. It adds
unique per-transaction request/completion event inputs, scalar one-event
compatibility, OR fan-in guards for multi-event direction groups, additive
`transaction_event_dispatch` report metadata, a public `.ppif` sample, and the
bounded IAL1 OR/negated-OR guard conflict proof needed by the generated rule
matrix.

ID allocation, ordering, response matching, bursts, queued/blocking policy,
profile aliases, full AXI manager syntax, and VHDL remain future exact-owner
work.
