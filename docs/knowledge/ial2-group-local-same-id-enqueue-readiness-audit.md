---
id: ial2-group-local-same-id-enqueue-readiness-audit
title: Group-local same-ID enqueue needs counted admission capacity first
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.209 decide?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.210?"
  - "can same-ID queue-head request onehot become group-local now?"
  - "why does group-local same-id enqueue need capacity accounting?"
date: 2026-06-21
status: current
tags: [ial2, axi, manager, same-id, queue-head, group-local, capacity]
evidence: docs/AXI_IAL2_MANAGER_GROUP_LOCAL_SAME_ID_ENQUEUE_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.209|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.210|GROUP_LOCAL_SAME_ID_ENQUEUE_READINESS_AUDIT|counted admission|request_fanin|issue_order_queue_request_onehot0|_direction_rules|_same_id_issue_order_queue_transition_specs' docs/AXI_IAL2_MANAGER_GROUP_LOCAL_SAME_ID_ENQUEUE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.209` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.210`, counted admission/capacity
prerequisite audit before group-local simultaneous enqueue widening.

Directly replacing the family-wide `*_issue_order_queue_request_onehot0`
assertion with per-concrete-ID group onehots is not safe yet. Generated
queue-head samples still feed the pending counter with one Boolean
same-direction request fan-in, so two distinct concrete-ID group requests in
one cycle would be counted as one accepted request unless admission/capacity
is widened first.

The queue transition rules are already generated per concrete-ID group and
only exclude multiple enqueues inside that group. Distinct-group enqueue is
therefore not blocked first by queue storage, but it must wait for counted
admission semantics that keep `pending_reads`, `pending_writes`,
`*_slots_available`, `*_full`, and `*_can_accept` consistent.
