---
id: ial2-two-dynamic-one-static-mixed-write-recapture-contract-selection
title: Two-dynamic one-static mixed write recapture contract selected
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.406 select?"
  - "what is the contract for two-dynamic-plus-one-static mixed write recapture?"
  - "which policy names are selected for two-dynamic mixed write recapture?"
  - "how should two-dynamic-plus-one-static mixed write recapture be reported?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, write, recapture, task-tree]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md; ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.406|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.407|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION|mixed_dynamic_static_multi_active_dynamic_write|axi0_w1_dynamic_id_release_recapture|axi0_w2_static_busy_release_recapture|generated_multi_mixed_dynamic_static_demux_completion' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.406` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.407`, direct implementation of
two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle
release-and-recapture on:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

The contract keeps public syntax, support identity,
`bounded_multi_mixed_dynamic_static_write_bid_demux_contract`,
`generated_multi_mixed_dynamic_static_demux`, and
`matched_dynamic_or_static_concrete_id`.

Dynamic recapture fields are selected for both
`response_demux.write.dynamic_capture.transactions[]` entries, using the new
combined dynamic policy string
`mixed_dynamic_static_multi_active_dynamic_write` and
`release_recapture_source: generated_multi_mixed_dynamic_static_demux_completion`.
The static `w2`
recapture entry is list-shaped under `response_demux.write.static_capture[]`
and uses `mixed_dynamic_static_static_write`.

The selected assertions replace the `w0`, `w1`, and `w2` request-not-busy
assertions with idle-or-releasing names while preserving onehot0,
no-active-same-ID, active dynamic-ID uniqueness, static-ID exclusions,
response active-match, pairwise unique-match, and completion-active
assertions.
