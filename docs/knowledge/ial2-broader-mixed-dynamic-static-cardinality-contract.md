---
id: ial2-broader-mixed-dynamic-static-cardinality-contract
title: Broader mixed cardinality starts with one dynamic plus three static writes
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.317 select?"
  - "what is the first broader mixed dynamic/static cardinality shape?"
  - "which sample should cover one dynamic plus three static write demux?"
  - "what comes after the broader mixed dynamic/static cardinality contract selection?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, write, response-demux, contract]
evidence: docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_CARDINALITY_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_CARDINALITY_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.317|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.318|BROADER_MIXED_DYNAMIC_STATIC_CARDINALITY_CONTRACT_SELECTION|write_mixed_dynamic_static_response_demux_multi_static3|one-dynamic plus three-concrete-static' docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_CARDINALITY_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.317` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.318`, direct generated behavior for a
bounded one-dynamic plus three-concrete-static write `BID` response-demux.

The selected future public sample stem is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif
```

The contract reuses the existing
`bounded_multi_mixed_dynamic_static_write_bid_demux_contract` report mode and
uses list fields to expose the three static transactions. Read-side,
read-data, two-dynamic-plus-static, general capped mixed sets, same-cycle,
queue, scoreboard, backend, and VHDL work remain later exact owners.
