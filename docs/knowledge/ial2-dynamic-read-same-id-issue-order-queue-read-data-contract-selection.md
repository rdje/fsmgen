---
id: ial2-dynamic-read-same-id-issue-order-queue-read-data-contract-selection
title: Dynamic read same-ID issue-order queue read-data contract selects implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.466 select?"
  - "what is the public contract for dynamic read issue-order queue read-data?"
  - "which samples should cover dynamic read issue-order queue read-data?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.467 implement?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, read-data, contract]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.466|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.467|DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_CONTRACT_SELECTION|dynamic_read_same_id_issue_order_queue_read_data|dynamic_read_burst_last_same_id_issue_order_queue_read_data|generated_dynamic_read_issue_order_queue_response_demux_completion_pulse|generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.466` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.467`, direct implementation of paired
bounded scalar read-data routing over generated dynamic read same-ID
`issue-order-queue` completions.

The contract reuses existing `read-data.read` syntax for two new public
samples:

```text
ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data.ppif
ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data.ppif
```

The selected read-data completion-validity names are
`generated_dynamic_read_issue_order_queue_response_demux_completion_pulse` and
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`.
The implementation must keep the underlying dynamic issue-order queue
response-demux modes/sources, generate only scalar `RDATA`/`RRESP` capture for
the two all-dynamic read transactions, and leave raw `ARLEN`, runtime
validation, multi-beat output banks, queue recapture widening, broader queue
cardinality, mixed dynamic/static queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL to future exact owners.
