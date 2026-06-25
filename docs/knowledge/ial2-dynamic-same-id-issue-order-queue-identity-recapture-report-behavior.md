---
id: ial2-dynamic-same-id-issue-order-queue-identity-recapture-report-behavior
title: Queue identity recapture report fields are generated
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.479 ship?"
  - "what fields report dynamic queue identity recapture support?"
  - "where are same_transaction_recapture fields emitted?"
  - "do dynamic queue reports include release_recapture fields?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, recapture, report-behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_REPORT_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.479|IDENTITY_RECAPTURE_REPORT_BEHAVIOR|same_transaction_recapture_policy|same_transaction_recapture_rule_scope|same_transaction_recapture_id_source|refresh_captured_request_id|state_key_preserving_selected_dequeue_enqueue|release_recapture' docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_REPORT_BEHAVIOR.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`.479` ships positive queue-owned report fields for generated dynamic same-ID
`issue-order-queue` identity recapture.

Each generated dynamic queue entry under
`same_id_ordering.dynamic_id_reuse_policy.{read,write}.generated_queues[]`
now reports `same_transaction_recapture_policy:
refresh_captured_request_id`, `same_transaction_recapture_rule_scope:
state_key_preserving_selected_dequeue_enqueue`, and
`same_transaction_recapture_id_source` set to the queue request-ID source.

Queue reports still do not include `same_cycle_release_recapture_policy` or
`release_recapture_*` fields; those remain response-demux capture-state
vocabulary.
