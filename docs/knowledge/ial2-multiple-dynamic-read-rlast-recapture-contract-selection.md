---
id: ial2-multiple-dynamic-read-rlast-recapture-contract-selection
title: Multiple dynamic read RLAST recapture contract selected
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.384 select?"
  - "what is the contract for multiple dynamic read RLAST recapture?"
  - "what follows the multiple dynamic read RLAST recapture contract?"
  - "which release_recapture_source is used for multiple dynamic read RLAST recapture?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, read, rlast, recapture, contract]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.384|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.385|MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION|generated_dynamic_demux_last_beat_completion|multi_active_unique_dynamic_read|axi0_r0_dynamic_request_idle_or_releasing|bounded_multi_dynamic_read_rid_rlast_demux_contract' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.384` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.385`, direct implementation of multiple
all-dynamic read burst-last `RID && RLAST` same-cycle release-and-recapture.

The selector changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifact, test, JSON, HDL, or runtime behavior.

The selected contract preserves the existing
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif`
sample, `bounded_multi_dynamic_read_rid_rlast_demux_contract`, onehot0 request
policy, raw non-final beat matching, final `RID && RLAST` completions, and
layered read-data/raw-`ARLEN`/runtime/multi-beat consumers.

Each dynamic read transaction should report
`same_cycle_release_recapture_policy: multi_active_unique_dynamic_read` and
`release_recapture_source: generated_dynamic_demux_last_beat_completion`.
Per-transaction request-not-busy assertions should become
`axi0_rN_dynamic_request_idle_or_releasing`.
