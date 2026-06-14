---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is read-data interleaving residue alignment
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.82?"
  - "what is the next AXI manager slice?"
  - "what is the next AXI manager report/static slice?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, feature-completeness, task-tree, selector]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_QUEUE_READINESS_AUDIT.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.81|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.82|READ_DATA_INTERLEAVING_QUEUE_READINESS_AUDIT|multi_beat_by_rid|report/static residue alignment|read_data_interleaving' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_QUEUE_READINESS_AUDIT.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.81` selected the next owner after
auditing AXI per-ID read-data interleaving and queue readiness.

The next active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.82`. It aligns
report/static `read_data_interleaving` residue for the covered generated
auto-ID multi-beat-by-RID output-bank subset.

Generated `.isf`, `.fsm`, and SystemVerilog behavior should remain unchanged
in `.82`; concrete-ID same-ID ordering, per-ID issue-order queues, broader
bursts, queued/blocking policy, profile aliases, full-manager behavior,
verification-code generation, direct backend lowering, and VHDL remain
deferred.
