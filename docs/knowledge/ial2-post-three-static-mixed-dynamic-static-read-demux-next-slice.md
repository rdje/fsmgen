---
id: ial2-post-three-static-mixed-dynamic-static-read-demux-next-slice
title: After three-static mixed read single-beat demux, audit burst-last readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.323 select?"
  - "what comes after one dynamic plus three static read single-beat demux?"
  - "what is the next three-static mixed dynamic/static read demux owner?"
  - "why not widen three-static mixed read-data immediately?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read, response-demux, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.323|IAL2-FEATURE-COMPLETENESS-FRONTIER\.324|POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION|three-static mixed read burst-last' docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.323` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.324`, readiness audit for bounded
one-dynamic plus three-concrete-static mixed dynamic/static read burst-last
`RID && RLAST` response-demux.

The selector follows the established read-side order: single-beat `RID`
response-demux first, burst-last/final-beat completion semantics second, then
read-data, burst-length/runtime validation, and multi-beat output banks.
Current burst-last normalization still guards the two-static boundary, and
read-data coverage still depends on the existing two-static multiple mixed
read demux shape, so three-static read-data remains behind the burst-last
audit.
