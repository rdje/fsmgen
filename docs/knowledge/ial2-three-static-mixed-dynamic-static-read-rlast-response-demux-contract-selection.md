---
id: ial2-three-static-mixed-dynamic-static-read-rlast-response-demux-contract-selection
title: Three-static mixed read RLAST contract selects direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.325 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.326?"
  - "what is the public contract for three-static mixed dynamic/static read burst-last response-demux?"
  - "which sample should cover one dynamic plus three static read RLAST demux behavior?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read, rlast, response-demux, contract]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.325|IAL2-FEATURE-COMPLETENESS-FRONTIER\.326|THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION|multi_static3_burst_last|bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract' docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.325` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.326`, direct generated behavior for
bounded one-dynamic plus three-concrete-static mixed dynamic/static read
burst-last `RID && RLAST` response-demux.

The selected public sample stem is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
```

The contract reuses `response-demux.read` with `response-scope burst-last`,
one-bit `last-signal`, and generated transaction completion. The report
should reuse `bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`
with completion source `generated_multi_mixed_dynamic_static_read_demux_last_beat`,
`dynamic_transactions = [r0]`, `static_transactions = [r1, r2, r3]`, static
ID reservations/exclusions for `4'd3`, `4'd5`, and `4'd7`, raw `RID`
active/unique assertions, and final `RID && RLAST` generated completions for
all four transactions.

`.325` changes no behavior. Direct implementation is selected for `.326`.
Read-data, burst-length/runtime validation, multi-beat output banks, broader
mixed cardinalities, same-cycle widening, queues/scoreboards, direct backend,
backend-language variants, and VHDL remain future owners.
