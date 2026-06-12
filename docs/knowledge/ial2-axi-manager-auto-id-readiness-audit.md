---
id: ial2-axi-manager-auto-id-readiness-audit
title: AXI manager auto-ID lifecycle needs a bounded contract first
answers:
  - "what did the AXI auto-ID lifecycle readiness audit conclude?"
  - "can AXI auto-ID allocation be implemented directly?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.20?"
  - "what must be selected before AXI auto-ID request-ID drive?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.21?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, id, auto-id, task-tree]
evidence: docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.21|bounded auto-ID pool|request-ID drive contract|auto_id_lifecycle|existing \\(id auto\\) transactions remain structural/report-only' docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.20` concluded that AXI auto-ID lifecycle is
the right next feature area, but a full allocator should not be implemented
directly from the existing `id auto` syntax.

The current IAL1/IAL0/SystemVerilog substrate can carry scalar request-ID
outputs, scalar storage, rules, and assertions once the contract is bounded.
The missing contract is the allocation boundary: AXI ID widths may be as large
as 32 bits, and width alone is not a reviewable implicit allocation pool.

Until the bounded contract is selected, existing `(id auto)` transactions
remain structural/report-only metadata.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.21` owns the next step: select the bounded
AXI auto-ID pool and request-ID drive contract before any auto-ID allocation,
request-ID output, ID release, response demux, ordering, or VHDL behavior
changes.
