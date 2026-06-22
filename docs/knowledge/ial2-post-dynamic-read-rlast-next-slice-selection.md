---
id: ial2-post-dynamic-read-rlast-next-slice-selection
title: Post dynamic read RLAST selector chooses dynamic read-data audit
answers:
  - "what comes after dynamic read RLAST demux?"
  - "what is the next IAL2 slice after dynamic read RID RLAST matching?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.232 select?"
  - "why is dynamic read-data routing an audit next?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-data, read-response-demux, rlast, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RLAST_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/11-extensions-and-embedding.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Adapter/IAL2/PPIF.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.232|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.233|POST_DYNAMIC_READ_RLAST_NEXT_SLICE_SELECTION|dynamic read-data routing|read_data\\.read cannot be combined with dynamic read transaction ID metadata|bounded_dynamic_read_rid_rlast_demux_contract' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RLAST_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/11-extensions-and-embedding.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.232` selects `.233`, readiness audit for
dynamic read-data routing over generated single-active dynamic read
response-demux.

The selector keeps behavior unchanged. `.227` shipped single-beat dynamic read
`RID` matching, and `.231` shipped burst-last dynamic read `RID && RLAST`
matching. Those generated paths provide admitted `ARID` capture,
selected-ID/busy state, generated completion pulses, and release semantics for
one explicit dynamic read transaction.

Current read-data behavior still fails closed for dynamic read IDs. The audit
must decide whether the next behavior owner can route read-data for the
single-beat dynamic read shape, the burst-last dynamic read shape, or both; or
whether a public contract/report selection or lower cleanup prerequisite must
run first.

`.233` must record generated completion consumption, selected-ID/busy
interactions, data/status capture, diagnostics, report keys, sample and
support-accounting boundaries, validation gates, rollback, docs, Knowledge Map
impact, and explicit residue before parser, generator, PPIF sample,
support-accounting, generated artifact, test, validation, or HDL behavior
changes.

Burst-length capture, runtime validation, multi-beat output banks, multiple
dynamic read/write transactions, mixed dynamic/static demux, same-cycle
recapture, dynamic same-ID ordering, queues, scoreboards, direct backend
behavior, and VHDL remain deferred until exact owners select them.
