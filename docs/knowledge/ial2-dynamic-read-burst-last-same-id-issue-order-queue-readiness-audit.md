---
id: ial2-dynamic-read-burst-last-same-id-issue-order-queue-readiness-audit
title: Dynamic read burst-last same-ID queue readiness selects contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.461 decide?"
  - "is dynamic read burst-last same-ID issue-order queue ready for direct implementation?"
  - "what comes after the dynamic read burst-last queue readiness audit?"
  - "why does dynamic read burst-last queue need a contract selection?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, read-rid, rlast, readiness]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.461|IAL2-FEATURE-COMPLETENESS-FRONTIER\.462|DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT|supports only response_scope single-beat|generated_dynamic_demux_last_beat|nonlast_no_dequeue|final-beat-only selected dequeue' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.461` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.462`, public contract selection for
generated dynamic read burst-last `RID && RLAST` same-ID `issue-order-queue`
behavior.

The audit found no lower parser, report-schema, IAL1, IAL0, or SystemVerilog
prerequisite. Existing dynamic burst-last demux already has final
`RID && RLAST` completions and raw non-final beat assertions, concrete
queue-head burst-last behavior already proves non-last no-dequeue semantics,
and the dynamic single-beat queue already proves compact runtime-ID slots.

Direct implementation is still not selected. The contract must first pin
final-beat-only selected dequeue, raw non-final beat preservation, one-bit
`last-signal` requirements, selected completion source/report vocabulary,
queue assertions, residue movement, diagnostics, support-accounting identity,
validation gates, rollback, and the first response-demux-only sample boundary.
