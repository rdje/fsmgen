---
id: ial2-dynamic-read-rlast-recapture-readiness-audit
title: Dynamic read burst-last recapture contract selection is next
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.370 select?"
  - "is burst-last dynamic read recapture ready for contract selection?"
  - "why does dynamic read RLAST recapture need a contract selector?"
  - "what dynamic read-data consumers affect RLAST recapture?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, read, rlast, recapture, readiness]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.370|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.371|DYNAMIC_READ_RLAST_RECAPTURE_READINESS_AUDIT|bounded_dynamic_read_rid_rlast_demux_contract|axi0_r0_dynamic_request_not_busy|single_active_dynamic_read' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.370` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.371`, public contract selection for
single-active dynamic read burst-last `RID && RLAST` same-cycle
release-and-recapture.

The audit changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifact, test, JSON, or HDL behavior.

The audit found no lower cleanup prerequisite before contract selection, but it
does not select direct behavior because burst-last recapture must define
final-completion-only release-and-recapture, raw matched non-last beat
preservation, active-match assertion semantics, scalar last-beat read-data
preservation, and the boundary for report-only raw-`ARLEN`,
runtime beat-count/`RLAST`, and multi-beat output-bank consumers.

The existing public burst-last mode remains
`bounded_dynamic_read_rid_rlast_demux_contract` until `.371` selects exact
report vocabulary.
