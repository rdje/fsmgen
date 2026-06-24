---
id: ial2-two-dynamic-one-static-read-rlast-read-data-burst-length-selection
title: Two-dynamic/one-static mixed read RLAST read-data burst-length readiness selected
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.351 select?"
  - "what is the next task after two-dynamic-plus-static mixed read RLAST read-data shipped?"
  - "which task owns raw-ARLEN readiness after two-dynamic-plus-static mixed read RLAST read-data?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, read-response-demux, rlast, burst-length, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.351|IAL2-FEATURE-COMPLETENESS-FRONTIER\.352|POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_NEXT_SLICE_SELECTION|two-dynamic-plus-one-static raw-ARLEN|report-only raw-ARLEN burst-length readiness|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data' docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.351` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.352`, readiness audit for report-only
raw-`ARLEN` burst-length capture over the shipped two-dynamic-plus-one-static
mixed dynamic/static read burst-last scalar last-beat read-data boundary.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifacts, tests, schedule/check or
semantic JSON, or HDL behavior. `.352` later decided whether direct
implementation is ready, a public contract-selection leaf is needed first,
helper/report cleanup should precede it, or another exact owner should take
priority.
