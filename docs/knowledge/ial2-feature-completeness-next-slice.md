---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is the next AXI manager residue-owner selector
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.83?"
  - "what is the next AXI manager slice?"
  - "what is the next AXI manager residue-owner selector?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, feature-completeness, task-tree, selector]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_RESIDUE_ALIGNMENT_FIRST_SLICE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.82|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.83|READ_DATA_INTERLEAVING_RESIDUE_ALIGNMENT_FIRST_SLICE|response_demux\\.residue: \\[bursts\\]|same_id_ordering\\.residue|next AXI manager residue-owner selector' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_RESIDUE_ALIGNMENT_FIRST_SLICE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.82` selected the next owner after
aligning read-data interleaving residue for the covered generated auto-ID
multi-beat-by-RID subset.

The next active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.83`. It selects
the next AXI manager residue owner after the public multi-beat sample now
reports `response_demux.residue: [bursts]` and
`same_id_ordering.residue: [concrete_id_same_id_ordering,
per_id_issue_order_queues, bursts]`.

`.83` must choose among remaining bursts, concrete-ID same-ID ordering, per-ID
queues, policy/profile/full-manager lanes, verification-code generation,
direct backend lowering, and VHDL deferrals before any behavior changes.
