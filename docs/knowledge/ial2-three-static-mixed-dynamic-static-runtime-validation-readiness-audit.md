---
id: ial2-three-static-mixed-dynamic-static-runtime-validation-readiness-audit
title: Three-static mixed read-data runtime validation audit selects direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.334 select?"
  - "is three-static mixed read-data runtime validation ready?"
  - "does three-static mixed read-data runtime validation need contract selection?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.335?"
  - "which sample should cover three-static mixed read-data runtime validation?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, burst-length, runtime-validation, readiness]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.334|IAL2-FEATURE-COMPLETENESS-FRONTIER\.335|THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT|multi_static3_burst_last_read_data_burst_length_runtime_assertion|mixed_dynamic_static_read_data_multi_static3_burst_length_runtime_assertion' docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.334` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.335`, direct bounded implementation of
runtime beat-count/`RLAST` validation over generated one-dynamic plus
three-concrete-static mixed dynamic/static raw-`ARLEN` last-beat read-data.

The audit found no separate public contract-selection leaf is needed. The
public `read-data.read` `burst-length` syntax already accepts
`validation runtime-assertion`, and the expected-beat storage, beat-count
storage, beat-count rules, runtime assertions, report fields, and residue
movement are already derived from the normalized transaction list once
coverage admits the shape.

`.335` should add the public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length_runtime_assertion.ppif`
and keep three-static multi-beat output banks, two-dynamic-plus-static
shapes, broader cardinalities, same-cycle widening, queues/scoreboards,
backend variants, and VHDL deferred.
