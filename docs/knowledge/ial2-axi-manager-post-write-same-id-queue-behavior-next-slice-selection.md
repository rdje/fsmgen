---
id: ial2-axi-manager-post-write-same-id-queue-behavior-next-slice-selection
title: Post-write same-ID queue behavior selection chooses read single-beat
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.109 select?"
  - "what comes after write same-ID queue-head behavior?"
  - "why is read single-beat same-ID queue behavior next?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.110?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, same-id, read, single-beat, response-demux, queue-head, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_WRITE_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.109|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.110|read `single-beat`|read single-beat|generated_write_bid_queue_head_demux|generated_read_burst_last_queue_head_demux' docs/AXI_IAL2_MANAGER_POST_WRITE_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.109` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.110` as the next AXI same-ID queue
behavior slice.

`.110` owns generated read `single-beat` concrete same-ID queue-head response
demux for exactly one duplicate concrete read-ID group of two transactions at
computed depth 2. The selected head match is raw read response event plus
concrete `RID` plus compact slot-0 transaction bit, without `RLAST`.

This is the smallest remaining expansion because `.108` already proved the
no-`last_signal` queue-head path for writes, while the public read
response-demux contract already accepts `response-scope single-beat`.

Read-data consumption of concrete queue-head demux, deeper or multiple
duplicate-ID groups, same-family mixed auto-ID plus concrete queue-head demux,
generalized per-ID queues, direct backend lowering, and VHDL remain deferred.
