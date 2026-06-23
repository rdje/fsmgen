---
id: ial2-multiple-mixed-dynamic-static-read-data-readiness-audit
title: Multiple mixed dynamic/static read-data readiness selects contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.305 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.306?"
  - "is multiple mixed dynamic/static scalar read-data ready for implementation?"
  - "why select a contract for multiple mixed dynamic/static read-data?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, readiness]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.305|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.306|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT|generated_multi_mixed_dynamic_static_read_demux|generated_mixed_dynamic_static_read_demux|requires exactly one dynamic read transaction and one concrete static read transaction' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.305` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.306`, public contract selection for
bounded scalar read-data over generated multiple mixed dynamic/static read
response-demux.

The audit changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifacts, tests, schedule/check or semantic
JSON, or HDL behavior.

The existing scalar read-data capture pipeline is close: once coverage is
admitted, it already validates exact transaction bindings and emits one
capture rule per normalized transaction. The missing contract is the widened
coverage selector for the `.299` and `.303` completion sources
`generated_multi_mixed_dynamic_static_read_demux` and
`generated_multi_mixed_dynamic_static_read_demux_last_beat`, plus public
sample naming, completion-validity vocabulary, diagnostics, validation
strategy, and residue movement.
