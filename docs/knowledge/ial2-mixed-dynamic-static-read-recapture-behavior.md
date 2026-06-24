---
id: ial2-mixed-dynamic-static-read-recapture-behavior
title: Mixed dynamic/static read single-beat recapture is generated
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.392 ship?"
  - "is mixed dynamic/static read same-cycle recapture generated?"
  - "what report fields identify mixed dynamic/static read recapture?"
  - "does mixed dynamic/static read recapture change public syntax?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, recapture, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.392|MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR|mixed_dynamic_static_dynamic_read|mixed_dynamic_static_static_read|axi0_r0_dynamic_id_release_recapture|axi0_r1_static_busy_release_recapture|axi0_r0_dynamic_request_idle_or_releasing|axi0_r1_static_request_idle_or_releasing' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.392` ships mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif`.

FSMGen emits `axi0_r0_dynamic_id_release_recapture` for the dynamic selected-ID
slot and `axi0_r1_static_busy_release_recapture` for the concrete static busy
slot. It keeps release-only rules disjoint from same-transaction same-cycle
requests and replaces the selected dynamic/static request-not-busy assertions
with `axi0_r0_dynamic_request_idle_or_releasing` and
`axi0_r1_static_request_idle_or_releasing`.

The report keeps `bounded_mixed_dynamic_static_read_rid_demux_contract` and
`response_scope: single_beat`. Dynamic recapture fields live under
`response_demux.read.dynamic_capture` with policy
`mixed_dynamic_static_dynamic_read`; static concrete busy recapture lives under
`response_demux.read.static_capture` with policy
`mixed_dynamic_static_static_read`. Public PPIF syntax and support-accounting
identity are unchanged.
