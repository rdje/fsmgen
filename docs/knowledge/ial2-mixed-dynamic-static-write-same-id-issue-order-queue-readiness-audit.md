---
id: ial2-mixed-dynamic-static-write-same-id-issue-order-queue-readiness-audit
title: Mixed dynamic/static write BID issue-order queue is ready for direct bounded implementation
answers:
  - "is mixed dynamic/static write BID same-ID issue-order queue ready?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.502 select?"
  - "where does the mixed dynamic/static write issue-order queue candidate fail today?"
  - "does mixed dynamic/static write issue-order queue require sv2v?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, mixed-dynamic-static, same-id-ordering, issue-order-queue, write-bid, readiness]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Adapter/IAL2/PPIF.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.502|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.503|MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT|requires exactly two or three all-dynamic write transactions|generated_mixed_dynamic_static_issue_order_queue|sv2v' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_SAME_ID_ISSUE_ORDER_QUEUE_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`.502` selects `.503`, direct bounded implementation of generated mixed
dynamic/static write `BID` same-ID `issue-order-queue` behavior for exactly
one dynamic write transaction and one concrete static write transaction.

The parser already accepts `(dynamic-id-reuse issue-order-queue)`. A
temporary mixed write candidate fails closed in the generator at the
all-dynamic write issue-order queue coverage gate:

```text
response_demux.write dynamic-id-reuse issue-order-queue requires exactly two or three all-dynamic write transactions in this slice
```

No parser, IAL1, IAL0, SystemVerilog, support-accounting, external converter,
or VHDL prerequisite is required first. The direct implementation should add a
mixed queue plan that stores `axi0_awid` for the dynamic transaction and the
concrete sized literal for the static transaction in compact runtime-ID queue
slots. `sv2v` remains deferred and is not a dependency.
