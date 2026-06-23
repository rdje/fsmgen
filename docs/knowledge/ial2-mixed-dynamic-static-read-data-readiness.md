---
id: ial2-mixed-dynamic-static-read-data-readiness
title: Mixed dynamic/static read-data readiness selects contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.282 select?"
  - "is mixed dynamic/static read-data ready for direct implementation?"
  - "why does mixed dynamic/static read-data need contract selection?"
  - "does .282 change code or generated behavior?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, readiness-audit]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RLAST_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.282|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.283|AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT|generated_mixed_dynamic_static_read_demux|generated_mixed_dynamic_static_read_demux_last_beat|public contract selection for bounded scalar read-data over generated mixed dynamic/static read response-demux|No parser, generator, PPIF sample, support-accounting catalog, validation behavior, generated artifact, test, schedule/check/semantic JSON, or HDL behavior changed' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.282` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.283`, public contract selection for
bounded scalar read-data over generated mixed dynamic/static read
response-demux.

Mixed dynamic/static read-data is close but not contract-complete. The current
read-data transaction coverage helper already handles generated auto-ID,
queue-head, mixed auto-ID plus queue-head, and all-dynamic response-demux
families, but it has no branch for
`generated_mixed_dynamic_static_read_demux` or
`generated_mixed_dynamic_static_read_demux_last_beat`.

The `.276` and `.280` mixed read demux reports expose the needed transaction
coverage and generated completion signals. `.283` must choose the public
single-beat and last-beat source shapes, exact transaction coverage rule,
sample names, completion-validity/report vocabulary, diagnostics, validation
gates, and residue before behavior changes.

`.282` is a docs/continuity audit only. It changes no parser, generator, PPIF
sample, support-accounting catalog, validation behavior, generated artifact,
test, schedule/check/semantic JSON, or HDL behavior.
