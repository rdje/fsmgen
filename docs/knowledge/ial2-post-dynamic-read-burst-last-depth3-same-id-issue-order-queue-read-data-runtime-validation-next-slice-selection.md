---
id: ial2-post-dynamic-read-burst-last-depth3-same-id-issue-order-queue-read-data-runtime-validation-next-slice-selection
title: Post depth-3 dynamic RLAST queue runtime-validation selector chooses multi-beat readiness
answers:
  - "what comes after depth-3 dynamic RLAST queue runtime validation?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.498 select?"
  - "is sv2v selected after depth-3 dynamic RLAST queue runtime validation?"
  - "why audit multi-beat after depth-3 dynamic RLAST queue runtime validation?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, rlast, read-data, burst-length, runtime-validation, multi-beat, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.498|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.499|POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION|multi-beat output banks|sv2v' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`.498` selects `.499`, readiness audit for multi-beat output banks over the
generated all-dynamic read burst-last `RID && RLAST` depth-3 same-ID
`issue-order-queue` runtime-validation read-data behavior shipped in `.497`.

The selector chooses multi-beat readiness because `.497` supplies the
three-transaction runtime-validation queue read-data surface and `.467`,
`.469`, `.471`, and `.473` establish the two-transaction dynamic queue
read-data ladder: scalar read-data, report-only raw-`ARLEN`, runtime
validation, and multi-beat output banks. FSMGen-owned generation/lowering
remains the default; `sv2v` is not selected as a dependency.
