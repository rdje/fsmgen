---
id: ial2-post-three-static-mixed-dynamic-static-read-recapture-next-slice-selection
title: Post three-static mixed read recapture selector
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.420 select?"
  - "what comes after three-static mixed read single-beat recapture?"
  - "what is the current three-static mixed read burst-last recapture baseline?"
  - "why audit three-static mixed read burst-last recapture next?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, rlast, recapture, selection]
evidence: docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.420|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.421|POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION|multi_static3_burst_last|generated_multi_mixed_dynamic_static_read_demux_last_beat|static_capture_present|request_not_busy_assertions' docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.420` selects `.421`, readiness audit for
one-dynamic-plus-three-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture.

The selected public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
```

The selector changes no behavior. A direct baseline probe confirms the
current report remains
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract` with
`response_scope: burst_last`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat`, no
`static_capture`, no dynamic recapture fields, and four request-not-busy
assertions.

The audit comes next because `.419` shipped the three-static single-beat
recapture sibling, `.415` shipped the two-static burst-last precedent, and
the current burst-last normalizer still marks recapture only for exactly
one dynamic plus two static states.
