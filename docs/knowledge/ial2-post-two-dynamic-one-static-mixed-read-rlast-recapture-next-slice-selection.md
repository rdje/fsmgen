---
id: ial2-post-two-dynamic-one-static-mixed-read-rlast-recapture-next-slice-selection
title: Post two-dynamic mixed read RLAST recapture selector chooses dynamic same-ID readiness
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.432 select?"
  - "what comes after two-dynamic-plus-one-static mixed read RLAST recapture?"
  - "which task owns dynamic same-ID readiness after .431?"
  - "why not implement dynamic same-ID queues directly after .432?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.432|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.433|POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION|dynamic same-ID issue-order|same_id_ordering|per-ID issue-order queues' docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.432` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.433`, readiness audit for dynamic same-ID
issue-order policy, queue, and scoreboard ownership after the bounded
dynamic/mixed response-demux, read-data, multi-beat, and same-cycle
release-and-recapture chain reached the two-dynamic-plus-one-static read
burst-last boundary.

The selector changes no behavior. It chooses an audit rather than direct queue
or scoreboard implementation because dynamic same-ID admission needs a public
issue-order policy, queue/scoreboard boundary, overflow/ambiguity assertions,
and report/residue movement before generated behavior can be widened.
