---
id: ial2-three-static-mixed-dynamic-static-read-data-burst-length-readiness-audit
title: Three-static mixed read-data burst-length audit selects direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.332 select?"
  - "is three-static mixed read-data burst-length ready?"
  - "does three-static mixed read-data burst-length need contract selection?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.333?"
  - "which sample should cover three-static mixed read-data burst-length?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read, read-data, burst-length, readiness]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.332|IAL2-FEATURE-COMPLETENESS-FRONTIER\.333|THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_READINESS_AUDIT|multi_static3_burst_last_read_data_burst_length|mixed_dynamic_static_read_data_multi_static3_burst_length' docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.332` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.333`, direct bounded implementation of
report-only raw-`ARLEN` burst-length capture over generated one-dynamic plus
three-concrete-static mixed dynamic/static read burst-last response-demux and
scalar last-beat read-data.

The audit found no separate public contract-selection leaf is needed. The
public `read-data.read` `burst-length` syntax is already shipped, and the
burst-length normalizer, request-time raw-`ARLEN` storage, capture-rule
generation, and report artifacts are transaction-list driven once coverage
admits the shape.

`.333` should add the public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length.ppif`
and keep three-static runtime validation, multi-beat output banks,
two-dynamic-plus-static shapes, broader cardinalities, same-cycle widening,
queues/scoreboards, backend variants, and VHDL deferred.
