---
id: ial2-post-two-dynamic-one-static-mixed-write-recapture-next-slice-selection
title: Post two-dynamic mixed write recapture selector chooses broader read audit
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.408 select?"
  - "what comes after two-dynamic-plus-one-static mixed write recapture?"
  - "which task owns broader mixed read recapture readiness after .407?"
  - "why not implement broader mixed read recapture directly after .408?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, recapture, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.408|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.409|POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION|read_mixed_dynamic_static_response_demux_multi_static|mixed_dynamic_static_read|generated_multi_mixed_dynamic_static_read_demux_completion|host memory reached 92\\.0%' docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.408` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.409`, readiness audit for
one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture.

The candidate public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
```

The selector changes no behavior. It chooses an audit rather than direct
contract selection because the read-side mixed recapture marker and report
projection are still singular one-dynamic plus one-static, while the candidate
has one dynamic read plus two concrete static reads and has scalar read-data
consumer preservation to keep intact.

A guarded baseline schedule probe for the candidate stopped before usable
output because host memory reached 92.0% against the default 88% cutoff; the
schedule output was 0 bytes and no cutoff was raised.
