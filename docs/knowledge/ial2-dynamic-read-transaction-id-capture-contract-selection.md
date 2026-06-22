---
id: ial2-dynamic-read-transaction-id-capture-contract-selection
title: Dynamic read ID contract selects direct single-beat behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.226 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.227?"
  - "what is the dynamic read ID capture contract?"
  - "how should response-demux.read handle dynamic read IDs?"
  - "what report mode should dynamic read RID demux use?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-response-demux, contract, task-tree]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.226|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.227|DYNAMIC_READ_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION|bounded_dynamic_read_rid_demux_contract|admitted_dynamic_read_request|matched_dynamic_id_single_beat' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.226` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.227`, direct generated behavior for
bounded single-beat dynamic read transaction-ID capture and `RID` response
matching.

The selected public contract reuses existing `response-demux.read` with
`response-scope single-beat`, one transaction-local `(id dynamic)` read
transaction, admitted-request capture of the read request-ID source such as
`ARID`, single-active selected-ID/busy storage, and a raw accepted read
response event plus `RID == captured_id` completion rule.

The expected report mode is `bounded_dynamic_read_rid_demux_contract`, with
`capture_event_source: admitted_dynamic_read_request` and
`transaction_completion_semantics: matched_dynamic_id_single_beat`.

Dynamic read `burst-last`/`RLAST`, read-data routing,
burst-length/runtime-validation behavior, multiple dynamic reads,
mixed dynamic/static read demux, same-cycle recapture, same-ID ordering,
queues, scoreboards, direct backend behavior, and VHDL remain future
exact-owner work.
