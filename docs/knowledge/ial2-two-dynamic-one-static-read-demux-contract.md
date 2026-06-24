---
id: ial2-two-dynamic-one-static-read-demux-contract
title: Two-dynamic/one-static mixed read demux contract selects implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.343 select?"
  - "what is the public contract for two-dynamic-plus-static mixed read demux?"
  - "which sample should cover two-dynamic-plus-static mixed read demux?"
  - "what assertion policy should two-dynamic-plus-static mixed read demux use?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, contract]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.343|IAL2-FEATURE-COMPLETENESS-FRONTIER\.344|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION|read_mixed_dynamic_static_response_demux_multi_dynamic|mixed_dynamic_static_read_demux_multi_dynamic|active_dynamic_ids_must_be_unique' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.343` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.344`, direct generated behavior for
bounded two-dynamic-plus-one-static mixed dynamic/static read single-beat
`RID` response-demux.

The selected public sample stem is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif`.
It should use existing `response-demux.read` syntax with `response-scope
single-beat`, generated transaction completions, dynamic read transactions
`r0`/`r1`, concrete static read transaction `r2`, and static ID `3`.

The selected report contract reuses
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`, with
cardinality carried by list-shaped `dynamic_transactions`,
`static_transactions`, `mixed_transactions`, and `static_id_reservations`.
The completion source is `generated_multi_mixed_dynamic_static_read_demux`.

The assertion policy combines onehot0 mixed read requests,
request-time no-active-same-ID checks for both dynamic reads, pairwise active
dynamic selected-ID uniqueness, dynamic request/static-ID exclusions,
dynamic active/static-ID exclusions, response active-match, pairwise response
unique-match, and completion-active assertions. Read burst-last, read-data,
broader mixed cardinalities, same-cycle widening, queues, scoreboards, direct
backend behavior, backend-language variants, and VHDL remain deferred.
