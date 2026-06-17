---
id: ial2-axi-manager-read-single-beat-depth3-queue-head-response-demux-behavior
title: AXI manager supports one generated read single-beat depth-3 queue-head response-demux shape
answers:
  - "does AXI manager queue-head response demux support depth 3?"
  - "which PPIF sample covers read single-beat depth-3 queue-head response-demux?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.149 ship?"
  - "what is deferred after read single-beat depth-3 queue-head response-demux?"
date: 2026-06-16
status: current
tags: [ial2, axi, manager, same-id, queue-head, response-demux, depth-3]
evidence: docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_response_demux.ppif; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_response_demux.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.149|read single-beat depth-3|slot2|depth-3 queue-head response-demux' docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.149` shipped one generated read
single-beat depth-3 concrete same-ID queue-head response-demux shape.

The support-accounted sample is
`ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_response_demux.ppif`.
It has one read group where `r0`, `r1`, and `r2` share concrete `RID` `3` and
the computed queue depth is `3`.

FSMGen generates compact one-hot queue slots `slot0` through `slot2`, shared
enumerated queue transitions, generalized queue assertions, and generated
completion pulse outputs for `r0`, `r1`, and `r2`. Response-demux rules match
the raw `RID` and the active queue head; no `RLAST` or `read_data` behavior is
introduced by this sample.

Read-data over depth-3 queues, read burst-last depth-3 response-demux, write
depth-3 response-demux, multiple or mixed depth-3 groups, same-family mixed
auto-ID, group-local enqueue widening, packed outputs, direct backend, and
VHDL remain deferred behind future task-tree leaves.
