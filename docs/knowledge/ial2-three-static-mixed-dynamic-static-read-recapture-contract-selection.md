---
id: ial2-three-static-mixed-dynamic-static-read-recapture-contract-selection
title: Three-static mixed read recapture contract selected
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.418 select?"
  - "what is the contract for one dynamic plus three static mixed read recapture?"
  - "what source should three-static mixed read recapture report?"
  - "what assertions change for three-static mixed read recapture?"
  - "what follows the three-static mixed read recapture contract?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, recapture, contract]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.418|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.419|THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION|generated_multi_mixed_dynamic_static_read_demux_completion|axi0_r3_static_busy_release_recapture|axi0_r3_static_request_idle_or_releasing|burst-last read report must remain outside' docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.418` selects `.419`, direct
implementation of one-dynamic-plus-three-static mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture for:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif
```

The contract preserves public syntax, support identity,
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`,
`response_scope: single_beat`, and
`transaction_completion_source: generated_multi_mixed_dynamic_static_read_demux`.

Dynamic recapture fields are selected for
`response_demux.read.dynamic_capture.transactions[0]`, using
`mixed_dynamic_static_dynamic_read` and
`generated_multi_mixed_dynamic_static_read_demux_completion`.

Static `r1`, `r2`, and `r3` recapture entries are selected as list-shaped
`response_demux.read.static_capture[]` entries ordered like
`static_transactions`, using `mixed_dynamic_static_static_read` and the same
single-beat release-recapture source.

The selected assertions replace request-not-busy for `r0`, `r1`, `r2`, and
`r3` with idle-or-releasing names while preserving onehot0, static-ID
exclusions, response active-match, pairwise unique-match, and
completion-active assertions. Three-static burst-last recapture and
two-dynamic-plus-one-static recapture remain deferred.
