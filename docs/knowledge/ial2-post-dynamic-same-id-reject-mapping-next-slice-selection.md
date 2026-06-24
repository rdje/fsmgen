---
id: ial2-post-dynamic-same-id-reject-mapping-next-slice-selection
title: Post dynamic same-ID reject mapping selector chooses single-active audit
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.439 select?"
  - "what comes after dynamic same-ID reject demux mapping?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.440?"
  - "why audit single-active dynamic reject mapping before queues or scoreboards?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.439|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.440|POST_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION|single-active dynamic same-ID reject|idle_or_releasing|dynamic same-ID reject mapping' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.439` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.440`, readiness audit for single-active
dynamic same-ID reject mapping over existing generated single-active dynamic
response-demux assertions.

The selector changes no behavior. It chooses an audit because the single-active
dynamic shapes expose generated `*_dynamic_request_idle_or_releasing`,
active-match, and completion-active assertions, but not the `.438`
multi-active no-active-same-ID plus active-ID uniqueness assertion pair.

One-dynamic mixed mapping, dynamic issue-order queues, dynamic scoreboards,
direct backend behavior, backend-language variants, VHDL, and new generated
HDL remain deferred.
