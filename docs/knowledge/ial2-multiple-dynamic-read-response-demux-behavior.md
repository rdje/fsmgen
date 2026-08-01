---
id: ial2-multiple-dynamic-read-response-demux-behavior
title: Multiple dynamic read demux behavior ships
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.251 ship?"
  - "is bounded multiple dynamic read response-demux generated?"
  - "which PPIF sample covers multiple dynamic read response-demux?"
  - "what remains after multiple dynamic read response-demux shipped?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, read-response-demux, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.251|AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR|axi_manager_capacity_status_dynamic_read_response_demux_multi|bounded_multi_dynamic_read_rid_demux_contract|multi_active_unique_dynamic_read_ids|onehot0_dynamic_read_request|active_dynamic_ids_must_be_unique' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t t/248-regression-corpus-accounting.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md
  ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.251` ships generated bounded multiple
dynamic read single-beat response-demux behavior.

The public sample is
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif`.
It uses explicit `response-demux.read` with `response-scope single-beat`, two
all-dynamic read transactions, shared `ARID`/`RID` family signals, generated
completion pulses, per-transaction selected-ID/busy state, and schedule report
mode `bounded_multi_dynamic_read_rid_demux_contract`.

The generated contract keeps same-cycle dynamic read requests onehot0,
requires active dynamic IDs to be pairwise unique, and prevents ambiguous
`RID` responses through active-match, unique-match, request no-active-same-ID,
and active-ID-unique assertions rather than queues or scoreboards.

Multiple dynamic read burst-last/`RLAST` demux, read-data over multiple dynamic
read demux, burst-length/runtime validation and multi-beat output banks over
multiple dynamic read demux, mixed dynamic/static demux, same-cycle request
widening beyond onehot0, same-cycle release-and-recapture, dynamic same-ID
queues, scoreboards, direct backend behavior, backend-language variants, and
VHDL remain deferred.
