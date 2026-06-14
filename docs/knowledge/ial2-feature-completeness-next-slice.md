---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is scalar RRESP aggregation behavior
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.78?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.79?"
  - "what is the next AXI manager behavior slice?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, multi-beat, rresp, aggregation, behavior, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_CONTRACT_SELECTION.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.78|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.79|RRESP_AGGREGATION_BEHAVIOR_READINESS|generated scalar RRESP aggregation behavior|status_aggregation_generated_behavior|generated_rresp_aggregation' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_READINESS_AUDIT.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.78` audited generated scalar AXI
multi-beat `RRESP` aggregation readiness and found no new IAL1, IAL0, or
SystemVerilog prerequisite for first width-2 `worst_observed` behavior.

The next active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.79`. It should
emit one width-2 scalar aggregate output per transaction, initialize it to
`OKAY` on the request event, update it on accepted matched read-data beats
when the current aggregate is less than the current `RRESP` signal under the
existing `!request_event` boundary, report generated artifact lists, and
remove `generated_rresp_aggregation` from `read_data.residue`.

Width-3 responses, alternate policies, aggregate-only output shapes, packed
outputs, per-ID queues, direct backend lowering, and VHDL remain deferred.
