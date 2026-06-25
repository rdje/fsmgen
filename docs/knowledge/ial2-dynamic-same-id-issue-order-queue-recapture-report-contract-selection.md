---
id: ial2-dynamic-same-id-issue-order-queue-recapture-report-contract-selection
title: Dynamic same-ID issue-order queue recapture report contract defers positive field
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.475 select?"
  - "where should dynamic issue-order queue recapture report fields live?"
  - "does the queue report currently guarantee same-transaction recapture?"
  - "why is identity-preserving queue recapture audited next?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, recapture, report, contract-selection]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_RECAPTURE_REPORT_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_RECAPTURE_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.475|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.476|DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_RECAPTURE_REPORT_CONTRACT_SELECTION|identity-preserving same-transaction|generated_update_rules.*literal|same_cycle_release_recapture_policy.*exclusive' docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_RECAPTURE_REPORT_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t
---

`.475` selected `.476`, readiness audit for identity-preserving
same-transaction queue recapture ID refresh.

No positive same-cycle queue recapture report field is selected yet.
`generated_update_rules` remains a literal generated-rule list under
`same_id_ordering.dynamic_id_reuse_policy.{read,write}.generated_queues[]`.

Classic `same_cycle_release_recapture_policy` and `release_recapture_*` fields
remain exclusive to dynamic response-demux capture state. Queue-owned behavior
should use queue terminology after `.476` settles whether a one-entry queue can
dequeue and re-enqueue the same transaction while refreshing the captured
request ID.
