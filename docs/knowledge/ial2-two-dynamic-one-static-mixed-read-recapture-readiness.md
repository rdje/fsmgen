---
id: ial2-two-dynamic-one-static-mixed-read-recapture-readiness
title: Two-dynamic one-static mixed read recapture readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.425 decide?"
  - "is two-dynamic-plus-one-static mixed read recapture ready for contract selection?"
  - "what policy should two-dynamic-plus-one-static mixed read recapture use?"
  - "what should IAL2-FEATURE-COMPLETENESS-FRONTIER.426 select?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, recapture, readiness]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.425|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.426|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT|mixed_dynamic_static_multi_active_dynamic_read|generated_multi_mixed_dynamic_static_read_demux_completion|axi0_r0_dynamic_request_not_busy|axi0_r0_dynamic_request_idle_or_releasing' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.425` selects `.426`, public contract
selection for two-dynamic-plus-one-static mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture on:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

The audit changes no behavior. A guarded schedule probe stopped because host
memory was already 95.3% against the default 88% cutoff, so direct fallback
probes were used.

The selected sample currently remains no-recapture: no dynamic
release-recapture fields, no `static_capture`, no generated
release-recapture rules in ISF, and request-not-busy assertions for `r0`,
`r1`, and `r2`.

Direct contract selection is ready because the read state builder already has
the needed sibling dynamic request, active same-ID, static request, static-ID,
and dynamic request guard operands. The contract should pin a new dynamic
policy spelling, `mixed_dynamic_static_multi_active_dynamic_read`, with source
`generated_multi_mixed_dynamic_static_read_demux_completion`, list-shaped
static capture for `r2`, and idle-or-releasing assertions for `r0`, `r1`, and
`r2`.
