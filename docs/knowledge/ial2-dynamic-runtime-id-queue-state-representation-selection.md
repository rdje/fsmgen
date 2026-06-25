---
id: ial2-dynamic-runtime-id-queue-state-representation-selection
title: Dynamic same-ID queues use compact runtime-ID issue-order slots first
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.454 select?"
  - "what is the runtime-ID queue-state representation for dynamic issue-order queues?"
  - "how should generated dynamic same-ID issue-order queues match BID responses?"
  - "what comes after runtime-ID queue-state representation selection?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, representation]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_ID_QUEUE_STATE_REPRESENTATION_SELECTION.md; docs/AXI_IAL2_MANAGER_GENERATED_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.454|IAL2-FEATURE-COMPLETENESS-FRONTIER\.455|compact_runtime_id_issue_order_slots|dynamic_issue_order_earliest_matching_slot|write_bid_two_dynamic_transactions' docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_ID_QUEUE_STATE_REPRESENTATION_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.454` selects
`compact_runtime_id_issue_order_slots` for the first generated dynamic
same-ID `issue-order-queue` behavior and selects `.455`, implementation of
the bounded two-transaction all-dynamic write `BID` dynamic issue-order queue.

Each queue slot stores one-hot transaction identity plus a slot-local
captured runtime ID. A raw `BID` response selects the earliest valid slot
whose captured ID equals `BID`; if two slots hold the same ID, slot0 wins,
while a different-ID slot1 response may complete ahead of slot0.

The representation replaces reject-only active-ID uniqueness evidence for the
queue path. Dynamic `reject` mappings keep `active_dynamic_ids_must_be_unique`;
dynamic `issue-order-queue` behavior uses queue-specific space, duplicate
transaction, no-match, selected-match, and earliest-match assertions.
