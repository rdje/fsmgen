---
id: ial2-two-dynamic-one-static-mixed-read-recapture-behavior
title: Two-dynamic one-static mixed read recapture behavior shipped
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.427 ship?"
  - "does two-dynamic-plus-one-static mixed read recapture now have release-recapture?"
  - "what policy reports for two-dynamic mixed read recapture?"
  - "what assertions changed for two-dynamic-plus-one-static mixed read recapture?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, recapture, behavior]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.427|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR|mixed_dynamic_static_multi_active_dynamic_read|axi0_r0_dynamic_id_release_recapture|axi0_r1_dynamic_id_release_recapture|axi0_r2_static_busy_release_recapture|axi0_r2_static_request_idle_or_releasing' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.427` ships
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture for:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

FSMGen now emits `axi0_r0_dynamic_id_release_recapture`,
`axi0_r1_dynamic_id_release_recapture`, and
`axi0_r2_static_busy_release_recapture`. Dynamic recapture reports use
`same_cycle_release_recapture_policy:
mixed_dynamic_static_multi_active_dynamic_read`; the static `r2` entry uses
`mixed_dynamic_static_static_read` under list-shaped `static_capture[]`.

The selected request-not-busy assertions are replaced by
`axi0_r0_dynamic_request_idle_or_releasing`,
`axi0_r1_dynamic_request_idle_or_releasing`, and
`axi0_r2_static_request_idle_or_releasing`, while onehot0,
no-active-same-ID, active dynamic-ID uniqueness, static-ID exclusions,
response active-match, pairwise unique-match, and completion-active
assertions are preserved.

The two-dynamic mixed read burst-last and read-data/raw-`ARLEN`/runtime/
multi-beat consumer samples remain no-recapture preservation boundaries for
this slice.
