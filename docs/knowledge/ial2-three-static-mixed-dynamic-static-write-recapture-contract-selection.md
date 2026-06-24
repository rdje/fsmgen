---
id: ial2-three-static-mixed-dynamic-static-write-recapture-contract-selection
title: Three-static mixed dynamic/static write recapture contract selected
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.402 select?"
  - "what is the contract for one dynamic plus three static mixed write recapture?"
  - "how should three-static mixed write recapture be reported?"
  - "what assertions change for three-static mixed write recapture?"
  - "which sample owns three-static mixed write recapture implementation?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, write, recapture, task-tree]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.402|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.403|THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION|write_mixed_dynamic_static_response_demux_multi_static3|axi0_w3_static_busy_release_recapture|axi0_w3_static_request_idle_or_releasing|generated_multi_mixed_dynamic_static_demux_completion' docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.402` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.403`, direct implementation of
one-dynamic plus three-static mixed dynamic/static write `BID` same-cycle
release-and-recapture on:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif
```

The contract keeps public syntax, support identity,
`bounded_multi_mixed_dynamic_static_write_bid_demux_contract`,
`generated_multi_mixed_dynamic_static_demux`, and
`matched_dynamic_or_static_concrete_id`. It adds dynamic recapture metadata to
`response_demux.write.dynamic_capture.transactions[0]` and selects
list-shaped `response_demux.write.static_capture[]` entries for `w1`, `w2`,
and `w3`.

The selected assertions replace the `w0`, `w1`, `w2`, and `w3`
request-not-busy assertions with idle-or-releasing names while preserving
onehot0, static-ID exclusion, response active-match, pairwise unique-match,
and completion-active assertions.
