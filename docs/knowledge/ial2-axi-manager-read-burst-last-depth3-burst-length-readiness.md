---
id: ial2-axi-manager-read-burst-last-depth3-burst-length-readiness
title: Read burst-last depth-3 queue-head burst-length readiness selects direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.161 select?"
  - "what is the next IAL2 frontier after read burst-last depth-3 burst-length readiness?"
  - "can depth-3 read burst-last report-only raw ARLEN ship directly?"
date: 2026-06-17
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3, burst-length]
evidence: docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.161|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.162|READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT|report-only raw' docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.161` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.162`, direct bounded implementation of
generated report-only raw-`ARLEN` burst-length capture over the generated read
burst-last depth-3 queue-head read-data shape.

The audit found that a temporary depth-3 report-only raw-`ARLEN` candidate
fails only at the local queue-head read-data coverage predicate. Burst-length
normalization, raw-`ARLEN` storage, request-bound capture rules, generated
input/report artifacts, and focused report helpers already iterate the covered
transaction list once the shape is admitted.

`.162` must keep runtime-validation, multi-beat output banks, write depth-3,
broader depth-3 groups, mixed auto-ID, direct backend, and VHDL deferred.
