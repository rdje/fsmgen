---
id: ial2-multiple-mixed-dynamic-static-read-rlast-recapture-contract-selection
title: Two-static mixed read RLAST recapture contract selected
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.414 select?"
  - "what is the contract for one dynamic plus two static mixed read burst-last recapture?"
  - "what source should two-static mixed read RLAST recapture report?"
  - "what assertions change for two-static mixed read RLAST recapture?"
  - "what follows the two-static mixed read RLAST recapture contract?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, rlast, recapture, contract]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.414|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.415|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION|generated_multi_mixed_dynamic_static_read_demux_last_beat_completion|axi0_r2_static_busy_release_recapture|axi0_r2_static_request_idle_or_releasing|raw non-final' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.414` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.415`, direct implementation of
one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture for:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
```

The contract keeps existing public syntax, support identity,
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`response_scope: burst_last`, `last_signal: axi0_rlast`, and
`transaction_completion_source:
generated_multi_mixed_dynamic_static_read_demux_last_beat`.

Dynamic recapture fields are selected for
`response_demux.read.dynamic_capture.transactions[0]`, using
`mixed_dynamic_static_dynamic_read` and
`release_recapture_source:
generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`.

Static `r1` and `r2` recapture entries are selected as list-shaped
`response_demux.read.static_capture[]` entries ordered like
`static_transactions`, using `mixed_dynamic_static_static_read` and the same
final-beat release-recapture source.

The selected assertions replace the `r0`, `r1`, and `r2`
request-not-busy assertions with idle-or-releasing names while preserving
onehot0, static-ID exclusions, raw response active-match, pairwise raw
unique-match, completion-active assertions, and scalar read-data/raw-`ARLEN`/
runtime/multi-beat consumers. Raw non-final `RID` beats remain ownership
evidence only and must not release or recapture transactions.
