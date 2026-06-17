---
id: ial2-axi-manager-read-burst-last-depth3-multi-beat-readiness-audit
title: Depth-3 multi-beat queue-head read-data is ready for bounded implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.167 select?"
  - "is read burst-last depth-3 multi-beat queue-head read-data ready?"
  - "what is the next IAL2 frontier after depth-3 multi-beat readiness?"
  - "does depth-3 multi-beat read-data need a lowerer prerequisite?"
date: 2026-06-17
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3, multi-beat, readiness]
evidence: docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.167|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.168|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.169|READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT|READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR|per_beat_output_bank|multi-beat depth-3 admission gate|response_demux_matched_read_beat' docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.167` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.168`, direct bounded implementation of
generated multi-beat output-bank behavior over exactly one read burst-last
depth-3 queue-head runtime-validation group.

`.168` has since shipped that behavior and advanced the frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.169`, the next feature-completeness
selector/audit.

The audit found no parser, IAL1, IAL0, SystemVerilog lowerer,
support-accounting framework, or mdBook prerequisite beyond the local
multi-beat depth-3 admission gate. Live reports showed `.165` is generated at
depth `3` with only multi-beat/read-output/RRESP aggregation residue, while
the one-group and multi-group depth-2 multi-beat siblings already generate
`per_beat_output_bank` behavior with empty read-data residue.

`.168` must stay bounded to `r0`/`r1`/`r2`, one concrete `RID` group at depth
`3`, runtime `ARLEN` validation, per-beat output banks, valid masks, length
outputs, and scalar `RRESP` aggregation. Write depth-3, multiple or mixed
depth-3 groups, mixed auto-ID, group-local enqueue widening, packed outputs,
alternate burst assembly, direct backend, verification-output generation,
VHDL, and other backend-language variant work remain deferred.
