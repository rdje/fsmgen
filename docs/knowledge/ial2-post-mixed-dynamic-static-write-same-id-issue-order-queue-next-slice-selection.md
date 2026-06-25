---
id: ial2-post-mixed-dynamic-static-write-same-id-issue-order-queue-next-slice-selection
title: Post mixed dynamic/static write BID issue-order queue selects mixed read RID readiness audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.504 select?"
  - "what is next after mixed dynamic/static write BID issue-order queue?"
  - "is sv2v required after mixed dynamic/static write issue-order queue?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, mixed-dynamic-static, same-id-ordering, issue-order-queue, read-rid, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.504|IAL2-FEATURE-COMPLETENESS-FRONTIER\.505|POST_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION|mixed dynamic/static read single-beat `RID` same-ID `issue-order-queue`|sv2v' docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.504` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.505`, readiness audit for generated mixed
dynamic/static read single-beat `RID` same-ID `issue-order-queue` behavior.

The selected audit is the smallest adjacent FSMGen-owned continuation after
`.503`: one dynamic read transaction plus one concrete static read
transaction, generated single-beat `RID` completions, compact runtime-ID queue
slots, dynamic enqueues from `axi0_arid`, and static enqueues from the concrete
sized literal if implementation proves ready.

External converter dependencies such as `sv2v` remain deferred and are not
required for `.505`.
