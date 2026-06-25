---
id: ial2-post-dynamic-read-burst-last-depth3-same-id-issue-order-queue-next-slice-selection
title: Post depth-3 dynamic read RLAST queue selector chooses read-data readiness
answers:
  - "what comes after generated dynamic read RLAST depth-3 same-ID issue-order queue behavior?"
  - "what is the next IAL2 owner after IAL2-FEATURE-COMPLETENESS-FRONTIER.488?"
  - "why audit read-data over the depth-3 dynamic RLAST queue next?"
  - "does FSMGen select sv2v after depth-3 dynamic RLAST queues?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, rlast, read-data, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.489|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.490|POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION|scalar last-beat read-data over the generated all-dynamic read burst-last|read_rid_rlast_three_dynamic_transactions|sv2v' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`.489` selects `.490`, readiness audit for scalar last-beat read-data over
the generated all-dynamic read burst-last `RID && RLAST` same-ID
`issue-order-queue` depth-3 behavior shipped in `.488`.

The selected audit is next because `.488` now provides the missing
three-transaction queue-owned last-beat completion source, while `.465`
through `.473` prove the two-transaction dynamic issue-order queue read-data
chain and the concrete depth-3 queue-head chain proves depth-3 read-data
needs explicit audit ownership. Mixed dynamic/static queues, scoreboards,
arbitrary cardinality, direct backend behavior, backend-language variants,
`sv2v` dependency selection, and VHDL remain deferred.
