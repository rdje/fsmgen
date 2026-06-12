---
id: ial2-axi-manager-capacity-status-readiness
title: AXI manager capacity/status can start as an in-process IAL2 generator
answers:
  - "is the codebase ready for an AXI manager capacity/status IAL2 implementation?"
  - "should AXI manager capacity/status start as public .ppif syntax?"
  - "does AXI manager capacity/status need new IAL1 features first?"
  - "what is the next AXI manager capacity/status implementation boundary?"
  - "which tests should cover the first capacity/status generator?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, capacity, status, readiness]
evidence: docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'Readiness Conclusion|Selected First Implementation Boundary|FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus|t/1437-axi-ial2-manager-capacity-status-generator|public \.ppif' docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

The AXI manager capacity/status subset is ready for a first in-process IAL2
implementation without new IAL1 or IAL0/SystemVerilog prerequisites.

The first behavior-bearing slice should be an in-process generator, not public
`.ppif` syntax. It should emit reviewable generated `.isf`, lower through the
existing scheduler to reviewable `.fsm`, and then use the existing
SystemVerilog path.

The implementation boundary is a capacity/status shell over abstract read/write
submit and completion events, explicit pending depths, namespaced status
outputs, generated pending counters, and report-only capacity blocked reasons.
Public `.ppif` syntax, profile aliases, IDs, ordering, response matching,
bursts, queued/blocking policy, and VHDL remain future exact-owner work.

Focused coverage should land in a new generator test such as
`t/1437-axi-ial2-manager-capacity-status-generator.t`, proving generated IAL1
and IAL0 review artifacts, namespaced status outputs, counter/status behavior,
same-cycle submit+complete handling, fail-closed unsupported policies, and
SystemVerilog reachability.
