---
id: ial2-broader-mixed-dynamic-static-recapture-readiness-audit
title: Broader mixed dynamic/static recapture audit selects two-static write contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.398 select?"
  - "what is the first broader mixed dynamic/static recapture owner?"
  - "why start broader mixed recapture with one dynamic plus two static write?"
  - "is broader mixed dynamic/static recapture ready for direct implementation?"
  - "what PPIF sample should broader mixed dynamic/static recapture contract selection use first?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, recapture, readiness, task-tree]
evidence: docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.398|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.399|BROADER_MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT|write_mixed_dynamic_static_response_demux_multi_static|bounded_multi_mixed_dynamic_static_write_bid_demux_contract|static_capture=absent' docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.398` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.399`, public contract selection for
one-dynamic plus two-static mixed dynamic/static write `BID` same-cycle
release-and-recapture on:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif
```

The audit changes no behavior and does not select direct implementation. The
two-static write sample is the first broader recapture owner because it is the
smallest public shape beyond one-dynamic plus one-static: it adds sibling
static busy recapture and multiple static-ID exclusions without introducing
read-side `RLAST`/read-data preservation or two-dynamic active-ID uniqueness.
Guarded baseline probes confirmed the two-static, three-static, and
two-dynamic-plus-one-static write samples still report no `static_capture`
recapture block before `.399`.
