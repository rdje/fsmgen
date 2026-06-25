---
id: ial2-dynamic-read-burst-last-depth3-same-id-issue-order-queue-read-data-burst-length-readiness-audit
title: Depth-3 dynamic RLAST queue read-data raw-ARLEN audit selects direct implementation
answers:
  - "is raw ARLEN over depth-3 dynamic RLAST queue read-data ready?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.493 select?"
  - "what blocks depth-3 dynamic RLAST queue read-data raw ARLEN today?"
  - "does FSMGen need sv2v for depth-3 dynamic RLAST queue raw ARLEN?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, rlast, read-data, burst-length, arlen, readiness]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.493|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.494|DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT|one depth-3 all-dynamic queue|report-only raw-`?ARLEN`?|axi0_r2_arlen_q|sv2v' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`.493` selects `.494`, direct bounded implementation of report-only
raw-`ARLEN` burst-length capture over the generated all-dynamic read
burst-last `RID && RLAST` depth-3 same-ID `issue-order-queue` scalar
read-data behavior shipped in `.491`.

The audit found only a local dynamic issue-order queue read-data coverage
blocker: the current branch allows depth-3 last-beat queue read-data only
when `burst_length` metadata is absent, while the existing depth-2 queue path
already supports report-only/runtime `burst_length`. A RAM-guarded in-memory
candidate with the existing public burst-length clause failed closed at that
local diagnostic. The storage/rule/report helpers already enumerate covered
transactions, so no parser, IAL1, IAL0, SystemVerilog, backend-language,
`sv2v`, or VHDL prerequisite was selected.
