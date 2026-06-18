---
id: ial2-axi-manager-post-multiple-mixed-depth3-burst-length-next-slice-selection
title: Post multiple/mixed depth-3 burst-length selector chooses runtime validation audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.184 select?"
  - "what comes after multiple/mixed depth-3 queue-head report-only ARLEN?"
  - "what is the next slice after multiple/mixed depth-3 queue-head burst-length behavior?"
  - "why is runtime validation next after multiple/mixed depth-3 burst-length?"
date: 2026-06-18
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3, burst-length, runtime-validation, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.184|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.185|POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION|generated_beat_count_validation|runtime beat-count|burst_length_validation: report_only|burst_length_validation: runtime_assertion' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.184` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.185`, a readiness audit for generated
runtime beat-count/`RLAST` validation over multiple/mixed depth-3 read
burst-last queue-head scalar last-beat read-data.

The selector follows the established sequence used by one-group depth-3 and
multi-group depth-2 queue-head scalar last-beat read-data: no-`burst_length`
scalar last-beat read-data, report-only raw-`ARLEN`, runtime validation, then
multi-beat output-bank behavior only behind later exact owners.

The `.183` samples keep `generated_beat_count_validation` residue because
they generate report-only raw-`ARLEN` capture, not expected-beat storage,
read-beat counters, beat-count rules, or beat-count/`RLAST` assertions.
Runtime validation is the next prerequisite before multi-beat payload over the
same multiple/mixed depth-3 groups.

Multi-beat payload, write-family read-data, same-family mixed auto-ID,
group-local enqueue widening, packed outputs, alternate burst assembly, direct
backend, verification-output generation, VHDL, and backend-language variants
remain deferred behind separate owned leaves.
