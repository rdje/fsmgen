---
id: ial2-axi-manager-post-queue-head-last-beat-read-data-next-slice-selection
title: Post queue-head last-beat read-data selector chooses queue-head burst-length capture
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.116 select?"
  - "what comes after generated last-beat queue-head read-data?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.117?"
  - "why is queue-head burst-length capture next?"
  - "is multi-beat queue-head read-data next after last-beat queue-head read-data?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, read-data, same-id, queue-head, selector, burst-length, arlen]
evidence: docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.116|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.117|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.118|POST_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION|queue-head burst-length|raw-ARLEN|axi0_arlen|generated_burst_length_capture|generated_queue_head_response_demux_last_beat_completion_pulse' docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.116` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.117`: generated raw-`ARLEN`
burst-length capture for the bounded read burst-last concrete same-ID
queue-head last-beat read-data shape.

The selection is narrow because generated queue-head last-beat read-data now
proves the queue-head completion source and scalar last-beat capture, and the
existing auto-ID burst-length path already proves request-bound raw-`ARLEN`
capture, generated input/storage/rule naming, and report fields.

`.117` should keep the queue-head last-beat completion validity
`generated_queue_head_response_demux_last_beat_completion_pulse` and add
report-only `burst-length` metadata plus generated raw-`ARLEN` capture for
the bounded one duplicate concrete read-ID group, two-transaction, depth-2
shape.

That selected behavior shipped in `.117` for
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif`.
The active frontier is now `.118`, the next queue-head/read-data selector.

Multi-beat queue-head read-data is not the next selected slice because it
also requires queue-head beat-count/RLAST validation, beat-index state,
per-beat output-bank writes, valid-mask/length outputs, and scalar `RRESP`
aggregation. Queue-head runtime validation, deeper or multiple queue groups,
mixed same-family auto-ID plus concrete queue-head demux, direct backend
lowering, and VHDL remain deferred.
