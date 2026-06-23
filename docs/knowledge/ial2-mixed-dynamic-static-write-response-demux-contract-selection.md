---
id: ial2-mixed-dynamic-static-write-response-demux-contract-selection
title: IAL2 mixed dynamic/static write demux contract selects implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.271 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.272?"
  - "what is the public contract for mixed dynamic/static write response-demux?"
  - "which sample was selected for mixed dynamic/static write response-demux?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, response-demux, write, contract]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.271|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.272|MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION|bounded_mixed_dynamic_static_write_bid_demux_contract|write_mixed_dynamic_static_response_demux' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md docs/knowledge/ial2-mixed-dynamic-static-write-response-demux-contract-selection.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.271` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.272`, direct generated behavior for
bounded mixed dynamic/static write `BID` response-demux.

The selected public contract reuses existing `response-demux.write` syntax
with generated transaction completion and exactly two selected write
transactions: one `(id dynamic)` transaction and one concrete `(id (value N))`
static transaction. The static concrete ID is reserved away from dynamic
capture so one raw `BID` cannot legally match both dynamic and static owners.

The selected sample is
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif`
with support-accounting entry
`intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_response_demux`.
The selector changes no parser, generator, sample, support accounting,
validation behavior, generated artifacts, tests, JSON, or HDL behavior.
