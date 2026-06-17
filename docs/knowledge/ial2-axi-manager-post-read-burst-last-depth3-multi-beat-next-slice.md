---
id: ial2-axi-manager-post-read-burst-last-depth3-multi-beat-next-slice
title: After depth-3 multi-beat read-data, write depth-3 queue-head readiness is next
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.169 select?"
  - "what is the next IAL2 frontier after depth-3 multi-beat read-data?"
  - "why is write depth-3 queue-head readiness next?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.170?"
  - "what follows IAL2-FEATURE-COMPLETENESS-FRONTIER.170?"
date: 2026-06-17
status: current
tags: [ial2, axi, manager, write, response-demux, queue-head, depth-3, readiness]
evidence: docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.169|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.170|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.171|POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION|WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT|write depth-3|generated_write_bid_queue_head_demux|generated_same_id_queue_head_demux' docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md docs/AXI_IAL2_MANAGER_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.169` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.170`, readiness audit for generated
write-family depth-3 concrete same-ID queue-head response-demux behavior.

The selector chose write depth-3 because the existing write depth-2 one-group
and write depth-2 multi-group queue-head response-demux samples are already
generated through `generated_write_bid_queue_head_demux`, while read depth-3
queue-state behavior has shipped for both single-beat and burst-last paths.
A temporary write depth-3 candidate with `w0`/`w1`/`w2` sharing concrete
`BID` `3` passes strict check with no diagnostics, reports one depth-3 write
queue group, and remains selected-not-generated only with
`generated_same_id_queue_head_demux` residue.

`.170` has since completed and selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.171`,
direct bounded implementation of that generated write depth-3 queue-head
response-demux behavior. Multiple or mixed depth-3 groups, mixed auto-ID,
group-local enqueue widening, read-data, burst-length, runtime-validation,
multi-beat payload, direct backend, verification-output generation, VHDL, and
backend-language variants remain deferred behind future owned leaves.
