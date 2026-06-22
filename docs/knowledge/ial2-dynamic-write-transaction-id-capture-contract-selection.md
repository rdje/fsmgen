---
id: ial2-dynamic-write-transaction-id-capture-contract-selection
title: Dynamic write transaction-ID capture reuses response-demux.write and selects direct behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.222 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.223?"
  - "what is the public contract for dynamic write transaction ID capture?"
  - "does dynamic write ID capture need a new lifecycle clause?"
  - "how should dynamic write BID matching capture the request ID?"
date: 2026-06-22
status: current
tags: [ial2, axi, manager, dynamic-id, response-demux, task-tree]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CAPTURE_MATCHING_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.222|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.223|DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION|bounded_dynamic_write_bid_demux_contract|generated_capture_matching|response-demux.*write|single-active dynamic write' docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.222` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.223`, direct generated behavior for
bounded dynamic write transaction-ID capture and `BID` response matching.

The selected public contract reuses transaction-local `(id dynamic)` plus the
existing explicit `(response-demux (write ...))` opt-in. No new dynamic-ID
lifecycle clause is selected.

The first supported behavior is exactly one dynamic write transaction in the
selected write family. It captures the family write request-ID source at the
admitted request point, requires single-active ownership through generated
selected-ID and busy storage, matches raw accepted write responses with
`BID == captured_id`, generates the transaction completion pulse, and releases
busy from that completion.

Dynamic read matching, multiple dynamic write transactions, mixed
dynamic/static write response demux, same-cycle recapture, same-ID ordering,
read-data routing, queues, scoreboards, direct backend behavior, and VHDL
remain residue.
