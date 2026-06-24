---
id: ial2-multiple-mixed-dynamic-static-read-recapture-readiness-audit
title: Multiple mixed dynamic/static read recapture audit selects contract selection
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.409 select?"
  - "is one-dynamic-plus-two-static mixed read recapture ready for contract selection?"
  - "which sample owns multiple mixed read single-beat recapture?"
  - "why not implement multiple mixed read recapture directly after .409?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, recapture, readiness]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.409|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.410|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT|read_mixed_dynamic_static_response_demux_multi_static|generated_multi_mixed_dynamic_static_read_demux_completion|axi0_r0_dynamic_request_not_busy|static_capture: absent' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.409` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.410`, public contract selection for
one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture.

The selected sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
```

A guarded baseline schedule probe completed at 79.6% host memory against the
88% cutoff and produced a 44021-byte schedule report. The live report still
uses `axi0_r0_dynamic_request_not_busy`,
`axi0_r1_static_request_not_busy`, and
`axi0_r2_static_request_not_busy`, has no `static_capture`, and has no
release-recapture fields under `dynamic_capture.transactions[]`.

The audit selects contract selection rather than direct implementation because
the read-side mixed recapture marker is still singular one-dynamic plus
one-static. The next contract must pin list-shaped static read recapture,
dynamic guard composition across both static siblings, idle-or-releasing
assertions, and scalar read-data preservation before behavior widens.
