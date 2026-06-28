---
id: ial2-post-apb-data16-protection-back-to-back-next-slice-selection
title: APB multi-peripheral data16 protection timing follows fixed data16 protection timing
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.632?"
  - "what APB timing owner follows data16 protection back-to-back behavior?"
  - "why select APB multi-peripheral data16 protection timing next?"
  - "does APB multi-peripheral data16 protection still carry back-to-back residue after .631?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.633?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, protection, pprot, multi-peripheral, back-to-back, selection, task-tree]
evidence: docs/IAL2_POST_APB_DATA16_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif; ppif/apb_composition_multi_peripheral_sideband_data16_protection.apb; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.632|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.633|multi-peripheral data16-protection|apb_composition_multi_peripheral_sideband_data16_protection|apb_back_to_back_policy_deferred' docs/IAL2_POST_APB_DATA16_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.632` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.633`, public contract selection for a
bounded APB sideband-aware multi-peripheral data16-protection back-to-back
timing-policy family.

The selector changes no runtime behavior. It records the next owner after
`.631` shipped fixed-composition data16-protection timing because the existing
multi-peripheral data16-protection `.ppif` and `.apb` sources still have no
aggregate `back_to_back_policy` and retain broad
`apb_back_to_back_policy_deferred`.

The selected next owner is intentionally narrower than broader
multi-peripheral multi-register timing. It combines already shipped
capabilities: fixed data16-protection timing from `.631`, sideband-aware
multi-peripheral timing propagation from `.618`, no-sideband multi-peripheral
timing propagation from `.609`, and the sideband/data16/protection endpoint
timing prerequisites from `.622`, `.625`, `.628`, and `.631`.

`.633` must settle exact source names, endpoint timing requirements,
interconnect propagation requirements, report/residue movement, support
accounting, diagnostics, validation, and rollback before any behavior-bearing
implementation. Broader multi-peripheral multi-register timing, deeper queues,
alternate overflow, accepted-less requesters, multiple active APB transfers,
broader protection policies, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.
