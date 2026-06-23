---
id: ial2-mixed-dynamic-static-read-response-demux-contract-selection
title: Mixed dynamic/static read demux contract selects direct single-beat behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.275 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.276?"
  - "what is the mixed dynamic/static read response-demux contract?"
  - "what public sample will mixed dynamic/static read single-beat demux use?"
  - "what follows mixed dynamic/static read demux contract selection?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, contract-selection]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.275|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.276|MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION|bounded_mixed_dynamic_static_read_rid_demux_contract|read_mixed_dynamic_static_response_demux' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-mixed-dynamic-static-read-response-demux-contract-selection.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.275` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.276`, direct generated behavior for bounded
mixed dynamic/static read single-beat `RID` response-demux.

The selected public contract reuses existing `response-demux.read` syntax with
`response-scope single-beat` and generated transaction completion. The first
behavior owner is bounded to exactly one dynamic read transaction plus exactly
one concrete static read transaction, reserves the static concrete ID away from
dynamic `ARID` capture, and keeps mixed read requests onehot0.

The future support-accounted public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif`,
with report mode `bounded_mixed_dynamic_static_read_rid_demux_contract`.
