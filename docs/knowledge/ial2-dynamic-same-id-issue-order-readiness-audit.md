---
id: ial2-dynamic-same-id-issue-order-readiness-audit
title: Dynamic same-ID issue-order readiness selected dynamic transaction-ID contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.216 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.217?"
  - "what comes after dynamic same-ID issue-order readiness?"
  - "why is dynamic transaction-ID contract selection next?"
  - "does FSMGen support dynamic user-ID arbitration?"
date: 2026-06-22
status: current
tags: [ial2, axi, manager, same-id, dynamic-id, issue-order, task-tree]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.216|IAL2-FEATURE-COMPLETENESS-FRONTIER\.217|DYNAMIC_SAME_ID_ISSUE_ORDER_READINESS_AUDIT|dynamic/user transaction-ID|dynamic user-ID arbitration|auto` or concrete' docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.216` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.217`, public dynamic/user transaction-ID
contract selection before generalized per-ID issue-order queues.

The audit found no stale support/report cleanup or lower-layer prerequisite.
Bounded concrete queue-head behavior is generated over static concrete ID
values and finite transaction inventory, including counted request-set fit
guards and concrete-ID group request assertions for selected multi-group
queue-head families. Live reports for those bounded samples still honestly
leave `per_id_issue_order_queues` residue.

Dynamic user-ID arbitration remains unsupported. The current PPIF transaction
surface accepts only `(id auto)` and `(id (value N))`, so generalized dynamic
per-ID queues or scoreboards need a public source/report contract before any
parser or generator behavior changes.
