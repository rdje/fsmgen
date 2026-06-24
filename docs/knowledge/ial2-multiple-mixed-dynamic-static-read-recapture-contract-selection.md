---
id: ial2-multiple-mixed-dynamic-static-read-recapture-contract-selection
title: Two-static mixed dynamic/static read recapture contract selected
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.410 select?"
  - "what is the contract for one dynamic plus two static mixed read recapture?"
  - "how should multi-static mixed read recapture be reported?"
  - "what PPIF sample owns the first broader mixed read recapture implementation?"
  - "what assertions change for two-static mixed read recapture?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, recapture, task-tree]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.410|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.411|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION|read_mixed_dynamic_static_response_demux_multi_static|generated_multi_mixed_dynamic_static_read_demux_completion|axi0_r2_static_busy_release_recapture|axi0_r2_static_request_idle_or_releasing' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.410` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.411`, direct implementation of
one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture on:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
```

The contract keeps the existing public syntax, support identity,
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`,
`response_scope: single_beat`,
`generated_multi_mixed_dynamic_static_read_demux`, and
`matched_dynamic_or_static_concrete_id_single_beat`.

Dynamic recapture fields are selected for
`response_demux.read.dynamic_capture.transactions[0]`, using
`mixed_dynamic_static_dynamic_read` with `release_recapture_source` set to
`generated_multi_mixed_dynamic_static_read_demux_completion`.

Static `r1` and `r2` recapture entries are selected as list-shaped
`response_demux.read.static_capture[]` entries ordered like
`static_transactions`, using `mixed_dynamic_static_static_read` and the same
multi-mixed read release-recapture source.

The selected assertions replace the `r0`, `r1`, and `r2` request-not-busy
assertions with idle-or-releasing names while preserving onehot0,
static-ID exclusions, response active-match, pairwise unique-match,
completion-active assertions, and scalar single-beat read-data consumers over
generated multiple mixed read completion pulses.
