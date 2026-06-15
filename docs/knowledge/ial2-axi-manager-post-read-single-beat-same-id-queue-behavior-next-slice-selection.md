---
id: ial2-axi-manager-post-read-single-beat-same-id-queue-behavior-next-slice-selection
title: Post-read-single-beat same-ID queue selector chooses queue-head read-data readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.111 select?"
  - "what comes after read single-beat same-ID queue-head behavior?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.112?"
  - "why is read-data consumption selected after same-ID queue-head demux?"
  - "can read_data consume concrete same-ID queue-head demux yet?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, same-id, read-data, response-demux, queue-head, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.111|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.112|read_data cannot consume concrete same-ID queue-head|generated_read_single_beat_queue_head_demux|generated_read_burst_last_queue_head_demux|generated_write_bid_queue_head_demux' docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.111` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.112`, a readiness audit for AXI
read-data consumption of generated concrete same-ID queue-head demux.

After `.110`, FSMGen generates the bounded read burst-last, write, and read
single-beat depth-2 concrete same-ID queue-head response-demux shapes. The
existing generated read-data path can capture `RDATA`/`RRESP` from generated
auto-ID read response-demux completion pulses, but current normalization still
rejects `read_data` when `response_demux.read` uses
`generated_queue_head_demux`.

The `.112` audit should decide whether the first safe behavior slice can be
bounded to read single-beat queue-head demux plus single-beat read-data
capture, reusing generated queue-head transaction completion pulses as capture
guards. Burst-last or multi-beat read-data consumption, deeper/multiple queue
groups, mixed auto-ID plus concrete queue-head demux, generalized per-ID
queues, direct backend lowering, and VHDL remain deferred.
