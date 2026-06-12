---
id: ial2-axi-manager-transaction-envelope-readiness
title: AXI manager transaction-envelope readiness selects additive metadata
answers:
  - "is the codebase ready for AXI transaction-envelope metadata?"
  - "should AXI transaction envelopes extend manager-capacity-status?"
  - "does the first transaction-envelope slice need IAL1 or IAL0 prerequisites?"
  - "does transaction-envelope metadata change generated ISF FSM or HDL?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, transaction-envelope, readiness, task-tree]
evidence: docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'Readiness Conclusion|Selected Implementation Boundary|transactions|manager-capacity-status|generated `.isf`|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.12' docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.11` selects the first AXI transaction
envelope implementation boundary.

The first slice should extend the existing public `manager-capacity-status`
object with optional static/report `(transactions ...)` metadata. It should
not introduce a broader `(axi-manager ...)` object yet.

No IAL1, IAL0, or SystemVerilog prerequisite is required for the first slice
because transaction request/completion bindings are constrained to the
existing direction-level abstract events and generated `.isf`, generated
`.fsm`, and HDL behavior remain unchanged.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.12` implemented this boundary as the
first shipped transaction-envelope metadata slice.
