---
id: ial2-protocol-neutral-valid-ready-bundle-contract-selection
title: Neutral Valid-Ready PPIF bundle contract selects dual-channel sample
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.534 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.535?"
  - "what is the neutral Valid-Ready PPIF bundle contract?"
  - "what is ppif/valid_ready_dual_channel_bundle.ppif?"
  - "what support-accounting id should the neutral Valid-Ready bundle use?"
date: 2026-06-26
status: current
tags: [ial2, ppif, protocol-platform, valid-ready, bundle, contract, task-tree]
evidence: docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_CONTRACT_SELECTION.md; docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_READINESS_AUDIT.md; docs/decisions/0017-ppif-valid-ready-bundle-contract.md; docs/IAL2_PPIF_VALID_READY_BUNDLE_CONTRACT_SELECTION.md; docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_SELECTION.md; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm; ppif/valid_ready_handshake.ppif; ppif/axi_aw_w_valid_ready_bundle.ppif; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.534|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.535|valid_ready_dual_channel_bundle|intent\\.ppif_valid_ready_dual_channel_bundle|ial2_ppif_valid_ready_dual_channel_bundle_pipeline_cli|valid_ready_profile_bundle_behavior_outside_monitor|producer-to-consumer|consumer-to-producer' docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-protocol-neutral-valid-ready-bundle-contract-selection.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.534` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.535`, direct bounded implementation of a
protocol-neutral/non-AXI Valid-Ready `.ppif` bundle.

The selected sample is `ppif/valid_ready_dual_channel_bundle.ppif`, with
support-accounting id `intent.ppif_valid_ready_dual_channel_bundle` and
coverage key `ial2_ppif_valid_ready_dual_channel_bundle_pipeline_cli`.

The sample uses `(profile valid-ready)`, channel `data_downstream` with role
`producer-to-consumer`, and channel `status_upstream` with role
`consumer-to-producer`. It reuses the existing aggregate
`valid_ready_bundle.v1` report schema and selects generic aggregate residue
instead of AXI manager concurrency residue.
