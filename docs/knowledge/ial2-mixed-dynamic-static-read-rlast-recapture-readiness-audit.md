---
id: ial2-mixed-dynamic-static-read-rlast-recapture-readiness-audit
title: Mixed dynamic/static read RLAST recapture readiness selects contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.394 select?"
  - "is mixed dynamic/static read RLAST recapture ready for direct implementation?"
  - "why select contract selection for mixed read RLAST recapture?"
  - "what remains to decide before mixed read burst-last recapture implementation?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, rlast, recapture, readiness]
evidence: >-
  docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md;
  docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.394|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.395|MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT|generated_mixed_dynamic_static_read_demux_last_beat|bounded_mixed_dynamic_static_read_rid_rlast_demux_contract|mixed dynamic/static read burst-last `RID && RLAST` same-cycle release-and-recapture' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.394` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.395`, public contract selection for mixed
dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture.

The audit found the shape ready for contract selection, not direct
implementation. The current public sample already has
`bounded_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`response_scope: burst_last`, `last_signal: axi0_rlast`, and completion source
`generated_mixed_dynamic_static_read_demux_last_beat`, but no recapture
metadata or `static_capture` block. `.395` must pin last-beat report-source
spelling, dynamic/static recapture fields, idle-or-releasing assertions, and
raw non-final `RID` preservation before behavior changes.

`.394` changes no parser, generator, PPIF sample, support-accounting catalog,
validation behavior, test, schedule/check/semantic JSON, HDL, or runtime
behavior.
