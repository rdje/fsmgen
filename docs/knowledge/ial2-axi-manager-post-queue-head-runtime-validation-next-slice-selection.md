---
id: ial2-axi-manager-post-queue-head-runtime-validation-next-slice-selection
title: IAL2 queue-head runtime-validation selector chose queue-head multi-beat read-data
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.120 select?"
  - "what is the next slice after queue-head runtime validation?"
  - "why is queue-head multi-beat read-data next?"
  - "is queue-head multi-beat read-data selected?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, queue-head, read-data, multi-beat, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.120|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.121|queue-head multi-beat|output-bank|per_beat_output_bank|generated_queue_head_response_demux_last_beat_completion_pulse' docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.120` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.121`, generated multi-beat read-data
output-bank behavior for the bounded read burst-last concrete same-ID
queue-head demux shape.

The selector chose this because `.119` now ships queue-head beat-count/`RLAST`
runtime validation and the `.119` sample's remaining read-data residue is the
multi-beat output/aggregation family. The existing auto-ID multi-beat path
already proves per-beat output banks, valid masks, length outputs, scalar
`RRESP` aggregation, matched-read-beat lane capture, and SV-backed lowering.

The direct blocker is the read-data coverage map, which currently admits
concrete same-ID queue-head `read-data` only for single-beat and last-beat
capture. `.121` owns adding the bounded `capture-scope multi-beat` queue-head
shape while preserving the existing queue-head completion-validity report.
