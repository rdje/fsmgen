---
id: ial2-mixed-dynamic-static-issue-order-queue-read-data-readiness-audit
title: Mixed dynamic/static issue-order queue read-data audit selects direct implementation
answers:
  - "is mixed dynamic/static issue-order queue read-data ready?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.513 select?"
  - "what should implement mixed queue scalar read-data?"
  - "where does mixed queue read-data fail today?"
  - "does mixed queue read-data need a public contract selection?"
date: 2026-06-26
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, mixed-dynamic-static, same-id-ordering, issue-order-queue, read-data, readiness]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.513|IAL2-FEATURE-COMPLETENESS-FRONTIER\.514|MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT|generated_mixed_dynamic_static_issue_order_queue_demux|generated_mixed_dynamic_static_read_issue_order_queue_response_demux_completion_pulse|requires read response_demux auto transaction coverage metadata' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_READ_DATA_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.513` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.514`, direct bounded implementation of
paired scalar read-data routing over generated mixed dynamic/static read
same-ID `issue-order-queue` completions.

The public contract is already determined by existing scalar `read-data.read`
syntax and the prior generated dynamic queue plus mixed response-demux
read-data contracts. The remaining blocker is local to
`_read_data_response_demux_transaction_coverage`: it lacks a branch for
`generated_mixed_dynamic_static_issue_order_queue_demux` and
`generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`.

Temporary single-beat and burst-last candidates failed closed at the current
coverage fallback diagnostic:

```text
AXI manager capacity/status IAL2 contract read_data.read requires read response_demux auto transaction coverage metadata
```

No parser, PPIF syntax, IAL1, IAL0, SystemVerilog, backend, external
converter, or VHDL prerequisite was exposed.
