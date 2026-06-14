---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is post-write same-ID queue behavior selection
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.107?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.108?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.109?"
  - "what is the next AXI manager slice?"
  - "what is the next AXI manager task after same-ID queue behavior implementation?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, same-id, concrete-id, ordering, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_POST_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE_SELECTION.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; docs/knowledge/ial2-common-vs-profile-factoring.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.108|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.109|generated_write_bid_queue_head_demux|write depth-2|post-write same-ID queue behavior|common semantic core' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md docs/knowledge/ial2-common-vs-profile-factoring.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.106` shipped the first generated
same-ID queue behavior boundary for the public read burst-last depth-2 sample.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.108` shipped generated AXI same-ID write
queue-head behavior for one duplicate concrete write-ID group of two
transactions at computed depth 2. The generated match is write response event
plus concrete `BID` plus the compact one-hot queue head transaction bit, and
the existing auto-ID write demux path remains separate.

The next active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.109`, an
audit/selector for the next same-ID queue behavior expansion after the shipped
read burst-last and write depth-2 queue-head boundaries.

The already-covered public samples now report generated response demux,
generated same-ID ordering, `accepted_same_id_reuse: true`, and
`generated_queue_behavior: true` only for the bounded read burst-last and
write depth-2 two-transaction shapes. Read `single-beat`, deeper or multiple
groups, same-family mixed auto-ID, read-data consumption, direct backend, and
VHDL remain deferred.

The IAL2 factoring stance remains that common constructs should be promoted
only after compatible reuse is proven across multiple profiles.
