---
id: ial2-two-dynamic-one-static-write-demux-contract
title: Two-dynamic one-static mixed write demux contract selects implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.340 select?"
  - "what is the public contract for two-dynamic-plus-static mixed write demux?"
  - "which sample should cover two-dynamic-plus-static mixed write demux?"
  - "what assertion policy should two-dynamic-plus-static mixed write demux use?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, response-demux, write, contract]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.340|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.341|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION|write_mixed_dynamic_static_response_demux_multi_dynamic|mixed_dynamic_static_write_demux_multi_dynamic|active_dynamic_ids_must_be_unique' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.340` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.341`, direct generated behavior for
bounded two-dynamic-plus-one-static mixed dynamic/static write `BID`
response-demux.

The selected public sample stem is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

The selected contract reuses
`bounded_multi_mixed_dynamic_static_write_bid_demux_contract` and requires
`w0`/`w1` dynamic write transactions plus static `w2` ID `3`. It keeps
`onehot0_mixed_write_request`, static-ID reservation/exclusion for `4'd3`,
dynamic-vs-static request/active exclusion assertions, dynamic-vs-dynamic
request no-active-same-ID assertions, pairwise active dynamic selected-ID
uniqueness, response active-match, and pairwise response unique-match across
all three transactions.
