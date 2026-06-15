---
id: ial2-axi-manager-post-queue-head-read-data-next-slice-selection
title: Post queue-head read-data selector chooses last-beat queue-head capture
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.114 select?"
  - "what comes after generated single-beat queue-head read-data?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.115?"
  - "why is last-beat queue-head read-data next?"
  - "is multi-beat queue-head read-data next?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, read-data, same-id, queue-head, selector, last-beat]
evidence: docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.114|IAL2-FEATURE-COMPLETENESS-FRONTIER\.115|IAL2-FEATURE-COMPLETENESS-FRONTIER\.116|IAL2-FEATURE-COMPLETENESS-FRONTIER\.117|IAL2-FEATURE-COMPLETENESS-FRONTIER\.120|IAL2-FEATURE-COMPLETENESS-FRONTIER\.121|generated_queue_head_response_demux_last_beat_completion_pulse|generated_read_burst_last_queue_head_demux|queue-head burst-length|queue-head multi-beat' docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.114` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.115`: generated last-beat `RDATA`/`RRESP`
capture for the bounded read burst-last concrete same-ID queue-head demux
shape.

The selection is narrow because generated read burst-last queue-head demux
already owns `RLAST`-qualified completion pulses, generated auto-ID last-beat
read-data already proves scalar last-beat capture, and `.113` made read-data
coverage source-aware for generated queue-head transactions and completion
signals.

`.115` should preserve existing auto-ID last-beat completion validity
(`generated_read_response_demux_last_beat_completion_pulse`) and existing
queue-head single-beat completion validity
(`generated_queue_head_response_demux_completion_pulse`) while introducing a
queue-head last-beat validity report:
`generated_queue_head_response_demux_last_beat_completion_pulse`.

That selected `.115` implementation has now shipped in
`docs/AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md` and
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif`.

`.120` later selected `.121`, generated multi-beat read-data output-bank
behavior for the bounded read burst-last concrete same-ID queue-head demux
shape. Deeper or multiple queue groups, mixed same-family auto-ID plus
concrete queue-head demux, generalized per-ID queues, direct backend
lowering, and VHDL remain deferred.

After `.115` shipped, `.116` selected `.117`, generated raw-`ARLEN`
burst-length capture for the bounded queue-head last-beat read-data shape.
`.120` later selected the bounded queue-head multi-beat read-data output-bank
implementation owner as `.121`.
