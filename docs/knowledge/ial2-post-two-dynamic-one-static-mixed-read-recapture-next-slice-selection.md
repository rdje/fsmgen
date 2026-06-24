---
id: ial2-post-two-dynamic-one-static-mixed-read-recapture-next-slice-selection
title: Post two-dynamic mixed read recapture next slice selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.428 select?"
  - "what is next after two-dynamic-plus-one-static mixed read recapture?"
  - "why audit two-dynamic mixed read RLAST recapture next?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, recapture, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.428|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.429|POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION|two-dynamic-plus-one-static mixed dynamic/static read burst-last' docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.428` selects `.429`, readiness audit for
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture.

The selector changes no behavior. It follows `.427` because the existing
burst-last public sample has the same r0/r1 dynamic plus r2 static shape, but
adds final-beat completion semantics, raw non-final `RID` preservation, and
burst-last read-data/raw-`ARLEN`/runtime/multi-beat consumer boundaries.

Direct probes confirmed the candidate burst-last samples still report
request-not-busy assertions, no `static_capture`, and no generated
release-recapture rules.
