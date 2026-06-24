---
id: ial2-two-dynamic-one-static-mixed-read-recapture-contract-selection
title: Two-dynamic one-static mixed read recapture contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.426 select?"
  - "what is the two-dynamic-plus-one-static mixed read recapture contract?"
  - "what should IAL2-FEATURE-COMPLETENESS-FRONTIER.427 implement?"
  - "what assertions change for two-dynamic-plus-one-static mixed read recapture?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, recapture, contract]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.426|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.427|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION|mixed_dynamic_static_multi_active_dynamic_read|axi0_r0_dynamic_id_release_recapture|axi0_r1_dynamic_id_release_recapture|axi0_r2_static_busy_release_recapture|axi0_r2_static_request_idle_or_releasing' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.426` selects `.427`, direct
implementation of two-dynamic-plus-one-static mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture on:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

The selector changes no behavior. The implementation should keep
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`,
`generated_multi_mixed_dynamic_static_read_demux`, and
`matched_dynamic_or_static_concrete_id_single_beat`.

The selected contract adds dynamic release-recapture fields under
`dynamic_capture.transactions[]` for `r0` and `r1` with policy
`mixed_dynamic_static_multi_active_dynamic_read`, source
`generated_multi_mixed_dynamic_static_read_demux_completion`, and
corresponding rules `axi0_r0_dynamic_id_release_recapture` and
`axi0_r1_dynamic_id_release_recapture`.

It also adds list-shaped `static_capture[]` for `r2` with
`axi0_r2_static_busy_release_recapture`, preserves
`mixed_dynamic_static_static_read`, and replaces only the `r0`/`r1`/`r2`
request-not-busy assertions with idle-or-releasing assertions.
