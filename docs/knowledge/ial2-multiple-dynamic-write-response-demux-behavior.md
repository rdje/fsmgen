---
id: ial2-multiple-dynamic-write-response-demux-behavior
title: Multiple dynamic write demux behavior ships
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.247 ship?"
  - "is bounded multiple dynamic write response-demux generated?"
  - "which PPIF sample covers multiple dynamic write response-demux?"
  - "what remains after multiple dynamic write response-demux shipped?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, write-response-demux, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.247|AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR|axi_manager_capacity_status_dynamic_write_response_demux_multi|bounded_multi_dynamic_write_bid_demux_contract|multi_active_unique_dynamic_write_ids|onehot0_dynamic_write_request|active_dynamic_ids_must_be_unique' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.247` ships generated bounded multiple
dynamic write response-demux behavior.

The public sample is
`ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif`.
It uses explicit `response-demux.write` with two all-dynamic write
transactions, shared `AWID`/`BID` family signals, generated completion pulses,
per-transaction selected-ID/busy state, and schedule report mode
`bounded_multi_dynamic_write_bid_demux_contract`.

The generated contract keeps same-cycle dynamic write requests onehot0, requires
active dynamic IDs to be pairwise unique, and prevents ambiguous `BID`
responses through active-match, unique-match, request no-active-same-ID, and
active-ID-unique assertions rather than queues or scoreboards.

Multiple dynamic read single-beat response-demux now ships under `.251`.
Multiple dynamic read burst-last/`RLAST`, read-data, burst-length/runtime
validation, and multi-beat output-bank widening remain deferred along with
mixed dynamic/static demux, same-cycle request widening beyond onehot0,
same-cycle release-and-recapture, dynamic same-ID queues, scoreboards, direct
backend behavior, backend-language variants, and VHDL.
