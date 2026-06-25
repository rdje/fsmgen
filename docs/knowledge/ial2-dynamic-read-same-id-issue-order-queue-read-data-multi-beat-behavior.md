---
id: ial2-dynamic-read-same-id-issue-order-queue-read-data-multi-beat-behavior
title: Dynamic read same-ID issue-order queue read-data multi-beat behavior
answers:
  - "does FSMGen support multi-beat output banks over dynamic read issue-order queue read-data?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.473 implement?"
  - "what sample covers dynamic read issue-order queue read-data multi-beat output banks?"
  - "what generated output-bank artifacts are emitted for dynamic queue read-data multi-beat?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, read-data, multi-beat, output-bank, burst-length, arlen, runtime-validation, behavior]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'dynamic_read_burst_last_same_id_issue_order_queue_read_data_multi_beat|generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse|bounded_multi_beat_read_data_contract|axi0_r0_beat_rdata_0|axi0_r1_beat_rdata_15|axi0_r0_beat_valid|axi0_r1_beat_valid|queue-backed runtime-assertion raw-ARLEN multi-beat output-bank' ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

FSMGen supports multi-beat read-data output banks over generated dynamic read
same-ID `issue-order-queue` runtime-validation read-data for exactly two
all-dynamic read transactions.

The public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif
```

The read-data report uses `bounded_multi_beat_read_data_contract`, completion
validity
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`,
`beat_match_source: response_demux_matched_read_beat`, runtime-assertion
`ARLEN` burst-length metadata, per-transaction valid masks, length outputs,
and worst-observed scalar status aggregates.

The generated artifacts include `axi0_r0_beat_rdata_0` through
`axi0_r1_beat_rdata_15`, `axi0_r0_beat_rresp_0` through
`axi0_r1_beat_rresp_15`, `axi0_r0_beat_valid`, `axi0_r1_beat_valid`,
`axi0_r0_read_beats`, `axi0_r1_read_beats`, `axi0_r0_rresp`,
`axi0_r1_rresp`, per-transaction output-init rules, per-lane capture rules,
scalar aggregate update rules, and the `.471` raw-`ARLEN`,
expected-beat/read-beat counter, and beat-count/`RLAST` assertion artifacts.

The `.467` scalar queue read-data, `.469` report-only raw-`ARLEN`, and `.471`
runtime-validation queue read-data samples remain supported. Queue recapture
widening, broader queues, mixed dynamic/static queues, scoreboards, direct
backend behavior, backend-language variants, and VHDL remain future owners.
