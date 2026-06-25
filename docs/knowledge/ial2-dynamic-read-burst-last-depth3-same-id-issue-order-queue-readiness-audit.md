---
id: ial2-dynamic-read-burst-last-depth3-same-id-issue-order-queue-readiness-audit
title: Depth-3 all-dynamic read burst-last queue can be implemented directly
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.487 select?"
  - "is generated dynamic read burst-last depth-3 same-ID issue-order queue ready?"
  - "what owns depth-3 dynamic read burst-last queue implementation?"
  - "what remains deferred after the depth-3 dynamic read burst-last audit?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, cardinality, readiness]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.487|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.488|DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT|read_rid_rlast_three_dynamic_transactions|nonlast_no_dequeue|r2_completion_selected_match|depth-3.*RLAST' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`.487` selects `.488`, direct bounded implementation of one generated
all-dynamic read burst-last `RID && RLAST` same-ID `issue-order-queue` with
exactly three dynamic read transactions, one-bit `last_signal`,
`read-max-pending` at least 3, and queue depth 3.

The audit found only local gates: dynamic read queue admission currently
allows depth 3 only for `single-beat`, the dynamic queue builder admits read
depth 3 only without `last_signal`, and read RLAST scope reporting currently
names only the two-transaction scope.

A direct synthetic helper probe for a depth-3 dynamic read burst-last queue
produced 99 transition rules, 20 assertions, zero duplicate names, the
non-final no-dequeue assertion, the `r2` completion-selected-match assertion,
the slot2 onehot assertion, the tail-selected same-transaction recapture rule,
and the disambiguated cross-transaction enqueue rule.

Read-data over depth-3 queues, mixed dynamic/static queues, scoreboards,
arbitrary cardinality, backend-language variants, external converter
dependencies, and VHDL remain deferred.
