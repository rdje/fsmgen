---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is scalar RRESP aggregation contract selection
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.73?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.74?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.74?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.75?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.75?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.76?"
  - "what must happen before the next AXI manager behavior?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, multi-beat, output-bank, rresp, selector, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_POST_MULTI_BEAT_OUTPUT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md; ppif/axi_manager_capacity_status_read_data_multi_beat.ppif; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.75|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.76|scalar RRESP aggregation|rresp_aggregation|AXI_IAL2_MANAGER_POST_MULTI_BEAT_OUTPUT_NEXT_SLICE_SELECTION' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_POST_MULTI_BEAT_OUTPUT_NEXT_SLICE_SELECTION.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.75` selected public AXI multi-beat
scalar `RRESP` aggregation contract selection as the next exact owner after
generated multi-beat read-data output-bank behavior.

The next active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.76`. It is a
selector. It must choose the public source/report contract for scalar
`RRESP` aggregation or record a smaller prerequisite before parser/report
metadata, generated behavior, HDL, sample, support-accounting, check JSON,
semantic JSON, or validation behavior changes.

The selection follows the live multi-beat sample report:
`multi_beat_reassembly_generated_behavior: true`,
`status_policy: per_beat`, `status_aggregation: none`, and
`read_data.residue: [rresp_aggregation]`. Per-ID queues, authored concrete-ID
same-ID ordering, queued/blocking policy, profile aliases, full-manager
behavior, direct backend, and VHDL remain deferred.
