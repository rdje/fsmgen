---
id: ial2-mixed-dynamic-static-read-response-demux-behavior
title: Mixed dynamic/static read response-demux behavior ships
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.276 ship?"
  - "is bounded mixed dynamic/static read response-demux generated?"
  - "which PPIF sample covers mixed dynamic/static read response-demux?"
  - "how does mixed dynamic/static read RID matching avoid ambiguity?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.276|AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux|bounded_mixed_dynamic_static_read_rid_demux_contract|generated_mixed_dynamic_static_read_demux|mixed_dynamic_static_unique_read_ids|static_id_reservation|axi0_read_mixed_dynamic_static_request_onehot0' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.276` ships generated bounded mixed
dynamic/static read single-beat `RID` response-demux behavior.

The public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif`.
It uses explicit `response-demux.read` with `response-scope single-beat`, one
dynamic read transaction `r0`, one concrete static read transaction `r1` at ID
`3`, shared `ARID`/`RID` family signals, and generated completion pulses.

The generated contract records report mode
`bounded_mixed_dynamic_static_read_rid_demux_contract` and completion source
`generated_mixed_dynamic_static_read_demux`. It captures dynamic `ARID` into
`axi0_r0_dynamic_id_q`, tracks dynamic and static busy state, reserves static
literal `4'd3` away from dynamic capture, and matches raw `RID` responses
against either the active dynamic ID or the active static concrete ID.

Ambiguity is prevented by onehot0 mixed read requests, dynamic request/static
ID exclusion, active dynamic/static ID exclusion, response active-match,
response unique-match, and dynamic/static completion-active assertions.

Mixed dynamic/static read burst-last `RID && RLAST`, read-data over mixed read
demux, burst-length/runtime behavior, multi-beat output banks, multiple mixed
transactions, same-cycle widening, release-and-recapture, dynamic same-ID
queues, scoreboards, direct backend behavior, backend-language variants, and
VHDL remain deferred to later exact owners.
