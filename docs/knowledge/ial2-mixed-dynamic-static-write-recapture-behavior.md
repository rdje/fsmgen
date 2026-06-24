---
id: ial2-mixed-dynamic-static-write-recapture-behavior
title: Mixed dynamic/static write BID recapture is generated
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.389 ship?"
  - "is mixed dynamic/static write same-cycle recapture generated?"
  - "what report fields identify mixed dynamic/static write recapture?"
  - "does mixed dynamic/static write recapture change public syntax?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, write, recapture, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.389|MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR|mixed_dynamic_static_dynamic_write|mixed_dynamic_static_static_write|axi0_w0_dynamic_id_release_recapture|axi0_w1_static_busy_release_recapture|axi0_w0_dynamic_request_idle_or_releasing|axi0_w1_static_request_idle_or_releasing' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.389` ships mixed dynamic/static write
`BID` same-cycle release-and-recapture for
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif`.

FSMGen emits `axi0_w0_dynamic_id_release_recapture` for the dynamic selected-ID
slot and `axi0_w1_static_busy_release_recapture` for the concrete static busy
slot. It keeps release-only rules disjoint from same-transaction same-cycle
requests and replaces the selected dynamic/static request-not-busy assertions
with `axi0_w0_dynamic_request_idle_or_releasing` and
`axi0_w1_static_request_idle_or_releasing`.

The report keeps `bounded_mixed_dynamic_static_write_bid_demux_contract`.
Dynamic recapture fields live under `response_demux.write.dynamic_capture`
with policy `mixed_dynamic_static_dynamic_write`; static concrete busy
recapture lives under `response_demux.write.static_capture` with policy
`mixed_dynamic_static_static_write`. Public PPIF syntax and support-accounting
identity are unchanged.
