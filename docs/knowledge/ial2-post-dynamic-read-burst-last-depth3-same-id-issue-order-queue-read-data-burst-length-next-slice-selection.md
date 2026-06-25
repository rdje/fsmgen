---
id: ial2-post-dynamic-read-burst-last-depth3-same-id-issue-order-queue-read-data-burst-length-next-slice-selection
title: Post depth-3 dynamic RLAST queue raw-ARLEN selector chooses runtime validation readiness
answers:
  - "what comes after depth-3 dynamic RLAST queue raw ARLEN read-data?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.495 select?"
  - "is sv2v selected after depth-3 dynamic RLAST queue raw ARLEN?"
  - "why audit runtime validation after depth-3 dynamic RLAST queue raw ARLEN?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, rlast, read-data, burst-length, arlen, runtime-validation, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.495|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.496|POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_NEXT_SLICE_SELECTION|runtime beat-count|sv2v' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`.495` selects `.496`, readiness audit for runtime beat-count/`RLAST`
validation over the generated all-dynamic read burst-last `RID && RLAST`
depth-3 same-ID `issue-order-queue` scalar read-data raw-`ARLEN` behavior
shipped in `.494`.

The selector chooses runtime-validation readiness because `.494` supplies the
three-transaction report-only raw-`ARLEN` queue read-data surface and `.467`,
`.469`, `.471`, and `.473` establish the two-transaction dynamic queue
read-data ladder: scalar read-data, report-only raw-`ARLEN`, runtime
validation, and multi-beat output banks. FSMGen-owned generation/lowering
remains the default; `sv2v` is not selected as a dependency.
