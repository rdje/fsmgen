---
id: ial2-dynamic-read-same-id-issue-order-queue-read-data-burst-length-behavior
title: Dynamic read same-ID issue-order queue read-data raw-ARLEN behavior
answers:
  - "does FSMGen support raw ARLEN over dynamic read issue-order queue read-data?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.469 implement?"
  - "what sample covers dynamic read issue-order queue read-data burst-length?"
  - "what completion validity is used for dynamic queue read-data raw ARLEN?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, read-data, burst-length, arlen, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length|generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse|axi0_r0_burst_length_capture|axi0_r1_burst_length_capture|burst_length_validation.*report_only|queue-backed report-only raw-ARLEN' ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

FSMGen supports report-only raw-`ARLEN` burst-length capture over generated
dynamic read same-ID `issue-order-queue` scalar last-beat read-data for
exactly two all-dynamic read transactions.

The public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length.ppif
```

The read-data report uses completion validity
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`,
`burst_length_source: arlen_signal`, and
`burst_length_validation: report_only`. Generated artifacts include
`axi0_arlen`, `axi0_r0_arlen_q`, `axi0_r1_arlen_q`,
`axi0_r0_burst_length_capture`, and `axi0_r1_burst_length_capture`.

Runtime beat-count/`RLAST` validation, multi-beat output banks, broader
queues, mixed dynamic/static queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL remain future owners.
