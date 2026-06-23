---
id: ial2-post-multiple-mixed-multi-beat-next-slice
title: Post multiple mixed multi-beat selector chooses broader cardinality audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.315 select?"
  - "what comes after multiple mixed dynamic/static multi-beat output banks?"
  - "what is the next IAL2 frontier after .314?"
  - "when will broader mixed dynamic/static cardinality be audited?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, multi-beat, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.315|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.316|POST_MULTIPLE_MIXED_MULTI_BEAT_NEXT_SLICE_SELECTION|broader mixed dynamic/static transaction cardinality' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_MULTI_BEAT_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.315` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.316`, a readiness audit for broader mixed
dynamic/static transaction cardinality after generated multiple mixed
dynamic/static read-data reached multi-beat output banks in `.314`.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check/
semantic JSON, or HDL behavior.

The audit must decide whether the next owner should directly implement a
bounded broader mixed shape, first select a public source/report contract, land
a helper/report prerequisite, or defer in favor of same-cycle, queue,
scoreboard, backend, or VHDL work.
