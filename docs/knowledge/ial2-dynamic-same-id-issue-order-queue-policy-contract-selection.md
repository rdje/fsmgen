---
id: ial2-dynamic-same-id-issue-order-queue-policy-contract-selection
title: Dynamic same-ID issue-order queue policy contract selects metadata-first support
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.449 select?"
  - "what is the public dynamic-id-reuse issue-order-queue spelling?"
  - "does dynamic issue-order queue metadata accept same-ID reuse?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.450?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, contract]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.449|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.450|DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_CONTRACT_SELECTION|dynamic-id-reuse issue-order-queue|dynamic_per_id_issue_order_queues|dynamic_issue_order_queue_selected_not_generated' docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.449` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.450`, metadata-first parser/report
implementation for dynamic same-ID `issue-order-queue` policy.

The public spelling is:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))
```

and the write-family equivalent. Metadata-first support must report
`implementation_status: selected_not_generated`, `enforcement:
not_generated`, `accepted_same_id_reuse: false`,
`request_conflict_policy:
dynamic_issue_order_queue_selected_not_generated`,
`generated_queue_behavior: false`, and `generated_scoreboard_behavior:
false`, with residue including `dynamic_id_same_id_ordering` and
`dynamic_per_id_issue_order_queues`.

Dynamic issue-order queue metadata does not accept same-ID reuse. Accepted
dynamic same-ID reuse remains future generated queue behavior. Dynamic
`scoreboard` remains unsupported.
