---
id: ial2-protocol-neutral-valid-ready-bundle-readiness-audit
title: Neutral Valid-Ready PPIF bundle readiness selects contract first
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.533 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.534?"
  - "can FSMGen implement a protocol-neutral Valid-Ready bundle directly?"
  - "why does the neutral Valid-Ready bundle need contract selection?"
  - "what candidate source shape should a neutral Valid-Ready PPIF bundle use?"
date: 2026-06-26
status: current
tags: [ial2, ppif, protocol-platform, valid-ready, bundle, task-tree]
evidence: docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_READINESS_AUDIT.md; docs/IAL2_POST_NEUTRAL_VALID_READY_PPIF_NEXT_SLICE_SELECTION.md; docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_BEHAVIOR.md; docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_CONTRACT_SELECTION.md; docs/decisions/0017-ppif-valid-ready-bundle-contract.md; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm; ppif/valid_ready_handshake.ppif; ppif/axi_aw_w_valid_ready_bundle.ppif; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.533|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.534|valid_ready_dual_channel_bundle|intent\\.ppif_valid_ready_dual_channel_bundle|profile valid-ready supports exactly one|valid_ready_profile_bundle_behavior_outside_monitor|axi_manager_concurrency' docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-protocol-neutral-valid-ready-bundle-readiness-audit.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.533` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.534`, public contract selection for a
bounded protocol-neutral/non-AXI Valid-Ready `.ppif` bundle.

The audit did not select direct implementation because the aggregate wrapper
substrate exists, but public bundle details still need an exact contract:
sample/support identity, both neutral roles, source-anchor inheritance,
generic aggregate residue, docs/manifest wording, and focused validation.

The candidate source shape is a two-channel
`valid_ready_dual_channel_bundle` using `(profile valid-ready)`,
`data_downstream` with role `producer-to-consumer`, and `status_upstream` with
role `consumer-to-producer`.
