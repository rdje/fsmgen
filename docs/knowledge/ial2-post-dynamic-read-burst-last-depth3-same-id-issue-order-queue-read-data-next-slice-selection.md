---
id: ial2-post-dynamic-read-burst-last-depth3-same-id-issue-order-queue-read-data-next-slice-selection
title: Post depth-3 dynamic RLAST queue read-data selector chooses raw-ARLEN readiness
answers:
  - "what comes after depth-3 dynamic RLAST queue read-data?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.492 select?"
  - "is sv2v selected after depth-3 dynamic RLAST queue read-data?"
  - "why audit raw ARLEN after depth-3 dynamic RLAST queue read-data?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, rlast, read-data, burst-length, arlen, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.492|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.493|POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_NEXT_SLICE_SELECTION|report-only raw-`?ARLEN`?|dynamic RLAST queue read-data raw|sv2v' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`.492` selects `.493`, readiness audit for report-only raw-`ARLEN`
burst-length capture over the generated all-dynamic read burst-last
`RID && RLAST` depth-3 same-ID `issue-order-queue` scalar read-data behavior
shipped in `.491`.

The selector chooses raw-`ARLEN` readiness because `.491` supplies the
three-transaction scalar last-beat queue read-data surface and `.467`,
`.469`, `.471`, and `.473` establish the two-transaction dynamic queue
read-data ladder: scalar read-data, report-only raw-`ARLEN`, runtime
validation, and multi-beat output banks. FSMGen-owned generation/lowering
remains the default; `sv2v` is not selected as a dependency.
