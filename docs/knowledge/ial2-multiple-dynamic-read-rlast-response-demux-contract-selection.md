---
id: ial2-multiple-dynamic-read-rlast-response-demux-contract-selection
title: Multiple dynamic read RLAST demux contract selects implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.254 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.255?"
  - "what is the multiple dynamic read RLAST demux contract?"
  - "how should multiple dynamic read RLAST demux match raw beats?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, read-response-demux, rlast, contract-selection]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.254|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.255|MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION|bounded_multi_dynamic_read_rid_rlast_demux_contract|_response_demux_guard_expr|_response_demux_match_expr' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.254` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.255`, direct generated behavior for
bounded multiple dynamic read burst-last/`RLAST` response-demux.

The selected contract uses two or more all-dynamic read transactions,
`response-demux.read response-scope burst-last`, a one-bit `last-signal`,
admitted `ARID` capture, onehot0 same-cycle dynamic read requests, pairwise
unique active dynamic IDs, raw `RID` beat active/unique assertions without
`RLAST`, final `RID && RLAST` completion/release guards, and the new
`bounded_multi_dynamic_read_rid_rlast_demux_contract` report mode.

Read-data, burst-length/runtime validation, multi-beat output banks, mixed
dynamic/static demux, same-cycle widening, release-and-recapture, dynamic
same-ID queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL remain later exact owners.
