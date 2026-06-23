---
id: ial2-mixed-dynamic-static-read-rlast-response-demux-behavior
title: Mixed dynamic/static read RLAST response-demux behavior ships
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.280 ship?"
  - "is bounded mixed dynamic/static read RLAST response-demux generated?"
  - "which PPIF sample covers mixed dynamic/static read RLAST response-demux?"
  - "how does mixed dynamic/static read RID/RLAST matching avoid early release?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, rlast, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.280|AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last|bounded_mixed_dynamic_static_read_rid_rlast_demux_contract|generated_mixed_dynamic_static_read_demux_last_beat|raw_accepted_read_response_beat|axi0_rlast|matched_dynamic_or_static_concrete_id_and_last_signal' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.280` ships generated bounded mixed
dynamic/static read burst-last `RID && RLAST` response-demux behavior.

The public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif`.
It uses explicit `response-demux.read` with `response-scope burst-last`, one
one-bit `last-signal` named `axi0_rlast`, one dynamic read transaction `r0`,
one concrete static read transaction `r1` at ID `3`, shared `ARID`/`RID`
family signals, and generated completion pulses.

The generated contract records report mode
`bounded_mixed_dynamic_static_read_rid_rlast_demux_contract`, event role
`raw_accepted_read_response_beat`, and completion source
`generated_mixed_dynamic_static_read_demux_last_beat`. It captures dynamic
`ARID` into `axi0_r0_dynamic_id_q`, tracks dynamic and static busy state,
reserves static literal `4'd3` away from dynamic capture, and completes only
when the matched dynamic or static concrete `RID` response also has
`axi0_rlast` asserted.

Early release is avoided by keeping raw `RID` beat active/unique assertions
separate from final completion rules: non-final beats prove ownership, but only
final `RID && RLAST` beats pulse `axi0_r0_complete` or `axi0_r1_complete` and
release the corresponding busy state.

Mixed dynamic/static read-data, burst-length/runtime behavior, multi-beat
output banks, multiple mixed transactions, same-cycle widening,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL remain deferred to later exact
owners.
