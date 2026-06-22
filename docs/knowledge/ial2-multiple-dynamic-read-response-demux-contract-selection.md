---
id: ial2-multiple-dynamic-read-response-demux-contract-selection
title: Multiple dynamic read demux contract selects single-beat implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.250 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.251?"
  - "what is the multiple dynamic read response-demux contract?"
  - "which dynamic read scope is selected first for multiple dynamic reads?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-response-demux, contract, selection]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.250|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.251|MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION|bounded_multi_dynamic_read_rid_demux_contract|multi_active_unique_dynamic_read_ids|onehot0_dynamic_read_request|axi_manager_capacity_status_dynamic_read_response_demux_multi' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.250` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.251`, direct generated behavior for
bounded multiple dynamic read single-beat response-demux.

The selected contract uses existing `response-demux.read` syntax with
`response-scope single-beat`, requires every read transaction in the selected
family to use `(id dynamic)`, keeps same-cycle dynamic read requests onehot0,
requires active dynamic read IDs to be pairwise unique, and reports
`bounded_multi_dynamic_read_rid_demux_contract` with ownership
`multi_active_unique_dynamic_read_ids`.

Burst-last/`RLAST` multiple dynamic read demux, dynamic read-data over
multiple dynamic reads, burst-length/runtime validation, multi-beat output
banks, mixed dynamic/static demux, same-cycle widening, release-and-recapture,
dynamic same-ID queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL remain deferred.
