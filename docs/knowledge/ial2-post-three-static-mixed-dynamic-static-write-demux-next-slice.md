---
id: ial2-post-three-static-mixed-dynamic-static-write-demux-next-slice
title: IAL2 post three-static mixed dynamic/static write demux next slice
answers:
  - what did IAL2-FEATURE-COMPLETENESS-FRONTIER.319 select?
  - what comes after one dynamic plus three static write demux?
  - should three-static mixed dynamic/static read-data be implemented directly?
  - what is the next IAL2 frontier after .318?
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read, response-demux, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_CARDINALITY_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_CARDINALITY_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.319|IAL2-FEATURE-COMPLETENESS-FRONTIER\.320|POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION|requires one dynamic and one or two static transactions|three-static read single-beat' docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.319` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.320`, a readiness audit for bounded
one-dynamic plus three-concrete-static mixed dynamic/static read
response-demux after `.318` shipped the corresponding write `BID`
response-demux.

Direct three-static read-data implementation is not selected. The current
read builder, burst-last normalization, and read-data coverage still encode
the one-dynamic plus one- or two-static read boundary, so `.320` must audit
the read response-demux boundary first.
