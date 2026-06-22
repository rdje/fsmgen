---
id: ial2-dynamic-transaction-id-capture-matching-readiness-audit
title: Dynamic transaction-ID capture and matching readiness selects write contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.221 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.222?"
  - "why is dynamic write BID matching contract selection next?"
  - "can dynamic transaction ID response matching be implemented directly?"
  - "what comes after dynamic ID capture readiness?"
date: 2026-06-22
status: current
tags: [ial2, axi, manager, dynamic-id, response-matching, bid, task-tree]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_TRANSACTION_ID_METADATA_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.221|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.222|DYNAMIC_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT|dynamic write transaction-ID capture|BID response matching|admitted request|selected_not_generated' docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.221` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.222`, public contract selection for
bounded dynamic write transaction-ID capture and `BID` response matching.

The audit found that existing IAL1/IAL0/SystemVerilog substrate can likely
carry the narrow write shape after contract selection: storage for a selected
ID and busy bit, rule-owned pulse outputs, equality matches against response
IDs, and active/unique assertions already exist for auto-ID response demux.

Generated behavior is not selected directly. The next owner must first define
admitted-request capture timing for the user-supplied request ID,
single-active dynamic ownership, stored-ID lifetime, `BID == captured_id`
completion semantics, diagnostics/assertions, report vocabulary, validation
gates, and explicit residue. Dynamic read matching, same-ID ordering,
read-data routing, queues, scoreboards, and HDL behavior outside the selected
write shape remain future exact-owner work.
