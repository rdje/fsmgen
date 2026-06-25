---
id: ial2-dynamic-read-same-id-issue-order-queue-read-data-runtime-validation-behavior
title: Dynamic read same-ID issue-order queue read-data runtime validation behavior
answers:
  - "does FSMGen support runtime beat-count validation over dynamic read issue-order queue read-data?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.471 implement?"
  - "what sample covers dynamic read issue-order queue read-data runtime assertion?"
  - "what generated beat-count artifacts are emitted for dynamic queue read-data runtime validation?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, read-data, burst-length, arlen, runtime-validation, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion|generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse|axi0_r0_expected_beats_q|axi0_r1_expected_beats_q|axi0_r0_read_beat_count_q|axi0_r1_read_beat_count_q|burst_length_validation.*runtime_assertion|queue-backed report-only/runtime-assertion raw-ARLEN' ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

FSMGen supports runtime beat-count/`RLAST` validation over generated dynamic
read same-ID `issue-order-queue` scalar last-beat read-data for exactly two
all-dynamic read transactions.

The public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif
```

The read-data report uses completion validity
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`,
`burst_length_validation: runtime_assertion`, and
`beat_count_match_source: response_demux_matched_read_beat`. Generated runtime
artifacts include `axi0_r0_expected_beats_q`, `axi0_r1_expected_beats_q`,
`axi0_r0_read_beat_count_q`, `axi0_r1_read_beat_count_q`,
`axi0_r0_beat_count_init`, `axi0_r1_beat_count_init`,
`axi0_r0_read_beat_count`, `axi0_r1_read_beat_count`, and four
beat-count/`RLAST` assertions per transaction.

The `.469` report-only raw-`ARLEN` sample remains supported. Multi-beat output
banks, broader queues, mixed dynamic/static queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL remain future owners.
