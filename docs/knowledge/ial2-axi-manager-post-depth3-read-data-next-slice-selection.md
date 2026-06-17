---
id: ial2-axi-manager-post-depth3-read-data-next-slice-selection
title: IAL2 post depth-3 read-data selector chose read burst-last depth-3 readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.154 select?"
  - "why is read burst-last depth-3 readiness next after depth-3 read-data?"
  - "what is the selected boundary for the post depth-3 read-data selector?"
date: 2026-06-17
status: current
tags: [ial2, axi, manager, same-id, queue-head, depth-3, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DEEPER_QUEUE_HEAD_GROUPS_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.154|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.155|read burst-last depth-3 queue-head response-demux readiness|AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION' docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.154` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.155`, readiness audit for generated read
burst-last depth-3 concrete same-ID queue-head response-demux.

The selected audit is read-family only, `response-demux.read.response_scope
burst-last`, one-bit `last-signal`/`RLAST`, generated queue-head
response-demux boundary `generated_read_burst_last_queue_head_demux`, exactly
one duplicate concrete `RID` group of three read transactions at computed
depth `3`, and selected concrete-ID issue-order queue policy.

The selector chose audit before implementation because the generalized
depth-3 queue-state core is proven by read single-beat response-demux and
scalar read-data, but the `RLAST`-qualified read burst-last path still needs a
focused review of last-signal matching, queue-head completion semantics,
assertions, reports, residue, and preservation probes before generation is
widened.

Write depth-3 response-demux, read-data over read burst-last depth-3,
burst-length/runtime-validation/multi-beat over read burst-last depth-3,
multiple or mixed depth-3 groups, mixed auto-ID, group-local enqueue widening,
direct backend, and VHDL remain deferred.
