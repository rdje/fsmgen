---
id: ial2-axi-manager-capacity-status-generator-first-slice
title: AXI manager capacity/status in-process generator first slice
answers:
  - "is the AXI manager capacity/status IAL2 generator shipped?"
  - "how do I use the AXI manager capacity/status IAL2 generator?"
  - "does AXI manager capacity/status lower directly to .fsm?"
  - "is public .ppif syntax shipped for AXI manager capacity/status?"
  - "what does the first AXI manager capacity/status generator report?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, capacity, status, generator, isf, lowering]
evidence: docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_GENERATOR_FIRST_SLICE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/book/src/14-feature-backlog.md
reverify: prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t
---

`FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus` is the first shipped
AXI manager capacity/status IAL2 generator. It accepts a structured in-process
AXI4 manager contract with explicit read/write pending depths, `try` policy,
abstract read/write submit and completion events, namespaced status outputs,
and optional source anchors. It emits reviewable generated `.isf`, parses that
through `FSM::Adapter::ISF`, lowers through `FSM::Scheduler::ISF` to
reviewable `.fsm`, and reaches SystemVerilog generation from the scheduled
artifact.

The report schema is
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1`. The slice is a
capacity/status shell only: public `.ppif` syntax, profile aliases, IDs,
ordering, response matching, bursts, queued/blocking policy, and VHDL backend
work remain future exact-owner residue.
