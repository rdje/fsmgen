---
id: ial2-dynamic-read-burst-last-depth3-same-id-issue-order-queue-read-data-readiness-audit
title: Depth-3 dynamic read RLAST queue read-data audit selects direct implementation
answers:
  - "is read-data over the depth-3 dynamic read RLAST issue-order queue ready?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.490 select?"
  - "what blocks depth-3 dynamic RLAST queue read-data today?"
  - "does FSMGen need sv2v for depth-3 dynamic RLAST queue read-data?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, rlast, read-data, readiness]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.490|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.491|DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT|dynamic issue-order queue coverage requires|axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data|sv2v' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`.490` selects `.491`, direct bounded implementation of scalar last-beat
read-data over the generated all-dynamic read burst-last `RID && RLAST`
same-ID `issue-order-queue` depth-3 behavior shipped in `.488`.

The audit found the blocker is local to dynamic issue-order queue read-data
coverage: it currently requires exactly two dynamic transactions and one
depth-2 queue. A RAM-guarded temporary candidate with `r0`, `r1`, and `r2`
failed closed at that coverage diagnostic after parser/PPIF shape acceptance.
FSMGen-owned generation/lowering remains the default; `sv2v` is not selected
as a dependency for this slice.
