---
id: ial2-three-static-mixed-dynamic-static-read-response-demux-readiness-audit
title: Three-static mixed dynamic/static read demux needs contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.320 select?"
  - "is three-static mixed dynamic/static read demux ready for direct behavior?"
  - "what comes after the three-static mixed read readiness audit?"
  - "which sample should cover one dynamic plus three static read demux?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read, response-demux, readiness]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.320|IAL2-FEATURE-COMPLETENESS-FRONTIER\.321|THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT|requires one dynamic and one or two static transactions|read_mixed_dynamic_static_response_demux_multi_static3' docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.320` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.321`, public contract selection for
bounded one-dynamic plus three-concrete-static mixed dynamic/static read
single-beat `RID` response-demux.

Direct behavior is not selected. The current read builder, burst-last
normalization, and read-data coverage still encode the one-dynamic plus one-
or two-static read boundary, so `.321` must first select the public source,
report, diagnostic, validation, and rollback contract.
