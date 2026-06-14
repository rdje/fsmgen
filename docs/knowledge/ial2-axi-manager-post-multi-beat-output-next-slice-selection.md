---
id: ial2-axi-manager-post-multi-beat-output-next-slice-selection
title: AXI post multi-beat output-bank selector chooses scalar RRESP aggregation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.75 select?"
  - "what comes after AXI multi-beat read-data output-bank behavior?"
  - "what is the next AXI manager slice after rresp_aggregation residue?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.76?"
  - "should RRESP aggregation be selected before behavior?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, multi-beat, rresp, aggregation, selector, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTI_BEAT_OUTPUT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; ppif/axi_manager_capacity_status_read_data_multi_beat.ppif; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.75|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.76|status_aggregation: none|rresp_aggregation|scalar RRESP aggregation' docs/AXI_IAL2_MANAGER_POST_MULTI_BEAT_OUTPUT_NEXT_SLICE_SELECTION.md docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.75` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.76`, public AXI multi-beat scalar
`RRESP` aggregation contract selection, as the next exact owner after
generated multi-beat read-data output-bank behavior.

The selection is grounded in the live public multi-beat sample report:
`read_data.read.status_policy: per_beat`,
`read_data.read.status_aggregation: none`,
`read_data.read.multi_beat_reassembly_generated_behavior: true`, and
`read_data.residue: [rresp_aggregation]`.

`.76` is a selector. It must choose the public source/report contract for
scalar `RRESP` aggregation, including policy semantics, scalar output
binding, diagnostics, generated artifact boundaries, residue movement, docs,
Knowledge Map updates, and VHDL deferral before parser/report metadata or
generated behavior changes. Per-ID queues, authored concrete-ID same-ID
ordering, queued/blocking policy, profile aliases, full-manager behavior,
direct backend, and VHDL remain deferred.
