---
id: ial2-two-dynamic-one-static-mixed-read-rlast-recapture-readiness-audit
title: Two-dynamic one-static mixed read RLAST recapture readiness audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.429 select?"
  - "is two-dynamic-plus-one-static mixed read RLAST recapture ready for contract selection?"
  - "what is the implementation gap for two-dynamic mixed read RLAST recapture?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, rlast, recapture, audit]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.429|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.430|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT|generated_multi_mixed_dynamic_static_read_demux_last_beat_completion|mixed_dynamic_static_multi_active_dynamic_read' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.429` selects `.430`, public contract
selection for two-dynamic-plus-one-static mixed dynamic/static read burst-last
`RID && RLAST` same-cycle release-and-recapture.

The audit changes no behavior. Direct baseline probes confirmed the candidate
burst-last response-demux/read-data/raw-`ARLEN` samples still have
request-not-busy assertions for `r0`, `r1`, and `r2`, no `static_capture`,
and no generated release-recapture rules.

No lower parser, support-accounting, report-schema, IAL1, or HDL prerequisite
was found. `.427` already supplied the read-side
`mixed_dynamic_static_multi_active_dynamic_read` policy and guard storage.
The remaining implementation gap is the burst-last multi-mixed read
normalizer selector, which still leaves the two-dynamic-plus-one-static
RLAST branch unmarked.
