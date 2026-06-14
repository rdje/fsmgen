---
id: ial2-axi-manager-same-id-queue-state-representation
title: Same-ID issue-order queues use compact one-hot transaction slots
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.101 decide?"
  - "what queue representation did FSMGen select for AXI same-ID issue-order queues?"
  - "does FSMGen use arrays for same-ID issue-order queues?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.102?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, issue-order, queue, representation, task-tree]
evidence: docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_REPRESENTATION_SELECTION.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_DEMUX_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.101|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.102|compact_onehot_transaction_slots|queue-head response-demux contract|dynamic indexed|admitted request pulses' docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_REPRESENTATION_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.101` selected
`compact_onehot_transaction_slots` as the future generated representation for
AXI same-ID `issue-order-queue` state.

Each generated queue is family-local and concrete-ID-value-local, uses compact
explicit slots with slot `0` as the head, stores one transaction identity bit
per slot/transaction, and is bounded by `min(max-pending, concrete transaction
inventory)`. The representation avoids arrays, dynamic indexed left-hand
sides, hidden unbounded queues, and pointer modulo arithmetic.

Enqueue remains sourced only from admitted request pulses. Dequeue is named as
a future `queue_dequeue_event` from queue-head response demux.

The next active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.102`, AXI
same-ID queue-head response-demux contract selection, because existing
`response-demux` syntax and generated behavior are auto-ID-lifecycle oriented.
