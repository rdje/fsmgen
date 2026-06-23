---
id: ial2-multiple-mixed-dynamic-static-read-rlast-response-demux-contract-selection
title: Multiple mixed dynamic/static read RLAST contract selects implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.302 decide?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.303?"
  - "what is the public contract for multiple mixed dynamic/static read burst-last response-demux?"
  - "what report mode should multiple mixed dynamic/static read RLAST demux use?"
date: 2026-06-23
status: historical
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, rlast, contract]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.302|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.303|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION|bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract|generated_multi_mixed_dynamic_static_read_demux_last_beat|multi_static_burst_last' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.302` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.303`, direct generated behavior for
bounded multiple mixed dynamic/static read burst-last `RID && RLAST`
response-demux.

The selected contract covers exactly one dynamic read transaction plus two
pairwise-distinct concrete static read transactions under existing
`response-demux.read` syntax with `response-scope burst-last`, one-bit
`last-signal`, and generated transaction completion.

The future public sample stem is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
```

The report mode is
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`, with
completion source `generated_multi_mixed_dynamic_static_read_demux_last_beat`,
list-shaped `mixed_transactions` and `static_id_reservations`, dynamic capture
exclusions for every selected static ID, onehot0 selected read requests, raw
`RID` active/unique assertions, and final `RID && RLAST` generated completion
pulses for `r0`, `r1`, and `r2`.

`.302` changed no behavior. Direct implementation later shipped in `.303`.
Read-data, burst-length/runtime validation, multi-beat output banks, broader
mixed cardinalities, same-cycle widening, queues/scoreboards, direct backend,
backend-language variants, and VHDL remain future owners.
