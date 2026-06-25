---
id: ial2-dynamic-same-id-issue-order-queue-identity-recapture-report-contract-selection
title: Queue identity recapture report fields live under generated dynamic queues
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.478 select?"
  - "where should dynamic queue identity recapture report fields live?"
  - "what report fields summarize same-transaction queue recapture?"
  - "should queue identity recapture use release_recapture report fields?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, recapture, report-contract]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_REPORT_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_RECAPTURE_REPORT_CONTRACT_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.478|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.479|IDENTITY_RECAPTURE_REPORT_CONTRACT_SELECTION|same_transaction_recapture_policy|same_transaction_recapture_rule_scope|same_transaction_recapture_id_source|refresh_captured_request_id|state_key_preserving_selected_dequeue_enqueue|release_recapture' docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_REPORT_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`.478` selected `.479`, direct public report/static alignment for the dynamic
same-ID `issue-order-queue` identity-recapture behavior shipped in `.477`.

The positive queue recapture report fields should live under each generated
dynamic queue entry:
`same_id_ordering.dynamic_id_reuse_policy.{read,write}.generated_queues[]`.
The selected field names are `same_transaction_recapture_policy`,
`same_transaction_recapture_rule_scope`, and
`same_transaction_recapture_id_source`.

Queue reports should not use `same_cycle_release_recapture_policy` or
`release_recapture_*` fields; those remain response-demux capture-state
vocabulary.
