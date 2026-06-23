---
id: ial2-three-static-mixed-dynamic-static-read-response-demux-contract-selection
title: Three-static mixed dynamic/static read demux contract starts at single-beat RID
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.321 select?"
  - "what is the three-static mixed dynamic/static read response-demux public contract?"
  - "which sample should cover one dynamic plus three static read demux behavior?"
  - "what comes after the three-static mixed read contract selection?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read, response-demux, contract]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.321|IAL2-FEATURE-COMPLETENESS-FRONTIER\.322|THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION|read_mixed_dynamic_static_response_demux_multi_static3|bounded_multi_mixed_dynamic_static_read_rid_demux_contract' docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.321` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.322`, direct generated behavior for
bounded one-dynamic plus three-concrete-static mixed dynamic/static read
single-beat `RID` response-demux.

The selected public sample stem is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif`.
The report should reuse
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract` and expose the
larger cardinality through existing list-shaped fields.
