---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is the post-RRESP aggregation selector
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.79?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.80?"
  - "what is the next AXI manager behavior slice?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, feature-completeness, task-tree, selector]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_FIRST_SLICE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.79|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.80|RRESP_AGGREGATION_BEHAVIOR_FIRST_SLICE|generated_status_aggregate|verification-code output roadmap lane|next AXI manager feature-completeness selector' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_FIRST_SLICE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.79` shipped generated scalar AXI
multi-beat `RRESP` aggregation behavior for the selected width-2
`worst_observed` contract.

The next active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.80`. It is a
selector after scalar `RRESP` aggregation behavior. It must choose the next
exact owner from remaining AXI manager residue, including per-ID read-data
queues, authored concrete-ID same-ID ordering, queued/blocking policy,
profile aliases, full-manager behavior, direct backend lowering, report/static
alignment, an IAL1/IAL0/SystemVerilog prerequisite, or whether verification
code generation should become a separate roadmap lane. No parser, generator,
HDL, sample, support-accounting, check JSON, semantic JSON, or validation
behavior changes belong to `.80` until the next owner is selected.
