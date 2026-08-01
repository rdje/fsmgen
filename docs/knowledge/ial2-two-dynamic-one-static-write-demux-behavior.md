---
id: ial2-two-dynamic-one-static-write-demux-behavior
title: Two-dynamic/one-static mixed write response-demux behavior ships
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.341 ship?"
  - "is two-dynamic-plus-static mixed write response-demux generated?"
  - "which PPIF sample covers two-dynamic-plus-static mixed write response-demux?"
  - "how does two-dynamic-plus-static mixed write BID matching avoid ambiguity?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, write-response-demux, behavior]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.341|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR|axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic|bounded_multi_mixed_dynamic_static_write_bid_demux_contract|generated_multi_mixed_dynamic_static_demux|multi_mixed_dynamic_static_unique_write_ids|active_dynamic_ids_must_be_unique|axi0_w0_w1_write_dynamic_active_id_unique' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t
  docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.341` ships generated bounded
two-dynamic-plus-one-static mixed dynamic/static write `BID` response-demux
behavior.

The public sample is
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif`.
It uses explicit `response-demux.write` with dynamic write transactions
`w0`/`w1`, concrete static write transaction `w2` at ID `3`, shared
`AWID`/`BID` family signals, and generated completion pulses.

The generated contract records report mode
`bounded_multi_mixed_dynamic_static_write_bid_demux_contract` and completion
source `generated_multi_mixed_dynamic_static_demux`. It captures dynamic
`AWID` into `axi0_w0_dynamic_id_q` and `axi0_w1_dynamic_id_q`, tracks dynamic
busy state for both dynamic transactions plus static busy state for `w2`,
reserves static literal `4'd3` away from dynamic capture, and matches raw
`BID` responses against either active dynamic selected ID or the active
static concrete ID.

Ambiguity is prevented by onehot0 mixed write requests across all selected
transactions, request-time no-active-same-ID checks for both dynamic writes,
pairwise active dynamic selected-ID uniqueness, dynamic request/static-ID
exclusion, dynamic active/static-ID exclusion, response active-match,
pairwise response unique-match, and completion-active assertions.

The `.272` one-dynamic plus one-static, `.295` one-dynamic plus two-static,
and `.318` one-dynamic plus three-static mixed write report contracts remain
unchanged. Read response-demux, read-data, broader capped mixed sets,
same-cycle widening, queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL remain deferred to later exact owners.
