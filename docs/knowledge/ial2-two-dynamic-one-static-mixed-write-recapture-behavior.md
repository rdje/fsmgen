---
id: ial2-two-dynamic-one-static-mixed-write-recapture-behavior
title: Two-dynamic one-static mixed write recapture behavior shipped
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.407 ship?"
  - "does two-dynamic-plus-one-static mixed write recapture now have release-recapture?"
  - "what policy reports for two-dynamic mixed write recapture?"
  - "what assertions changed for two-dynamic-plus-one-static mixed write recapture?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, write, recapture, behavior]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.407|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR|mixed_dynamic_static_multi_active_dynamic_write|axi0_w0_dynamic_id_release_recapture|axi0_w1_dynamic_id_release_recapture|axi0_w2_static_busy_release_recapture|axi0_w2_static_request_idle_or_releasing' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.407` ships
two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle
release-and-recapture for:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

FSMGen now emits `axi0_w0_dynamic_id_release_recapture`,
`axi0_w1_dynamic_id_release_recapture`, and
`axi0_w2_static_busy_release_recapture`. Dynamic recapture reports use
`same_cycle_release_recapture_policy:
mixed_dynamic_static_multi_active_dynamic_write`; the static `w2` entry uses
`mixed_dynamic_static_static_write` under list-shaped `static_capture[]`.

The selected request-not-busy assertions are replaced by
`axi0_w0_dynamic_request_idle_or_releasing`,
`axi0_w1_dynamic_request_idle_or_releasing`, and
`axi0_w2_static_request_idle_or_releasing`, while onehot0,
no-active-same-ID, active dynamic-ID uniqueness, static-ID exclusions,
response active-match, pairwise unique-match, and completion-active
assertions are preserved.
