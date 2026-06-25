---
id: ial2-mixed-dynamic-static-read-same-id-issue-order-queue-readiness-audit
title: Mixed dynamic/static read RID issue-order queue is ready for direct bounded implementation
answers:
  - "is mixed dynamic/static read RID same-ID issue-order queue ready?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.505 select?"
  - "where does the mixed dynamic/static read issue-order queue candidate fail today?"
  - "does mixed dynamic/static read issue-order queue require sv2v?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, mixed-dynamic-static, same-id-ordering, issue-order-queue, read-rid, readiness]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Adapter/IAL2/PPIF.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.505|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.506|MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT|requires exactly two all-dynamic read transactions|generated_mixed_dynamic_static_issue_order_queue|sv2v' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`.505` selects `.506`, direct bounded implementation of generated mixed
dynamic/static read single-beat `RID` same-ID `issue-order-queue` behavior for
exactly one dynamic read transaction and one concrete static read transaction.

The parser already accepts `(dynamic-id-reuse issue-order-queue)` on the read
family. A temporary mixed read candidate fails closed in the generator at the
all-dynamic read issue-order queue coverage gate:

```text
response_demux.read dynamic-id-reuse issue-order-queue requires exactly two all-dynamic read transactions, or exactly three all-dynamic read transactions with response_scope single-beat or burst-last in this slice
```

No parser, IAL1, IAL0, SystemVerilog, support-accounting, external converter,
or VHDL prerequisite is required first. The direct implementation should add a
mixed queue plan that stores `axi0_arid` for the dynamic transaction and the
concrete sized literal for the static transaction in compact runtime-ID queue
slots. `sv2v`, mixed read burst-last queues, read-data, broader cardinality,
verification-code generation, direct backend behavior, backend-language
variants, and VHDL remain deferred.
