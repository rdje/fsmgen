---
id: ial2-mixed-dynamic-static-multi-beat-readiness-audit
title: IAL2 mixed dynamic/static multi-beat readiness selects direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.290 decide?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.290?"
  - "can mixed dynamic/static multi-beat output banks be implemented directly?"
  - "what is the next IAL2 slice after mixed dynamic/static runtime validation?"
  - "what PPIF sample should cover mixed dynamic/static multi-beat read-data?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, read-data, multi-beat, readiness]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.290|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.291|MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT|capture_scope multi-beat|multi-beat-by-rid|response_demux_matched_read_beat|bounded_multi_beat_read_data_contract|read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.290` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.291`, direct bounded implementation of
generated mixed dynamic/static multi-beat read-data output banks over the
`.289` mixed runtime-validation boundary.

The audit found no lower-layer prerequisite and no separate public
contract-selection need. The `.289` runtime shape already provides generated
mixed dynamic/static `RID && RLAST` response-demux, raw `ARLEN` capture,
expected-beat storage, read-beat counters, raw matched-read-beat expressions,
and runtime assertions for exactly one dynamic read transaction plus one
concrete static read transaction. Existing multi-beat output-bank machinery is
transaction-list driven once the mixed coverage branch admits
`capture-scope multi-beat`.

The selected public sample for `.291` is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat.ppif
```

The selected source shape uses `capture-scope multi-beat`, `status-policy
per-beat`, `status-aggregation worst-observed`, `interleaving
multi-beat-by-rid`, runtime-assertion `burst-length` metadata, and complete
per-transaction output-bank bindings for the dynamic and static read
transactions.

Multiple mixed dynamic/static transactions, same-cycle widening,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL remain future owners.
