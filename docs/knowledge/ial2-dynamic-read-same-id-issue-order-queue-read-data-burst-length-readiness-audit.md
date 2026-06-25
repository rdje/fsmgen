---
id: ial2-dynamic-read-same-id-issue-order-queue-read-data-burst-length-readiness-audit
title: Dynamic read same-ID issue-order queue read-data raw-ARLEN audit selects implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.468 select?"
  - "is raw ARLEN burst-length ready for dynamic read issue-order queue read-data?"
  - "what sample should cover dynamic read issue-order queue read-data burst-length?"
  - "does dynamic read issue-order queue read-data need a new burst-length public contract?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, read-data, burst-length, arlen, readiness]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.468|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.469|DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT|dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length|generated_dynamic_issue_order_queue_demux_last_beat|burst_length_generated_behavior|arlen_signal' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.468` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.469`, direct bounded implementation of
report-only raw-`ARLEN` burst-length capture over generated dynamic read
same-ID `issue-order-queue` last-beat read-data.

No new public contract-selection leaf is required because existing
`read-data.read` `burst-length` syntax already defines source `arlen`,
width-8 signal, `axlen-plus-one`, request capture, `max-beats`, and
`report-only` validation. The current blocker is only the local generated
dynamic issue-order queue read-data coverage gate, which rejects
`burst-length` metadata today.

The selected public sample is
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length.ppif`.
`.469` should keep runtime validation, multi-beat output banks, queue
recapture widening, broader queues, mixed dynamic/static queues, scoreboards,
direct backend behavior, backend-language variants, and VHDL as future exact
owners.
