---
id: ial2-two-dynamic-one-static-mixed-write-recapture-readiness-audit
title: Two-dynamic one-static mixed write recapture audit selects contract selection
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.405 select?"
  - "is two-dynamic-plus-one-static mixed write recapture ready for contract selection?"
  - "why not implement two-dynamic mixed write recapture directly after .405?"
  - "which sample owns two-dynamic-plus-one-static mixed write recapture?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, write, recapture, readiness]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md; ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.405|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.406|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_READINESS_AUDIT|mixed_dynamic_static_write_response_demux_multi_dynamic|dynamic_request_idle_or_releasing|static_capture|multi_active_unique_dynamic_write|mixed_dynamic_static_dynamic_write' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.405` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.406`, public contract selection for
two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle
release-and-recapture.

The candidate sample is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

The audit found no smaller parser/source/support-accounting/report/assertion
substrate prerequisite. The existing state builder already computes sibling
dynamic request blocks, active sibling same-ID blocks, static request blocks,
static-ID exclusions, static dynamic-request blocks, idle-or-releasing names,
and the preservation assertions needed for the future behavior.

Direct implementation is not selected yet because the current mixed write
recapture marker is capped at exactly one dynamic transaction, and the dynamic
release-recapture helper currently selects either multi-active dynamic guards
or mixed static guards. `.406` must pin the public policy/source/report shape
and guard composition before behavior widens.
