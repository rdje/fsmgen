---
id: ial2-dynamic-read-rlast-transaction-id-capture-contract-selection
title: Dynamic read RLAST contract selects direct generated behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.230 select?"
  - "what is the dynamic read RLAST public contract?"
  - "what comes after dynamic read RLAST contract selection?"
  - "does dynamic read RLAST reuse response-demux.read?"
  - "what is the next IAL2 slice after dynamic read RLAST contract selection?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-response-demux, rlast, contract-selection]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/knowledge/ial2-dynamic-read-rlast-transaction-id-capture-readiness-audit.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.230|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.231|DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION|bounded_dynamic_read_rid_rlast_demux_contract|matched_dynamic_id_and_last_signal' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.230` selects `.231`, direct generated
behavior for bounded dynamic read burst-last/`RLAST` transaction-ID capture and
response matching.

The public contract reuses existing `response-demux.read` with exactly one
transaction-local dynamic read ID, `response-scope burst-last`, one-bit
`last-signal`, admitted `ARID` capture, single-active selected-ID/busy state
across non-last beats, and generated completion only on raw accepted read
response beat plus `RID == captured_id` plus asserted `RLAST`.

The selected report vocabulary is
`bounded_dynamic_read_rid_rlast_demux_contract` with
`transaction_completion_semantics: matched_dynamic_id_and_last_signal`. The
selector keeps read-data routing, burst-length/runtime validation, multi-beat
output banks, multiple/mixed dynamic demux, same-cycle recapture, same-ID
ordering, queues, scoreboards, direct backend behavior, and VHDL as residue.
