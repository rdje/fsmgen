---
id: ial2-axi-manager-same-id-issue-order-queue-contract-selection
title: Same-ID issue-order queue contract selects family-local policy and readiness audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.94 select?"
  - "what is the AXI same-ID issue-order queue contract?"
  - "what is the public spelling for AXI issue-order queue policy?"
  - "does issue-order-queue accept same-ID reuse yet?"
  - "what comes after AXI same-ID issue-order queue contract selection?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, issue-order, queue, response-demux, task-tree]
evidence: docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.94|IAL2-FEATURE-COMPLETENESS-FRONTIER\.95|IAL2-FEATURE-COMPLETENESS-FRONTIER\.96|issue-order-queue|issue_order_queue|selected_not_generated|queue-head response-demux|generated_queue_behavior' docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.94` selected the public AXI same-ID
issue-order queue contract. The source spelling stays inside the existing
AXI-profile-local `same-id-ordering` clause:

```lisp
(same-id-ordering
  (read
    (concrete-id-reuse issue-order-queue))
  (write
    (concrete-id-reuse issue-order-queue)))
```

Read and write arms are independent. The first contract adds no public
`queue-depth` clause. For each selected response family and concrete ID, the
queue depth is statically bounded by the smaller of the family `max-pending`
value and the number of concrete transactions in that family using the same
ID.

The selected generated behavior must enqueue only admitted transaction
requests and dequeue only on queue-head response completion. Same-ID response
demux must use queue-head transaction identity; ID-only matching is
insufficient when multiple authored transactions share the same concrete ID.

The final report spelling is `issue_order_queue` with
`enforcement: generated_issue_order_queue`, `accepted_same_id_reuse: true`,
`generated_queue_behavior: true`, and
`response_demux_strategy: queue_head_issue_order`. Any metadata-only
intermediate slice must report `accepted_same_id_reuse: false`,
`generated_queue_behavior: false`, and
`implementation_status: selected_not_generated`.

`.94` does not accept same-ID reuse in generated artifacts. It advances the
frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.95`, AXI same-ID
issue-order queue behavior readiness, because current response-demux behavior
is auto-ID-oriented and must be audited before parser/report metadata or
generated queue-head behavior ships.

`.95` completed that audit and selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.96`, metadata-first parser/report support
for `issue-order-queue`, while duplicated concrete same-ID reuse remains
fail-closed until generated queue-head behavior ships.
