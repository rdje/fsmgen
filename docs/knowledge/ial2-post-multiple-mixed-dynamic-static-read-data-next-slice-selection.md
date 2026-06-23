---
id: ial2-post-multiple-mixed-dynamic-static-read-data-next-slice-selection
title: Post multiple mixed dynamic/static read-data selector chooses burst-length readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.308 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.309?"
  - "what is next after multiple mixed dynamic/static scalar read-data?"
  - "why is multiple mixed raw ARLEN burst-length readiness next?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, burst-length, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.308|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.309|POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION|multiple mixed dynamic/static raw-`?ARLEN`?|readiness audit for generated report-only raw-`?ARLEN`?' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.308` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.309`, readiness audit for generated
report-only raw-`ARLEN` burst-length capture over generated multiple mixed
dynamic/static read burst-last response-demux and scalar last-beat read-data.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifacts, tests, schedule/check or
semantic JSON, or HDL behavior.

The selected audit follows the shipped ordering used by the dynamic,
multiple-dynamic, queue-head, mixed auto-ID, and one-dynamic plus one-static
mixed read-data families: scalar read-data first, report-only raw `ARLEN`
capture next, runtime beat-count/`RLAST` validation after raw `ARLEN`, and
multi-beat output banks after runtime validation.
