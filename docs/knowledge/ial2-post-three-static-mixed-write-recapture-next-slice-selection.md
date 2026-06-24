---
id: ial2-post-three-static-mixed-write-recapture-next-slice-selection
title: Post three-static mixed write recapture selector chooses two-dynamic audit
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.404 select?"
  - "what comes after three-static mixed write recapture?"
  - "why audit two-dynamic-plus-static mixed write recapture next?"
  - "why is broader mixed read recapture not next after .403?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, write, recapture, selection]
evidence: docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.404|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.405|POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION|two-dynamic-plus-one-static mixed dynamic/static write|mixed_dynamic_static_write_response_demux_multi_dynamic|multi_active_unique_dynamic_write|active_dynamic_ids_must_be_unique' docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.404` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.405`, readiness audit for
two-dynamic-plus-one-static mixed dynamic/static write `BID`
same-cycle release-and-recapture.

The candidate sample is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

This is the nearest post-`.403` residue because it stays write-only while
adding the already-shipped two-dynamic/one-static response-demux shape. It
needs an audit before contract selection because the current mixed write
recapture marker is capped at exactly one dynamic transaction and must be
composed with multi-active dynamic same-ID checks, active-ID uniqueness, and
static concrete-ID reservation before behavior can widen.

Broader mixed read recapture remains later because it would reintroduce raw
non-final `RID`, `RLAST`, read-data, raw-`ARLEN`, runtime-validation, and
multi-beat preservation concerns.
