---
id: ial2-protocol-neutral-valid-ready-ppif-contract-selection
title: Protocol-neutral Valid-Ready PPIF uses the valid-ready profile contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.530 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.531?"
  - "what profile should a protocol-neutral Valid-Ready PPIF sample use?"
  - "what is the selected non-AXI Valid-Ready PPIF sample path?"
  - "does protocol-neutral Valid-Ready PPIF remove the profile clause?"
date: 2026-06-26
status: current
tags: [ial2, ppif, protocol-platform, valid-ready, profile, contract, task-tree]
evidence: docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_CONTRACT_SELECTION.md; docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_READINESS_AUDIT.md; docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; docs/decisions/0017-ppif-valid-ready-bundle-contract.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.530|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.531|profile valid-ready|valid_ready_handshake|intent\\.ppif_valid_ready_handshake|producer-to-consumer|does not introduce \\.axi' docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-protocol-neutral-valid-ready-ppif-contract-selection.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.530` selected the public contract for the
first protocol-neutral/non-AXI Valid-Ready `.ppif` example and selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.531`, direct bounded implementation.

The selected neutral profile remains explicit: the sample uses `(profile
valid-ready)`, not a no-profile form. The selected sample path is
`ppif/valid_ready_handshake.ppif`, with support-accounting identity
`intent.ppif_valid_ready_handshake`, logical channel `data_link`, role
`producer-to-consumer`, and generated monitor
`data_link_valid_ready_monitor`.
