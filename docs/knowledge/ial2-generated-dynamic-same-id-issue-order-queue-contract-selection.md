---
id: ial2-generated-dynamic-same-id-issue-order-queue-contract-selection
title: Generated dynamic issue-order queues need runtime-ID queue-state representation first
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.453 select?"
  - "what is the first generated dynamic issue-order queue contract?"
  - "why is runtime-ID queue-state representation needed before dynamic issue-order queue behavior?"
  - "which family should generated dynamic same-ID issue-order queue behavior start with?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, contract]
evidence: docs/AXI_IAL2_MANAGER_GENERATED_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_GENERATED_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.453|IAL2-FEATURE-COMPLETENESS-FRONTIER\.454|GENERATED_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION|runtime-ID queue-state|dynamic write BID|generated dynamic same-ID issue-order queue' docs/AXI_IAL2_MANAGER_GENERATED_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.453` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.454`, runtime-ID queue-state
representation selection for the first generated dynamic same-ID
`issue-order-queue` behavior.

The first behavior path should start with all-dynamic write `BID`
response-demux plus same-family `(dynamic-id-reuse issue-order-queue)`.
Direct behavior is not selected yet because dynamic issue-order queues must
replace reject-only active-ID uniqueness proofs with explicit runtime-ID queue
state, admitted enqueue/dequeue semantics, response matching, same-cycle
policy, overflow/ambiguity assertions, report fields, and residue movement.

Until generated behavior ships, `accepted_same_id_reuse` and
`generated_queue_behavior` stay false and `dynamic_per_id_issue_order_queues`
residue remains visible.
