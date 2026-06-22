---
id: ial2-multiple-dynamic-write-response-demux-contract-selection
title: Multiple dynamic write demux contract selects direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.246 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.247?"
  - "what is the multiple dynamic write response-demux contract?"
  - "how are ambiguous dynamic write BID responses prevented?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, write-response-demux, contract, selection]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.246|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.247|MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION|bounded_multi_dynamic_write_bid_demux_contract|multi_active_unique_dynamic_write_ids|onehot0_dynamic_write_request|active_dynamic_ids_must_be_unique' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.246` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.247`, direct generated behavior for
bounded multiple dynamic write response-demux.

The public contract reuses existing `response-demux.write` syntax with two or
more write transactions using `(id dynamic)`. The first implementation shape
requires every selected write-family transaction to be dynamic, keeps
same-cycle dynamic write requests mutually exclusive, and requires all active
captured dynamic write IDs to be pairwise unique.

Ambiguous `BID` responses are prevented by contract assertions rather than
queues: raw write responses must match at least one and at most one active
captured dynamic write, active dynamic IDs must be unique, and new dynamic
write requests must not reuse an ID held by an active sibling transaction.

Multiple dynamic read demux, mixed dynamic/static demux, same-cycle request
widening, same-cycle release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain deferred.
