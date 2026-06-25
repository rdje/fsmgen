---
id: ial2-dynamic-read-burst-last-depth3-same-id-issue-order-queue-read-data-multi-beat-readiness-audit
title: Depth-3 dynamic RLAST queue multi-beat readiness selects direct implementation
answers:
  - "is multi-beat ready after depth-3 dynamic RLAST queue runtime validation?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.499 select?"
  - "what blocks depth-3 dynamic RLAST queue multi-beat today?"
  - "does depth-3 dynamic RLAST queue multi-beat require sv2v?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, rlast, read-data, runtime-validation, multi-beat, readiness]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.499|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.500|DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT|multi-beat output banks over generated all-dynamic read burst-last|generated_dynamic_issue_order_queue_demux_last_beat|sv2v' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`.499` selects `.500`, direct bounded implementation of multi-beat output
banks over generated all-dynamic read burst-last `RID && RLAST` depth-3
same-ID `issue-order-queue` runtime-validation read-data.

The audit found only the local dynamic issue-order queue read-data coverage
gate: a RAM-guarded temporary depth-3 multi-beat candidate failed closed at the
diagnostic that still admits multi-beat only over two dynamic transactions.
The parser syntax and downstream multi-beat/runtime/report helpers are already
transaction-list driven. FSMGen-owned generation/lowering remains the default;
`sv2v` is not selected as a dependency.
