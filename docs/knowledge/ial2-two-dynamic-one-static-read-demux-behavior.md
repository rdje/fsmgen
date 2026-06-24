---
id: ial2-two-dynamic-one-static-read-demux-behavior
title: Two-dynamic/one-static mixed read single-beat response-demux behavior ships
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.344 ship?"
  - "is two-dynamic-plus-static mixed read response-demux generated?"
  - "which PPIF sample covers two-dynamic-plus-static mixed read response-demux?"
  - "how does two-dynamic-plus-static mixed read RID matching avoid ambiguity?"
  - "what is the bounded two-dynamic-plus-one-static mixed read RID demux contract?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, behavior]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.344|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic|bounded_multi_mixed_dynamic_static_read_rid_demux_contract|generated_multi_mixed_dynamic_static_read_demux|multi_mixed_dynamic_static_unique_read_ids|active_dynamic_ids_must_be_unique|axi0_r0_r1_read_dynamic_active_id_unique' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.344` ships generated bounded
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
response-demux behavior.

The public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif`.
It uses explicit `response-demux.read` with `response-scope single-beat`,
dynamic read transactions `r0`/`r1`, concrete static read transaction `r2`
at ID `3`, shared `ARID`/`RID` family signals, and generated completion
pulses.

The generated contract records report mode
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract` and completion
source `generated_multi_mixed_dynamic_static_read_demux`. It captures dynamic
`ARID` into `axi0_r0_dynamic_id_q` and `axi0_r1_dynamic_id_q`, tracks dynamic
busy state for both dynamic transactions plus static busy state for `r2`,
reserves static literal `4'd3` away from dynamic capture, and matches raw
single-beat `RID` responses against either active dynamic selected ID or the
active static concrete ID.

Ambiguity is prevented by onehot0 mixed read requests across all selected
transactions, request-time no-active-same-ID checks for both dynamic reads,
pairwise active dynamic selected-ID uniqueness, dynamic request/static-ID
exclusion, dynamic active/static-ID exclusion, response active-match,
pairwise response unique-match, and completion-active assertions.

The `.276` one-dynamic plus one-static, `.299` one-dynamic plus two-static,
and `.322` one-dynamic plus three-static mixed read single-beat report
contracts remain unchanged. Read burst-last response-demux, read-data,
burst-length/runtime validation, multi-beat output banks, broader capped
mixed sets, same-cycle widening, queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL remain deferred to later exact
owners.
