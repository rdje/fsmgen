---
id: ial2-multiple-mixed-dynamic-static-read-response-demux-contract-selection
title: IAL2 multiple mixed dynamic/static read demux contract selects implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.298 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.299?"
  - "what is the public contract for multiple mixed dynamic/static read demux?"
  - "which PPIF sample should cover multiple mixed dynamic/static read demux?"
  - "what remains residue after multiple mixed dynamic/static read contract selection?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, contract]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.298|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.299|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static|bounded_multi_mixed_dynamic_static_read_rid_demux_contract|generated_multi_mixed_dynamic_static_read_demux' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.298` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.299`, direct generated behavior for
bounded multiple mixed dynamic/static read single-beat `RID` response-demux.

The selected contract reuses existing `response-demux.read` syntax with
`response-scope single-beat`, one dynamic read transaction, and two
pairwise-distinct concrete static read transactions. The selected public
sample stem is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif`.

Reports should use
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`, completion
source `generated_multi_mixed_dynamic_static_read_demux`, single-beat
semantics `matched_dynamic_or_static_concrete_id_single_beat`, list-shaped
`mixed_transactions` and `static_id_reservations`, dynamic capture exclusions
for every selected static ID, onehot0 selected read requests, and pairwise
raw `RID` response unique-match assertions.

The `.276` one-dynamic plus one-static read report contract remains
unchanged. Burst-last `RID && RLAST`, read-data, burst-length/runtime
validation, multi-beat output banks, broader mixed cardinalities,
same-cycle widening, release-and-recapture, queues/scoreboards, backend
variants, and VHDL remain future exact owners.
