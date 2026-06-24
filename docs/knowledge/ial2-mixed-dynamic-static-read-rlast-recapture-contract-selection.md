---
id: ial2-mixed-dynamic-static-read-rlast-recapture-contract-selection
title: Mixed dynamic/static read RLAST recapture contract selects implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.395 select?"
  - "what is the mixed dynamic/static read RLAST recapture contract?"
  - "what release_recapture_source should mixed read RLAST recapture use?"
  - "does mixed read RLAST recapture need new policy names?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, rlast, recapture, contract]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.395|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.396|MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION|generated_mixed_dynamic_static_read_demux_last_beat_completion|mixed_dynamic_static_dynamic_read|mixed_dynamic_static_static_read|axi0_r0_dynamic_request_idle_or_releasing|axi0_r1_static_request_idle_or_releasing' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.395` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.396`, direct implementation of mixed
dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif`.

The contract preserves `bounded_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`response_scope: burst_last`, `last_signal: axi0_rlast`, and transaction
completion source `generated_mixed_dynamic_static_read_demux_last_beat`.
Recapture should reuse the existing mixed read policy names
`mixed_dynamic_static_dynamic_read` and `mixed_dynamic_static_static_read`;
the last-beat distinction is reported through
`release_recapture_source:
generated_mixed_dynamic_static_read_demux_last_beat_completion`.

`.395` changes no parser, generator, PPIF sample, support-accounting catalog,
validation behavior, test, schedule/check/semantic JSON, HDL, or runtime
behavior.
