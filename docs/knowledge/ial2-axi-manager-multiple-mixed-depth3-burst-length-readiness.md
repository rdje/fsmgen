---
id: ial2-axi-manager-multiple-mixed-depth3-burst-length-readiness
title: Multiple/mixed depth-3 burst-length readiness selects direct report-only ARLEN implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.182 select?"
  - "what is the next IAL2 frontier after multiple/mixed depth-3 burst-length readiness?"
  - "can multiple/mixed depth-3 queue-head scalar last-beat read-data add report-only ARLEN next?"
  - "what public samples should implement multiple/mixed depth-3 queue-head burst-length?"
date: 2026-06-18
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3, burst-length, readiness]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.182|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.183|MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT|read_burst_last_multi_depth3_same_id_queue_head_burst_length|read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length|report-only raw' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.182` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.183`, direct bounded implementation of
generated report-only raw-`ARLEN` burst-length capture over multiple/mixed
depth-3 queue-head scalar last-beat read-data.

The audit is documentation-only. It changes no parser, generator, PPIF sample,
support-accounting, test, generated artifact, validation, or HDL behavior.

Temporary in-memory candidates that add report-only `burst-length` metadata to
the `.180` two-depth-3 and mixed depth-3/depth-2 samples fail closed only at
the local last-beat coverage gate. Downstream burst-length storage, capture
rules, generated artifacts, and report helpers are transaction-list driven
once the shape is admitted.

The selected `.183` public samples are:

- `ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length.ppif`
- `ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length.ppif`

Runtime beat-count/`RLAST` validation, multi-beat payload behavior,
write-family read-data, same-family mixed auto-ID plus concrete queue-head
demux, group-local enqueue widening, packed outputs, alternate burst
assembly, direct backend, verification-output generation, VHDL, and
backend-language variants remain deferred behind separate owned leaves.
