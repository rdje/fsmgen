---
id: ial2-post-mixed-dynamic-static-read-same-id-issue-order-queue-next-slice-selection
title: Post mixed dynamic/static read RID issue-order queue selects mixed read RLAST readiness audit
answers:
  - "what is next after mixed dynamic/static read RID same-ID issue-order queue?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.507 select?"
  - "is sv2v required after mixed dynamic/static read issue-order queue?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, mixed-dynamic-static, same-id-ordering, issue-order-queue, read-rid, rlast, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.507|IAL2-FEATURE-COMPLETENESS-FRONTIER\.508|POST_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION|mixed dynamic/static read burst-last `RID && RLAST`|sv2v' docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.507` selects `.508`, readiness audit for
generated mixed dynamic/static read burst-last `RID && RLAST` same-ID
`issue-order-queue` behavior.

The selector chose `.508` because `.506` shipped the one-dynamic plus one-static
mixed read single-beat queue, `.463` ships all-dynamic read burst-last queue
semantics, and `.280` ships one-dynamic plus one-static mixed read final-beat
response-demux semantics. The next question is local: combine the queue-owned
static/dynamic runtime-ID overlap with final selected `RID && RLAST`
completion.

`sv2v` is not required; FSMGen-owned generation/lowering remains the default.
