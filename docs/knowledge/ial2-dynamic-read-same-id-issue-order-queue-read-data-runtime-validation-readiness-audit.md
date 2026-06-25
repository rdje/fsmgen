---
id: ial2-dynamic-read-same-id-issue-order-queue-read-data-runtime-validation-readiness-audit
title: Dynamic read same-ID issue-order queue read-data runtime validation audit selects implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.470 select?"
  - "is runtime beat-count validation ready for dynamic read issue-order queue read-data?"
  - "what sample should cover dynamic read issue-order queue read-data runtime validation?"
  - "does dynamic read issue-order queue runtime validation need a new public contract?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, read-data, burst-length, arlen, rlast, beat-count, runtime-assertion, readiness]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.470|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.471|DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT|dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion|generated_dynamic_issue_order_queue_demux_last_beat|runtime_assertion|response_demux_matched_read_beat' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.470` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.471`, direct bounded implementation of
runtime beat-count/`RLAST` validation over generated dynamic read same-ID
`issue-order-queue` scalar last-beat read-data with raw-`ARLEN` capture.

No new public contract-selection leaf is required because existing
`read-data.read` `burst-length` syntax already accepts
`validation runtime-assertion`. The current blocker is only the local
generated dynamic issue-order queue read-data coverage gate, which admits the
`.469` queue raw-`ARLEN` shape only for `report_only` validation.

The selected public sample is
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif`.
`.471` should keep multi-beat output banks, queue recapture widening,
broader queues, mixed dynamic/static queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL as future exact owners.
