---
id: ial2-multiple-mixed-dynamic-static-write-recapture-behavior
title: Two-static mixed dynamic/static write BID recapture is generated
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.400 ship?"
  - "is two-static mixed dynamic/static write same-cycle recapture generated?"
  - "where is multi-static mixed write recapture reported?"
  - "does two-static mixed write recapture change public syntax?"
  - "which broader mixed write recapture shapes remain deferred?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, write, recapture, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.400|MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR|mixed_dynamic_static_dynamic_write|mixed_dynamic_static_static_write|generated_multi_mixed_dynamic_static_demux_completion|axi0_w0_dynamic_id_release_recapture|axi0_w1_static_busy_release_recapture|axi0_w2_static_busy_release_recapture|axi0_w2_static_request_idle_or_releasing' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.400` ships one-dynamic plus two-static
mixed dynamic/static write `BID` same-cycle release-and-recapture for:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif
```

FSMGen emits `axi0_w0_dynamic_id_release_recapture` for the dynamic selected-ID
slot and `axi0_w1_static_busy_release_recapture` /
`axi0_w2_static_busy_release_recapture` for the two concrete static busy slots.
Release-only rules are disjoint from same-transaction same-cycle requests, and
the selected `w0`, `w1`, and `w2` request-not-busy assertions become
idle-or-releasing assertions.

The report keeps `bounded_multi_mixed_dynamic_static_write_bid_demux_contract`.
Dynamic recapture fields live under
`response_demux.write.dynamic_capture.transactions[0]`; static concrete busy
recapture lives under list-shaped `response_demux.write.static_capture[]`.
Public PPIF syntax and support-accounting identity are unchanged. Three-static
and two-dynamic-plus-one-static mixed write recapture remain deferred.
