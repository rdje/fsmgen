---
id: ial2-axi-manager-read-response-demux-selection
title: AXI read response demux readiness follows same-ID avoidance
answers:
  - "what comes after AXI same-ID avoidance?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.36 select?"
  - "is read RID response demux next?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.37?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, read-response, response-demux, rid, feature-completeness, task-tree]
evidence: docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.36|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.37|read response-demux|read RID|AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION' docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.36` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.37`, a readiness audit for bounded AXI
read `RID` response demux after generated auto-ID same-ID avoidance.

This is not an implementation slice. The audit must decide whether the first
read response-demux step can safely be an explicit read-only opt-in contract,
a bounded single-beat/non-burst `RID` match that generates transaction
completion pulses, a metadata/static-validation slice before behavior, an
IAL1/IAL0/SystemVerilog prerequisite, or a deferral behind read-data
interleaving/reassembly or burst/last-beat ownership.

The candidate public shape to audit is additive under the existing
`response-demux` clause:

```text
(response-demux
  (read
    (response-event axi0_read_complete)
    (transaction-completion generated)))
```

Read-data interleaving/reassembly, burst or last-beat tracking, per-ID
same-ID response queues or scoreboards, authored concrete-ID same-ID ordering,
queued/blocking policy, profile aliases, full AXI manager syntax, and VHDL
remain future exact-owner residue.
