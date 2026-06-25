---
id: ial2-dynamic-same-id-issue-order-queue-identity-recapture-behavior
title: Dynamic same-ID issue-order queue identity recapture refreshes captured IDs
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.477 ship?"
  - "does generated dynamic issue-order queue support same-transaction recapture now?"
  - "which dynamic queue rules refresh ARID or AWID on same-transaction recapture?"
  - "does queue identity recapture add release_recapture report fields?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, recapture, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.477|IDENTITY_RECAPTURE_BEHAVIOR|same-transaction ID-refresh|w0_dequeue_enqueue_w0|w1_w0_dequeue_enqueue_w0|r0_dequeue_enqueue_r0|r1_r0_dequeue_enqueue_r0|same_identity_state|generated_update_rules' docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_BEHAVIOR.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`.477` ships state-key-preserving dynamic same-ID `issue-order-queue`
recapture ID refresh. The dynamic transition generator now keeps unchanged
transaction-identity transitions when the selected dequeued transaction is
admitted again in the same cycle.

Generated update rules now include same-transaction refresh forms such as
`w0_dequeue_enqueue_w0`, `w1_w0_dequeue_enqueue_w0`,
`r0_dequeue_enqueue_r0`, and `r1_r0_dequeue_enqueue_r0`. Those rules refresh
the affected slot ID from the current `AWID` or `ARID` while preserving
retained slot IDs.

Queue reports still expose this through the literal `generated_update_rules`
list. `.477` does not add `same_cycle_release_recapture_policy` or
`release_recapture_*` fields to queue reports; those remain response-demux
capture-state vocabulary.
