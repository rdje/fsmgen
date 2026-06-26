---
id: ial2-mixed-dynamic-static-issue-order-queue-read-data-behavior
title: Mixed dynamic/static issue-order queue read-data behavior
answers:
  - "does FSMGen support read-data over generated mixed dynamic/static read issue-order queues?"
  - "what samples cover mixed dynamic/static same-ID issue-order queue read-data?"
  - "what completion validity names are used for mixed dynamic/static issue-order queue read-data?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.514 implement?"
date: 2026-06-26
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, same-id-ordering, issue-order-queue, read-data, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_same_id_issue_order_queue_read_data.ppif; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/11-extensions-and-embedding.md
reverify: rg -n 'read_mixed_dynamic_static_same_id_issue_order_queue_read_data|read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data|generated_mixed_dynamic_static_read_issue_order_queue_response_demux_completion_pulse|generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse|mixed dynamic/static issue-order queue read_data|MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR|paired scalar read-data over the generated mixed read single-beat and burst-last queue completions' ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm perl/FSM/Support/LanguageSurfaceSection.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/297-capability-manifest.t docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/11-extensions-and-embedding.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
---

FSMGen supports paired scalar read-data routing over generated mixed
dynamic/static read same-ID `issue-order-queue` completions for exactly one
dynamic read transaction plus one concrete static read transaction in one
depth-2 generated mixed queue.

The public samples are:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_same_id_issue_order_queue_read_data.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data.ppif
```

The single-beat queue path uses completion validity
`generated_mixed_dynamic_static_read_issue_order_queue_response_demux_completion_pulse`.
The last-beat queue path uses completion validity
`generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse`.
Both `.514` shapes keep the response-demux queue-owned and generate scalar
`RDATA`/`RRESP` capture. Raw `ARLEN`, runtime validation, multi-beat output
banks, broader mixed queue cardinality, scoreboards, direct backend behavior,
backend-language variants, verification-output generation, external converter
dependencies, and VHDL remain future owners.
