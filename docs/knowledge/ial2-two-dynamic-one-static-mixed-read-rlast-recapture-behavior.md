---
id: ial2-two-dynamic-one-static-mixed-read-rlast-recapture-behavior
title: Two-dynamic one-static mixed read RLAST recapture behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.431 ship?"
  - "does two-dynamic mixed read RLAST recapture now emit release-recapture rules?"
  - "how is two-dynamic-plus-one-static mixed read burst-last recapture reported?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, rlast, recapture, behavior]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.431|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR|axi0_r0_dynamic_id_release_recapture|axi0_r1_dynamic_id_release_recapture|axi0_r2_static_busy_release_recapture|mixed_dynamic_static_multi_active_dynamic_read|generated_multi_mixed_dynamic_static_read_demux_last_beat_completion' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.431` ships
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif`.

FSMGen now emits `axi0_r0_dynamic_id_release_recapture`,
`axi0_r1_dynamic_id_release_recapture`, and
`axi0_r2_static_busy_release_recapture` from generated final-beat completion
pulses only. Dynamic recapture reports under
`response_demux.read.dynamic_capture.transactions[]` use
`mixed_dynamic_static_multi_active_dynamic_read` and
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`.
Static recapture reports as list-shaped `static_capture[]` for `r2` with
`mixed_dynamic_static_static_read`.

The behavior preserves the existing public sample, support identity,
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`axi0_rlast`, raw non-final `RID` active/unique-match assertions, final-beat
completion ownership, and layered read-data/raw-`ARLEN`/runtime/multi-beat
consumer behavior.
