---
id: ial2-post-three-static-mixed-dynamic-static-read-data-next-slice-selection
title: Post three-static mixed read-data selector chooses raw-ARLEN audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.331 select?"
  - "what is next after three-static mixed read-data?"
  - "should three-static mixed read-data raw ARLEN be implemented directly?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.332?"
  - "which three-static mixed read-data work remains deferred after .331?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read, read-data, burst-length, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.331|IAL2-FEATURE-COMPLETENESS-FRONTIER\.332|POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION|raw-ARLEN|burst-length' docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.331` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.332`, a readiness audit for report-only
raw-`ARLEN` burst-length capture over generated one-dynamic plus
three-concrete-static mixed dynamic/static read burst-last response-demux and
scalar last-beat read-data.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior. It follows the existing read-data ladder:
raw-`ARLEN` burst-length capture must be audited before runtime beat-count
validation and multi-beat output banks over the three-static boundary.

`.332` must decide whether the three-static report-only raw-`ARLEN` shape can
be implemented directly, needs public contract selection first, needs
helper/report cleanup first, or should defer behind another prerequisite.
Runtime validation, multi-beat output banks, two-dynamic-plus-static shapes,
broader mixed cardinalities, same-cycle widening, queues/scoreboards, backend
variants, and VHDL remain deferred.
