---
id: ial2-axi-manager-post-depth3-burst-length-next-slice-selection
title: Post depth-3 burst-length selector chooses runtime-validation readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.163 select?"
  - "what is the next IAL2 frontier after read burst-last depth-3 burst-length behavior?"
  - "why is runtime-validation readiness next after depth-3 report-only ARLEN?"
date: 2026-06-17
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3, burst-length, runtime-validation]
evidence: docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.163|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.164|POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION|runtime beat-count|runtime-validation readiness' docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.163` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.164`, a readiness audit for generated
runtime beat-count/`RLAST` validation over the shipped read burst-last
depth-3 queue-head read-data plus report-only raw-`ARLEN` burst-length shape.

The selector found that the `.162` sample is support-accounted and generated
with raw-`ARLEN` storage for `r0`, `r1`, and `r2`, but it still reports
`generated_beat_count_validation` residue and emits no expected-beat storage,
beat counters, or runtime assertions.

Existing depth-2 one-group and multi-group runtime-validation samples prove
the beat-count helper path for generated queue-head last-beat read-data. A
temporary depth-3 runtime-validation candidate currently fails closed only at
the local queue-head last-beat coverage diagnostic, which still admits depth-3
for no `burst_length` metadata or report-only metadata but not
`runtime_assertion`.

Runtime-validation readiness is next because multi-beat output-bank behavior
depends on the same matched-read-beat counter substrate, and implementing
either behavior without first auditing the depth-3 admission boundary would
blur the task-tree slice.
