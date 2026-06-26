---
id: ial2-mixed-dynamic-static-issue-order-queue-read-data-runtime-validation-readiness-audit
title: Mixed dynamic/static issue-order queue read-data runtime-validation readiness audit
answers:
  - "is runtime validation over mixed dynamic static issue-order queue read-data ready?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.517 select?"
  - "what should implement mixed queue read-data runtime validation?"
  - "where is mixed queue read-data runtime validation blocked?"
date: 2026-06-26
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, same-id-ordering, issue-order-queue, read-data, burst-length, arlen, runtime-validation, readiness]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.517|IAL2-FEATURE-COMPLETENESS-FRONTIER\.518|MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT|mixed_queue_last_beat_report_only_burst_length|validation runtime-assertion|read_data.read mixed dynamic/static issue-order queue coverage requires' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.517` selected `.518`, direct bounded
implementation of runtime beat-count/`RLAST` validation over generated mixed
dynamic/static read burst-last same-ID `issue-order-queue` scalar last-beat
read-data with raw-`ARLEN` capture.

The audit found the remaining blocker is local to the mixed queue branch in
`_read_data_response_demux_transaction_coverage`: it admits the `.516`
report-only raw-`ARLEN` shape but still rejects `burst_length_validation
runtime_assertion`. The shared normalization, runtime beat-count/`RLAST`
generation, and report artifact paths already exist behind admitted
`runtime_assertion` read-data contracts.

The selected `.518` public sample should be:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif
```

The selected coverage bucket should be:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion_pipeline_cli
```

Multi-beat output banks, broader mixed queues, scoreboards, direct backend
behavior, backend-language variants, verification-output generation, external
converter dependencies, and VHDL remain future owners.
