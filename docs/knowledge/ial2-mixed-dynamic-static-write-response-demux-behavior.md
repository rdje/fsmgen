---
id: ial2-mixed-dynamic-static-write-response-demux-behavior
title: Mixed dynamic/static write response-demux behavior ships
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.272 ship?"
  - "is bounded mixed dynamic/static write response-demux generated?"
  - "which PPIF sample covers mixed dynamic/static write response-demux?"
  - "how does mixed dynamic/static write BID matching avoid ambiguity?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, write-response-demux, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.272|AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR|axi_manager_capacity_status_write_mixed_dynamic_static_response_demux|bounded_mixed_dynamic_static_write_bid_demux_contract|generated_mixed_dynamic_static_demux|mixed_dynamic_static_unique_write_ids|static_id_reservation|axi0_write_mixed_dynamic_static_request_onehot0' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.272` ships generated bounded mixed
dynamic/static write `BID` response-demux behavior.

The public sample is
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif`.
It uses explicit `response-demux.write` with one dynamic write transaction
`w0`, one concrete static write transaction `w1` at ID `3`, shared `AWID`/`BID`
family signals, and generated completion pulses.

The generated contract records report mode
`bounded_mixed_dynamic_static_write_bid_demux_contract` and completion source
`generated_mixed_dynamic_static_demux`. It captures dynamic `AWID` into
`axi0_w0_dynamic_id_q`, tracks dynamic and static busy state, reserves static
literal `4'd3` away from dynamic capture, and matches raw `BID` responses
against either the active dynamic ID or the active static concrete ID.

Ambiguity is prevented by onehot0 mixed write requests, dynamic request/static
ID exclusion, active dynamic/static ID exclusion, response active-match,
response unique-match, and dynamic/static completion-active assertions.

Mixed dynamic/static read demux, multiple mixed write transactions, same-cycle
widening beyond onehot0, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain deferred to later exact owners.
