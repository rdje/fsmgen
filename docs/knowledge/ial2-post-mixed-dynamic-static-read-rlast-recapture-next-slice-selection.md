---
id: ial2-post-mixed-dynamic-static-read-rlast-recapture-next-slice-selection
title: Post mixed read RLAST recapture selects broader mixed recapture audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.397 select?"
  - "what is next after mixed dynamic/static read RLAST recapture?"
  - "why is broader mixed dynamic/static recapture next?"
  - "is validation retry after the mixed read RLAST recapture RAM cutoff the next owner?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, recapture, selection, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.397|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.398|POST_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION|broader mixed dynamic/static|validation retry' docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.397` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.398`, readiness audit for broader mixed
dynamic/static same-cycle release-and-recapture.

The selector changes no behavior. It chooses a readiness audit because the
one-dynamic plus one-static mixed write/read/read-`RLAST` recapture family has
shipped, while broader public mixed shapes add multiple static busy slots,
possible multiple dynamic selected-ID slots, sibling request blocking,
static-ID exclusion lists, active dynamic-ID uniqueness, and read burst-last
raw non-final beat preservation.

The `.396` RAM-guard cutoff is recorded but not selected as the next owner.
Future audit or implementation leaves can retry guarded probes when host
memory permits; no cutoff is raised.
