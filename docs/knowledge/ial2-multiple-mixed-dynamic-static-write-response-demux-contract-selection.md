---
id: ial2-multiple-mixed-dynamic-static-write-response-demux-contract-selection
title: IAL2 multiple mixed dynamic/static write demux contract selects implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.294 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.295?"
  - "what is the public contract for multiple mixed dynamic/static write demux?"
  - "which PPIF sample should cover multiple mixed dynamic/static write demux?"
  - "what remains residue after multiple mixed dynamic/static write demux contract selection?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, response-demux, contract-selection]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.294|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.295|MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION|write_mixed_dynamic_static_response_demux_multi_static|bounded_multi_mixed_dynamic_static_write_bid_demux_contract' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.294` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.295`, direct generated behavior for
bounded multiple mixed dynamic/static write `BID` response-demux.

The selected public contract reuses existing `response-demux.write` syntax
with generated transaction completion and exactly one dynamic write
transaction plus exactly two concrete static write transactions.

The future public sample is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif
```

The report mode should be
`bounded_multi_mixed_dynamic_static_write_bid_demux_contract`, with
transaction completion source `generated_multi_mixed_dynamic_static_demux`,
`dynamic_transactions = [w0]`, `static_transactions = [w1, w2]`,
list-shaped `mixed_transactions`, list-shaped `static_id_reservations`,
dynamic capture exclusions for every selected static concrete ID, onehot0
same-cycle request policy across all selected mixed write transactions, and
pairwise raw-response unique-match assertions.

The existing one-dynamic plus one-static `.272` report contract remains
unchanged. Two-dynamic plus one-static mixed write cardinality, broader mixed
write cardinalities, read `RID`/`RLAST` demux, read-data, burst-length/runtime
validation, multi-beat output banks, same-cycle widening,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL remain later exact owners.
