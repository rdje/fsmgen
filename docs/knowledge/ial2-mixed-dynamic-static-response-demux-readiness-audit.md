---
id: ial2-mixed-dynamic-static-response-demux-readiness-audit
title: IAL2 mixed dynamic/static response-demux audit selects write BID contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.270 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.271?"
  - "is mixed dynamic/static response-demux ready?"
  - "which mixed dynamic/static response-demux family comes first?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, response-demux, mixed-dynamic-static, readiness]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.270|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.271|MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT|bounded mixed dynamic/static write `BID` response-demux|requires every write transaction to use dynamic IDs' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.270` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.271`, public contract selection for
bounded mixed dynamic/static write `BID` response-demux.

The audit changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifacts, tests, JSON, or HDL behavior.

Current dynamic response-demux intentionally fails closed unless every
selected transaction in the family uses dynamic IDs. That protects against a
raw response matching both static concrete-ID state and active dynamic
captured-ID state before the public ownership/assertion contract is selected.
Write `BID` is the first safe mixed family because it avoids read `RLAST`,
burst-length/runtime validation, read-data routing, and multi-beat
output-bank coupling.
