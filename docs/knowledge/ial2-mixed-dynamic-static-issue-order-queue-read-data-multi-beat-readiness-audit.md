---
id: ial2-mixed-dynamic-static-issue-order-queue-read-data-multi-beat-readiness-audit
title: Mixed dynamic/static issue-order queue read-data multi-beat readiness audit
answers:
  - "is multi-beat output-bank support ready over mixed dynamic static issue-order queue read-data?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.519 select?"
  - "what should implement mixed dynamic static issue-order queue read-data multi-beat output banks?"
date: 2026-06-26
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, same-id-ordering, issue-order-queue, read-data, multi-beat, output-bank, readiness-audit]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.519|IAL2-FEATURE-COMPLETENESS-FRONTIER\.520|read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_multi_beat|_read_data_response_demux_transaction_coverage|generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.519` selects `.520`, direct bounded
implementation of multi-beat output banks over generated mixed dynamic/static
read burst-last same-ID `issue-order-queue` runtime-validation read-data.

The audit found the remaining blocker local to
`_read_data_response_demux_transaction_coverage`: the mixed dynamic/static issue
order queue branch supports scalar single-beat and scalar last-beat, including
report-only/runtime raw-`ARLEN`, but does not yet admit the `multi-beat`
runtime-assertion boundary that the dynamic queue branch already supports.

Shared normalization, report metadata, output-bank rule generation, status
aggregation, beat-count/`RLAST` assertions, response-state lookup, parser
syntax, and test helper vocabulary are already present. The selected `.520`
sample should be:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif
```

Broader mixed queue cardinality, scoreboards, backend behavior,
backend-language variants, verification-output generation, external converter
dependencies, and VHDL remain future owners.
