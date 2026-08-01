---
id: ial2-mixed-dynamic-static-read-burst-last-same-id-issue-order-queue-readiness-audit
title: Mixed dynamic/static read RID/RLAST issue-order queue is ready for direct bounded implementation
answers:
  - "is mixed dynamic/static read RID/RLAST same-ID issue-order queue ready?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.508 select?"
  - "where does the mixed dynamic/static read burst-last issue-order queue candidate fail today?"
  - "does mixed dynamic/static read RLAST issue-order queue require sv2v?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, mixed-dynamic-static, same-id-ordering, issue-order-queue, read-rid, rlast, readiness]
evidence: >-
  docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; perl/FSM/Support/RegressionCorpus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md;
  docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.508|IAL2-FEATURE-COMPLETENESS-FRONTIER\.509|MIXED_DYNAMIC_STATIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT|exactly one dynamic plus one concrete static read transaction with response_scope single-beat|generated_mixed_dynamic_static_issue_order_queue_demux_last_beat|sv2v' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.508` selects `.509`, direct bounded
implementation of generated mixed dynamic/static read burst-last `RID &&
RLAST` same-ID `issue-order-queue` behavior for exactly one dynamic read
transaction and one concrete static read transaction.

A temporary `/tmp` candidate derived from the `.506` mixed read queue sample by
switching to `response-scope burst-last` and adding one-bit `axi0_rlast`
failed closed under the RAM guard at the local planner diagnostic that still
allows mixed dynamic/static read issue-order queues only for
`response_scope single-beat`.

No parser, IAL1, IAL0, SystemVerilog, support-accounting, external converter,
or VHDL prerequisite is required first. The direct implementation should add
the mixed read burst-last admission/report path, use compact runtime-ID queue
slots with dynamic `axi0_arid` and static literal enqueue sources, and complete
only on the earliest matching stored `RID` plus `RLAST`. `sv2v`, read-data,
raw `ARLEN`, runtime validation, multi-beat output banks, broader mixed
cardinality, verification-code generation, direct backend behavior,
backend-language variants, and VHDL remain deferred.
