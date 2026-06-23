---
id: ial2-multiple-dynamic-read-data-contract-selection
title: IAL2 multiple dynamic read-data contract selects direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.258 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.259?"
  - "what is the multiple dynamic read-data contract?"
  - "what PPIF samples should cover multiple dynamic read-data?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, read-data, contract]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.258|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.259|MULTIPLE_DYNAMIC_READ_DATA_CONTRACT_SELECTION|axi_manager_capacity_status_dynamic_read_data_multi|axi_manager_capacity_status_dynamic_read_data_multi_last_beat|bounded scalar read-data over generated multiple dynamic read response-demux' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.258` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.259`, direct generated behavior for
bounded scalar read-data over generated multiple dynamic read response-demux.

The selected contract covers two public samples:

```text
ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif
ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif
```

The first sample composes `.251` generated multiple dynamic read single-beat
response-demux with scalar `capture-scope single-beat` read-data. The second
sample composes `.255` generated multiple dynamic read burst-last/`RLAST`
response-demux with scalar `capture-scope last-beat` read-data.

The read-data bindings must exactly cover all generated dynamic read demux
transactions, map each transaction to the matching generated completion pulse,
and reuse the existing scalar read-data report modes. Burst-length/runtime
validation and multi-beat output banks over multiple dynamic read demux remain
future exact owners.
