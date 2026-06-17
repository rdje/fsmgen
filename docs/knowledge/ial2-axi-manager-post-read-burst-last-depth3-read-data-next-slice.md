---
id: ial2-axi-manager-post-read-burst-last-depth3-read-data-next-slice
title: Read burst-last depth-3 queue-head read-data selects burst-length readiness next
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.160 select?"
  - "what is the next IAL2 frontier after read burst-last depth-3 queue-head read-data?"
  - "what follows generated read burst-last depth-3 queue-head read-data?"
date: 2026-06-17
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3, burst-length]
evidence: docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.160|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.161|POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION|report-only raw' docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.160` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.161`, readiness audit for generated
report-only raw-`ARLEN` burst-length capture over the generated read
burst-last depth-3 queue-head read-data shape.

The selector is documentation-only. It follows `.159`, which shipped scalar
last-beat read-data over one read burst-last depth-3 queue-head group. Live
probes showed that `.159` still reports
`arlen_or_beat_count_validation` residue while the existing depth-2
queue-head sibling already generates request-bound raw-`ARLEN` capture with
`validation report_only`.

`.161` must audit only the report-only raw-`ARLEN` burst-length boundary
before any behavior change. Runtime validation, multi-beat output banks, write
depth-3, broader depth-3 groups, mixed auto-ID, direct backend, and VHDL remain
deferred.
