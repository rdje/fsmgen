---
id: ial2-axi-manager-read-burst-last-depth3-queue-head-read-data-readiness
title: Read burst-last depth-3 queue-head scalar read-data is ready for direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.158 select?"
  - "can read-data over read burst-last depth-3 queue-head demux be implemented directly?"
  - "what is the next IAL2 frontier after read burst-last depth-3 read-data readiness?"
date: 2026-06-17
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3]
evidence: docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.158|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.159|READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT|generated_queue_head_response_demux_last_beat_completion_pulse|read burst-last depth-3 queue-head scalar read-data' docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.158` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.159`, direct bounded implementation of
generated scalar last-beat read-data over the generated read burst-last
depth-3 queue-head response-demux.

The audit found no lower-layer prerequisite. The shipped `.156` response-demux
already generates the one depth-3 read burst-last queue-head group and three
completion pulses, while scalar read-data generation already iterates covered
transactions once the local read-data coverage gate admits a shape.

`.159` must stay narrow: one concrete `RID` group with `r0`/`r1`/`r2`, queue
depth `3`, scalar last-beat `RDATA`/`RRESP` capture, no burst-length,
runtime-validation, multi-beat output bank, write depth-3, broader groups,
direct backend, or VHDL widening.
