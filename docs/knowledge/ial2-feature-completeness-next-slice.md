---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is post queue-head last-beat read-data selection
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.107?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.108?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.109?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.110?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.111?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.112?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.113?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.114?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.115?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.116?"
  - "what is the next AXI manager slice?"
  - "what is the next AXI manager task after same-ID queue behavior implementation?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, same-id, concrete-id, ordering, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; docs/knowledge/ial2-common-vs-profile-factoring.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.115|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.116|generated_queue_head_response_demux_last_beat_completion_pulse|axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data|generated_queue_head_response_demux_completion_pulse|generated_read_burst_last_queue_head_demux|common semantic core' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md docs/knowledge/ial2-common-vs-profile-factoring.md
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

`IAL2-FEATURE-COMPLETENESS-FRONTIER.111` selected queue-head read-data
readiness as `.112`. `IAL2-FEATURE-COMPLETENESS-FRONTIER.112` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.113`, generated single-beat read-data
capture for bounded read single-beat concrete same-ID queue-head demux.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.113` shipped that behavior for
`ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif`
and advanced the frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.114`.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.114` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.115`, generated last-beat read-data
capture for the bounded read burst-last concrete same-ID queue-head demux
shape. `IAL2-FEATURE-COMPLETENESS-FRONTIER.115` shipped that behavior for
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif`
and advanced the frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.116`, the
selector for the next queue-head/read-data expansion.

The already-covered public samples now report generated response demux,
generated same-ID ordering, `accepted_same_id_reuse: true`, and
`generated_queue_behavior: true` only for the bounded read burst-last, write,
and read single-beat depth-2 two-transaction shapes. Generated queue-head
read-data capture is now supported for the bounded read single-beat queue-head
shape and the bounded read burst-last queue-head last-beat shape. The
single-beat path reports `generated_queue_head_response_demux_completion_pulse`;
the last-beat path reports
`generated_queue_head_response_demux_last_beat_completion_pulse`. Existing
auto-ID read-data capture keeps its auto-ID completion-validity values.
Multi-beat queue-head read-data, queue-head `burst-length` metadata, deeper
or multiple groups, same-family mixed auto-ID, direct backend, and VHDL remain
deferred.

The IAL2 factoring stance remains that common constructs should be promoted
only after compatible reuse is proven across multiple profiles.
