---
id: ial2-axi-manager-post-multiple-mixed-depth3-last-beat-read-data-next-slice
title: Multiple/mixed depth-3 last-beat read-data selects burst-length readiness next
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.181 select?"
  - "what is the next IAL2 frontier after multiple/mixed depth-3 burst-last read-data?"
  - "what follows generated multiple/mixed depth-3 queue-head last-beat read-data?"
  - "should multiple/mixed depth-3 scalar last-beat read-data add raw ARLEN before runtime validation?"
date: 2026-06-18
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3, burst-length, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.181|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.182|POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION|report-only raw|multiple/mixed depth-3 queue-head scalar last-beat read-data' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.181` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.182`, readiness audit for generated
report-only raw-`ARLEN` burst-length capture over multiple/mixed depth-3
queue-head scalar last-beat read-data.

The selector is documentation-only. It changes no parser, generator, PPIF
sample, support-accounting, test, generated artifact, validation, or HDL
behavior.

The selected `.182` boundary follows the established sequence used by
one-group depth-3 and multi-group depth-2 queue-head scalar last-beat
read-data: first generate no-`burst_length` scalar last-beat read-data, then
audit report-only raw-`ARLEN`, then leave runtime validation and multi-beat
payload behavior to later exact owners.

The `.182` audit must stay bounded to read family, `response-scope
burst-last`, generated read burst-last queue-head response-demux,
`capture-scope last-beat`, scalar `RDATA`/`RRESP`, `burst-length` source
`arlen`, width `8`, `encoding axlen-plus-one`, `capture request`, and
`validation report-only` over two-depth-3 and mixed depth-3/depth-2 concrete
`RID` queue-head groups.
