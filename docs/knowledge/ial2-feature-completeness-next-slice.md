---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is queue-head read-data readiness
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.107?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.108?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.109?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.110?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.111?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.112?"
  - "what is the next AXI manager slice?"
  - "what is the next AXI manager task after same-ID queue behavior implementation?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, same-id, concrete-id, ordering, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; docs/knowledge/ial2-common-vs-profile-factoring.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.111|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.112|read_data cannot consume concrete same-ID queue-head|generated_read_single_beat_queue_head_demux|generated_write_bid_queue_head_demux|generated_read_burst_last_queue_head_demux|common semantic core' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md docs/knowledge/ial2-common-vs-profile-factoring.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.106` shipped the first generated
same-ID queue behavior boundary for the public read burst-last depth-2 sample.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.108` shipped generated AXI same-ID write
queue-head behavior for one duplicate concrete write-ID group of two
transactions at computed depth 2. The generated match is write response event
plus concrete `BID` plus the compact one-hot queue head transaction bit, and
the existing auto-ID write demux path remains separate.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.109` selected `.110`, and `.110` has now
shipped generated AXI read `single-beat` same-ID queue-head behavior for one
duplicate concrete read-ID group of two transactions at computed depth 2. The
generated match is raw read response event plus concrete `RID` plus the
compact one-hot queue head transaction bit, without `RLAST`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.111` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.112`. The next active leaf owns AXI
read-data consumption of generated concrete same-ID queue-head demux
readiness before relaxing the current fail-closed `read_data` queue-head
guard.

The already-covered public samples now report generated response demux,
generated same-ID ordering, `accepted_same_id_reuse: true`, and
`generated_queue_behavior: true` only for the bounded read burst-last, write,
and read single-beat depth-2 two-transaction shapes. Existing generated
read-data capture consumes generated auto-ID demux completion pulses, but
read-data consumption of concrete queue-head demux remains unimplemented until
a future behavior leaf selected after `.112`. Deeper or multiple groups,
same-family mixed auto-ID, direct backend, and VHDL remain deferred.

The IAL2 factoring stance remains that common constructs should be promoted
only after compatible reuse is proven across multiple profiles.
