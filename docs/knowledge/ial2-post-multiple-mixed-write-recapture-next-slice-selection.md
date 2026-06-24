---
id: ial2-post-multiple-mixed-write-recapture-next-slice-selection
title: Post two-static mixed write recapture selector chooses three-static contract
answers:
  - "what follows two-static mixed dynamic/static write recapture?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.401 select?"
  - "why is three-static mixed write recapture next?"
  - "why not two-dynamic mixed write recapture next?"
  - "which sample owns the next broader mixed write recapture contract?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, write, recapture, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.401|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.402|POST_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION|write_mixed_dynamic_static_response_demux_multi_static3|three-static mixed write recapture|generated_multi_mixed_dynamic_static_demux_completion' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.401` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.402`, public contract selection for
one-dynamic plus three-static mixed dynamic/static write `BID` same-cycle
release-and-recapture.

The selected sample is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif
```

Three-static mixed write recapture is next because it extends `.400` by one
more concrete static sibling while staying in the same write-only,
one-dynamic cardinality. Two-dynamic-plus-one-static recapture is deferred
because it adds multiple active dynamic selected-ID ownership, active
dynamic-ID uniqueness, and no-active-same-ID checks. Broader mixed read
recapture is deferred behind read `RID`/`RLAST`, read-data, raw-`ARLEN`,
runtime, and multi-beat preservation concerns.
