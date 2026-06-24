---
id: ial2-multiple-mixed-dynamic-static-write-recapture-contract-selection
title: Two-static mixed dynamic/static write recapture contract selected
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.399 select?"
  - "what is the contract for one dynamic plus two static mixed write recapture?"
  - "how should multi-static mixed write recapture be reported?"
  - "what PPIF sample owns the first broader mixed write recapture implementation?"
  - "what assertions change for two-static mixed write recapture?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, write, recapture, task-tree]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.399|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.400|MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION|write_mixed_dynamic_static_response_demux_multi_static|generated_multi_mixed_dynamic_static_demux_completion|axi0_w2_static_busy_release_recapture|axi0_w2_static_request_idle_or_releasing' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.399` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.400`, direct implementation of
one-dynamic plus two-static mixed dynamic/static write `BID` same-cycle
release-and-recapture on:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif
```

The contract keeps the existing public syntax, support identity,
`bounded_multi_mixed_dynamic_static_write_bid_demux_contract`,
`generated_multi_mixed_dynamic_static_demux`, and
`matched_dynamic_or_static_concrete_id`. It adds dynamic recapture metadata to
`response_demux.write.dynamic_capture.transactions[0]` and selects a
list-shaped `response_demux.write.static_capture[]` block for `w1` and `w2`.
The selected assertions replace the `w0`, `w1`, and `w2` request-not-busy
assertions with idle-or-releasing names while preserving onehot0, static-ID
exclusion, response active-match, pairwise unique-match, and completion-active
assertions.
