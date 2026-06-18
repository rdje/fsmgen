---
id: ial2-axi-manager-multiple-mixed-depth3-last-beat-read-data-readiness
title: Multiple/mixed depth-3 burst-last read-data can be implemented directly
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.179 select?"
  - "can burst-last read-data over multiple or mixed depth-3 queue-head groups be implemented directly?"
  - "what is the next IAL2 frontier after burst-last read-data readiness?"
date: 2026-06-18
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3, readiness]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.179|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.180|MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT|read burst-last scalar last-beat' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.179` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.180`, direct bounded implementation of
generated read burst-last scalar last-beat `RDATA`/`RRESP` over multiple or
mixed depth-3 concrete same-ID queue-head groups.

The audit found no lower-layer prerequisite. The matching response-demux-only
samples already generate over depth `3,3` and `3,2` queue sets, the one-group
depth-3 burst-last scalar read-data sibling already generates, and downstream
scalar read-data artifacts are transaction-list driven once the local coverage
gate admits a shape.

`.180` must stay narrow: no `burst_length` metadata, read family only,
`response_scope burst_last`, `capture_scope last-beat`, scalar last-beat
outputs for every covered transaction, and no burst-length, runtime
validation, multi-beat payload, write-family read-data, mixed auto-ID,
direct backend, VHDL, or backend-language widening.
