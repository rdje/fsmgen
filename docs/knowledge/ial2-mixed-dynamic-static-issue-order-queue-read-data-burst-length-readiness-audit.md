---
id: ial2-mixed-dynamic-static-issue-order-queue-read-data-burst-length-readiness-audit
title: Mixed dynamic/static issue-order queue read-data burst-length readiness audit
answers:
  - "is raw ARLEN over mixed dynamic/static issue-order queue read-data ready?"
  - "what should implement mixed queue read-data burst-length?"
  - "where does mixed queue read-data burst-length fail today?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.515 select?"
date: 2026-06-26
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, same-id-ordering, issue-order-queue, read-data, arlen, readiness-audit]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.515|IAL2-FEATURE-COMPLETENESS-FRONTIER\.516|MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT|generated_mixed_dynamic_static_issue_order_queue_demux_last_beat|read_data.read mixed dynamic/static issue-order queue coverage requires|read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.515` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.516`, direct bounded implementation of
report-only raw-`ARLEN` burst-length capture over generated mixed
dynamic/static read burst-last same-ID `issue-order-queue` scalar read-data.

Existing PPIF `burst-length` syntax, dynamic issue-order queue raw-`ARLEN`
behavior, and ordinary mixed response-demux raw-`ARLEN` behavior are sufficient
precedent. A guarded temporary candidate reached the local mixed queue
read-data coverage branch and failed only because that branch still requires
no `burst_length` metadata.

The selected `.516` sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length.ppif
```

`.516` should stay bounded to one dynamic read plus one concrete static read,
one depth-2 generated mixed queue, `capture-scope last-beat`, report-only
raw-`ARLEN`, and the `.514` queue-specific last-beat completion-validity name.
Runtime validation, multi-beat output banks, broader mixed cardinality,
scoreboards, direct backend behavior, backend-language variants,
verification-output generation, external converter dependencies, and VHDL
remain future owners.
