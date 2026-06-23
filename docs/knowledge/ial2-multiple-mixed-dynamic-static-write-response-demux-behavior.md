---
id: ial2-multiple-mixed-dynamic-static-write-response-demux-behavior
title: Multiple mixed dynamic/static write response-demux behavior ships
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.295 ship?"
  - "is bounded multiple mixed dynamic/static write response-demux generated?"
  - "which PPIF sample covers multiple mixed dynamic/static write response-demux?"
  - "how does multiple mixed dynamic/static write BID matching avoid ambiguity?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, write-response-demux, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.295|AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR|axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static|bounded_multi_mixed_dynamic_static_write_bid_demux_contract|generated_multi_mixed_dynamic_static_demux|multi_mixed_dynamic_static_unique_write_ids|static_id_reservations|axi0_w0_w2_write_dynamic_request_not_static_id' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.295` ships generated bounded multiple
mixed dynamic/static write `BID` response-demux behavior.

The public sample is
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif`.
It uses explicit `response-demux.write` with one dynamic write transaction
`w0`, two concrete static write transactions `w1`/`w2` at IDs `3` and `5`,
shared `AWID`/`BID` family signals, and generated completion pulses.

The generated contract records report mode
`bounded_multi_mixed_dynamic_static_write_bid_demux_contract` and completion
source `generated_multi_mixed_dynamic_static_demux`. It captures dynamic
`AWID` into `axi0_w0_dynamic_id_q`, tracks dynamic and per-static busy state,
reserves static literals `4'd3` and `4'd5` away from dynamic capture, and
matches raw `BID` responses against either the active dynamic ID or one active
static concrete ID.

Ambiguity is prevented by pairwise-distinct static concrete IDs, onehot0 mixed
write requests across all selected transactions, dynamic request/static-ID
exclusion for every static ID, active dynamic/static-ID exclusion for every
static ID, response active-match, pairwise response unique-match, and
dynamic/static completion-active assertions.

The `.272` one-dynamic plus one-static mixed write report contract remains
unchanged. Two-dynamic plus one-static mixed writes, broader mixed
cardinalities, multiple mixed read demux, same-cycle widening,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL remain deferred to later exact
owners.
