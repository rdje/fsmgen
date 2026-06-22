---
id: ial2-dynamic-read-transaction-id-capture-matching-readiness-audit
title: Dynamic read ID readiness selects single-beat contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.225 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.226?"
  - "what follows dynamic read ID readiness?"
  - "is dynamic read RID matching ready for direct implementation?"
  - "what is the first selected dynamic read response scope?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-response-demux, readiness, task-tree]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/knowledge/ial2-dynamic-read-transaction-id-capture-contract-selection.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.225|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.226|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.227|DYNAMIC_READ_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT|DYNAMIC_READ_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION|bounded single-beat dynamic read|response-scope single-beat|bounded_dynamic_read_rid_demux_contract' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.225` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.226`, public contract selection for
bounded single-beat dynamic read transaction-ID capture and `RID` response
matching.

The follow-on selector `.226` selected `.227`, direct generated behavior for
that bounded single-beat dynamic read contract.

The audit does not implement parser, generator, PPIF sample, support
accounting, generated artifact, test, validation, or HDL behavior.

The first selected read scope is `response-scope single-beat`. Dynamic
read `RLAST`, burst/runtime validation, read-data routing, interleaving,
multiple dynamic reads, mixed dynamic/static read demux, queues, scoreboards,
direct backend behavior, and VHDL remain future exact-owner work.
