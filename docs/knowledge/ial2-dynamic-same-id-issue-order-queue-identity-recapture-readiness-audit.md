---
id: ial2-dynamic-same-id-issue-order-queue-identity-recapture-readiness-audit
title: Dynamic same-ID issue-order queue identity recapture needs ID-refresh rules
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.476 select?"
  - "why are dynamic queue r0_dequeue_enqueue_r0 rules needed?"
  - "does generated dynamic issue-order queue support same-transaction recapture?"
  - "what is the next queue recapture implementation owner?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, recapture, readiness]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_RECAPTURE_REPORT_CONTRACT_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.476|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.477|IDENTITY_RECAPTURE_READINESS_AUDIT|state-key-preserving|r0_dequeue_enqueue_r0|w0_dequeue_enqueue_w0|_dynamic_same_id_issue_order_queue_transition_specs|_dynamic_same_id_issue_order_queue_assignments' docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`.476` selected `.477`, direct implementation of state-key-preserving dynamic
same-ID `issue-order-queue` recapture ID refresh.

Current dynamic queue transition generation skips transitions whose
transaction-identity state key is unchanged. That omits rules such as
`r0_dequeue_enqueue_r0` and `w0_dequeue_enqueue_w0`, even though a selected
dequeue plus same-transaction enqueue must refresh the slot-local captured
request ID from the current `ARID` or `AWID`.

The source shape is already accepted and assertions allow it when the selected
dequeue frees the transaction. The next owner should generate the missing
state-key-preserving update rules and update literal `generated_update_rules`
expectations, while keeping classic `same_cycle_release_recapture_policy` and
`release_recapture_*` fields exclusive to response-demux capture state.
