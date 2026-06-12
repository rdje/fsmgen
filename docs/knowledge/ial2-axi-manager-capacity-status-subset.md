---
id: ial2-axi-manager-capacity-status-subset
title: First post-Valid-Ready AXI manager subset is capacity/status
answers:
  - "what is the first AXI manager subset after Valid-Ready?"
  - "what AXI manager rule subset was selected first?"
  - "does the first AXI manager slice include IDs and response matching?"
  - "what is the next IAL2 AXI manager readiness audit about?"
  - "what source anchors define the AXI manager capacity/status subset?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, capacity, status, task-tree]
evidence: docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'capacity/status|outstanding-capacity|acceptance/status|A1\\.1|A1\\.2|A5\\.1|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.3' docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

The first post-Valid-Ready AXI manager subset is outstanding transaction
capacity plus acceptance/status feedback, anchored to `A1.1`, `A1.2`, and
`A5.1`.

The selected subset owns explicit read/write pending depths, `try`-style
acceptance feedback, full/pending/available-slot status, and a capacity-only
blocked-reason vocabulary. It must preserve generated IAL1 `.isf` and IAL0
`.fsm` review artifacts before SystemVerilog HDL.

It does not include ID allocation, user ID validation, same-ID ordering,
different-ID interleaving, response matching, burst/last-beat tracking,
channel expansion, `blocking`/`queued` policy behavior, profile aliases, or
VHDL backend work. The active next leaf is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.3`, a readiness audit that must map code,
test, report, and documentation owners before behavior changes.
