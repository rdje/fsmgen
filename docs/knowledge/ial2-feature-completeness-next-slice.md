---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is per-ID read-data interleaving readiness
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.80?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.81?"
  - "what is the next AXI manager behavior slice?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, feature-completeness, task-tree, selector]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_POST_RRESP_AGGREGATION_NEXT_SLICE_SELECTION.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.80|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.81|POST_RRESP_AGGREGATION_NEXT_SLICE_SELECTION|per-ID read-data interleaving and queue readiness|verification-code generation' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_POST_RRESP_AGGREGATION_NEXT_SLICE_SELECTION.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.80` selected the next owner after
generated scalar AXI multi-beat `RRESP` aggregation behavior.

The next active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.81`. It audits
AXI per-ID read-data interleaving and queue readiness before parser,
generator, HDL, sample, support-accounting, check JSON, semantic JSON, or
validation behavior changes.

The audit must decide whether the next exact owner should be public per-ID
queue/interleaving contract selection, authored concrete-ID same-ID ordering,
generated per-ID issue/response queue substrate, burst payload assembly,
report/static alignment, an IAL1/IAL0/SystemVerilog prerequisite, or a smaller
docs/support-accounting slice. Verification-code generation is tracked as a
separate future roadmap lane from the current synthesizable RTL/HDL path.
