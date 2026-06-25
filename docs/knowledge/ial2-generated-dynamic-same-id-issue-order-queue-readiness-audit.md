---
id: ial2-generated-dynamic-same-id-issue-order-queue-readiness-audit
title: Generated dynamic issue-order queues need contract selection first
answers:
  - "is generated dynamic-id-reuse issue-order-queue behavior ready?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.452 select?"
  - "what comes after the dynamic issue-order queue readiness audit?"
  - "why not implement generated dynamic issue-order queues directly?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, audit]
evidence: docs/AXI_IAL2_MANAGER_GENERATED_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.452|IAL2-FEATURE-COMPLETENESS-FRONTIER\.453|GENERATED_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT|generated dynamic same-ID issue-order queue|dynamic_per_id_issue_order_queues' docs/AXI_IAL2_MANAGER_GENERATED_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.452` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.453`, public contract selection for
generated dynamic same-ID `issue-order-queue` behavior.

Direct generated behavior is not ready. Existing dynamic response-demux
behavior captures runtime IDs and matches responses for bounded unique-ID
shapes, but issue-order queues must first define the public family/scope,
runtime-ID queue key, entry state, admitted enqueue, dequeue, response
matching, ordering guarantees, overflow/ambiguity assertions, report fields,
and residue movement.

Dynamic `scoreboard`, direct backend behavior, backend-language variants, and
VHDL remain later exact-owner work.
