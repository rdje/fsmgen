---
id: ial2-mixed-dynamic-static-read-rlast-response-demux-contract-selection
title: Mixed dynamic/static read RLAST response-demux contract selects direct behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.279 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.280?"
  - "what is the public contract for mixed dynamic/static read RLAST response-demux?"
  - "which PPIF sample will cover mixed dynamic/static read burst-last response-demux?"
  - "how should mixed dynamic/static read RLAST completion differ from raw beat matching?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, rlast, contract]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.279|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.280|MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last|bounded_mixed_dynamic_static_read_rid_rlast_demux_contract|generated_mixed_dynamic_static_read_demux_last_beat|matched_dynamic_or_static_concrete_id_and_last_signal' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.279` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.280`, direct generated behavior for
bounded mixed dynamic/static read burst-last `RID && RLAST` response-demux.

The selected future public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
```

The contract keeps exactly one dynamic read transaction plus one concrete
static read transaction, uses `response-demux.read response-scope burst-last`
with one-bit `last-signal`, reserves the static concrete ID away from dynamic
`ARID` capture, and keeps same-cycle mixed read requests onehot0.

Raw beat ownership assertions match active transactions by `RID` only, while
generated completions and releases pulse only on final matching
`RID && RLAST` beats for both the dynamic and static owners. Read-data,
burst-length/runtime validation, multi-beat output banks, multiple mixed
transactions, same-cycle widening, release-and-recapture, queues, scoreboards,
direct backend behavior, backend-language variants, and VHDL remain later
owners.
