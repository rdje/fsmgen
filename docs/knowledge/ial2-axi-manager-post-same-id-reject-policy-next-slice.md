---
id: ial2-axi-manager-post-same-id-reject-policy-next-slice
title: Same-ID reject policy follow-up selects issue-order queue contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.93 select?"
  - "what is the next AXI manager task after same-ID reject policy?"
  - "should FSMGen implement same-ID issue-order queues directly after reject policy?"
  - "what owns the issue-order-queue policy contract?"
  - "what is the active IAL2 frontier after .93?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, issue-order, queue, policy, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_SAME_ID_REJECT_POLICY_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.93|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.94|issue-order queue policy contract|issue-order-queue|queue-head response-demux' docs/AXI_IAL2_MANAGER_POST_SAME_ID_REJECT_POLICY_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.93` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.94`, AXI same-ID issue-order queue policy
contract selection.

The selector does not change parser, generator, `.isf`, `.fsm`,
SystemVerilog, sample, support-accounting, check JSON, semantic JSON, or
validation behavior. It records that `.92` is policy-only: explicit `reject`
still reports `generated_queue_behavior: false`, generated auto-ID samples
avoid same-ID concurrency rather than accepting reuse, and concrete-ID
response demux needs queue-head issue-order state before it can distinguish
same-ID transactions.

`.94` must define the public `issue-order-queue` spelling, read/write family
scope, depth bounds, enqueue/dequeue semantics, queue-head response-demux
expectations, diagnostics, report vocabulary, validation gates, and rollback
boundary before parser/report metadata or generated queue behavior can ship.
