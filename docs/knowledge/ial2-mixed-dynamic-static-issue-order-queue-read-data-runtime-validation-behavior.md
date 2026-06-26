---
id: ial2-mixed-dynamic-static-issue-order-queue-read-data-runtime-validation-behavior
title: Mixed dynamic/static issue-order queue read-data runtime-validation behavior
answers:
  - "does FSMGen support runtime validation over mixed dynamic static issue-order queue read-data?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.518 implement?"
  - "what sample covers mixed dynamic static issue-order queue read-data runtime validation?"
  - "what completion validity is used for mixed queue read-data runtime validation?"
date: 2026-06-26
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, same-id-ordering, issue-order-queue, read-data, burst-length, arlen, runtime-validation, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion|generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse|axi0_r0_expected_beats_q|axi0_r1_expected_beats_q|runtime beat-count/RLAST validation over the generated mixed read burst-last queue completion' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm perl/FSM/Support/LanguageSurfaceSection.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t docs/REGRESSION_CORPUS.md README.md ROADMAP_V2.md docs/book/src/11-extensions-and-embedding.md docs/book/src/14-feature-backlog.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
---

FSMGen supports runtime beat-count/`RLAST` validation over generated mixed
dynamic/static read burst-last same-ID `issue-order-queue` scalar last-beat
read-data for exactly one dynamic read transaction plus one concrete static read
transaction in one depth-2 generated mixed queue.

The public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif
```

The read-data report uses completion validity
`generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse`,
`burst_length_source: arlen_signal`, `burst_length_validation:
runtime_assertion`, and generated beat-count validation behavior. Generated
artifacts include `axi0_r0_expected_beats_q`, `axi0_r1_expected_beats_q`,
`axi0_r0_read_beat_count_q`, `axi0_r1_read_beat_count_q`, and eight
beat-count/`RLAST` assertions across `r0` and `r1`.

Multi-beat output banks over this mixed queue, broader mixed queues,
scoreboards, direct backend behavior, backend-language variants,
verification-output generation, and VHDL remain future owners.
