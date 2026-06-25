---
id: ial2-dynamic-read-same-id-issue-order-queue-read-data-behavior
title: Dynamic read same-ID issue-order queue read-data behavior
answers:
  - "does FSMGen support read-data over generated dynamic read issue-order queues?"
  - "what samples cover dynamic read same-ID issue-order queue read-data?"
  - "what completion validity names are used for dynamic read issue-order queue read-data?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.467 implement?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, read-data, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data.ppif; ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'dynamic_read_same_id_issue_order_queue_read_data|dynamic_read_burst_last_same_id_issue_order_queue_read_data|generated_dynamic_read_issue_order_queue_response_demux_completion_pulse|generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse|dynamic issue-order queue read_data' ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

FSMGen supports paired scalar read-data routing over generated dynamic read
same-ID `issue-order-queue` completions for exactly two all-dynamic read
transactions.

The public samples are:

```text
ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data.ppif
ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data.ppif
```

The single-beat queue path uses completion validity
`generated_dynamic_read_issue_order_queue_response_demux_completion_pulse`.
The last-beat queue path uses completion validity
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`.
Both shapes keep the response-demux queue-owned and generate only scalar
`RDATA`/`RRESP` capture. Raw `ARLEN`, runtime validation, multi-beat output
banks, broader queues, mixed dynamic/static queues, scoreboards, direct
backend behavior, backend-language variants, and VHDL remain future owners.
