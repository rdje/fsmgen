---
id: ial2-axi-manager-post-queue-head-burst-length-next-slice-selection
title: Post queue-head burst-length selector chooses queue-head runtime validation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.118 select?"
  - "what comes after queue-head burst-length capture?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.119?"
  - "why is queue-head runtime validation next?"
  - "is multi-beat queue-head read-data next after queue-head burst-length?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, read-data, queue-head, selector, burst-length, rlast, runtime-validation]
evidence: docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.118|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.119|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.120|POST_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION|queue-head runtime|beat-count/RLAST|runtime_assertion|generated_queue_head_response_demux_last_beat_completion_pulse' docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.118` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.119`: generated queue-head
beat-count/`RLAST` runtime validation for the bounded read burst-last
concrete same-ID queue-head last-beat read-data shape. `.119` has since
shipped that selected behavior.

The selection is narrow because `.117` already generates request-bound
raw-`ARLEN` capture for the queue-head last-beat shape, and the existing
auto-ID runtime-validation path already proves expected-count storage, beat
counters, generated assertions, report fields, and HDL lowering.

The `.119` implementation should preserve the queue-head last-beat
completion validity
`generated_queue_head_response_demux_last_beat_completion_pulse`, keep raw
`ARLEN` capture request-bound, and count matched read beats using raw read
response event plus concrete `RID` plus active queue-head transaction
identity, not `RLAST`-qualified completion pulses.

The active frontier advances to `IAL2-FEATURE-COMPLETENESS-FRONTIER.120`,
the next queue-head/read-data expansion selector. Multi-beat queue-head
read-data remains behind an explicit selector because it needs beat-index
state, per-beat output-bank writes, valid-mask/length outputs, and scalar
`RRESP` aggregation on top of the newly shipped runtime validation. Deeper or
multiple queue groups, mixed same-family auto-ID plus concrete queue-head
demux, direct backend lowering, and VHDL remain deferred.
