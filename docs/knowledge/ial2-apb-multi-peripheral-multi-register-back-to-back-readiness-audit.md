---
id: ial2-apb-multi-peripheral-multi-register-back-to-back-readiness-audit
title: APB sideband protection multi-peripheral timing selected after multi-register audit
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.636?"
  - "what APB multi-peripheral multi-register timing target follows .636?"
  - "why select APB sideband protection multi-peripheral timing next?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.637 select?"
date: 2026-06-28
status: current
tags: [ial2, apb, multi-peripheral, multi-register, protection, sideband, back-to-back, readiness, task-tree]
evidence: docs/IAL2_APB_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT.md; docs/IAL2_POST_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_REGISTER_SIDEBAND_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_composition_multi_peripheral_sideband_protection.ppif; ppif/apb_composition_multi_peripheral_sideband_protection.apb; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.636|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.637|apb_composition_multi_peripheral_sideband_protection|multi-peripheral multi-register|apb_back_to_back_policy_deferred' docs/IAL2_APB_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md ppif/apb_composition_multi_peripheral_sideband_protection.ppif perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/Support/LanguageSurfaceSection.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.636` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.637`, public contract selection for the
bounded 32-bit sideband-aware protection multi-peripheral back-to-back timing
family.

The selected candidate starts from the existing non-timing
`ppif/apb_composition_multi_peripheral_sideband_protection.ppif` family. That
surface already has one depth-1 queued requester, two protected 32-bit
sideband-aware peripheral completers, `PPROT width 3`, `PSTRB width 4`, two
protected registers per peripheral at byte addresses `0` and `4`, windows at
`0` and `256`, propagation-only interconnect decode, peripheral-completer-owned
protection enforcement, and broad `apb_back_to_back_policy_deferred` residue.

`.636` changes no behavior. `.637` must settle exact source names, topology,
requester/completer/interconnect timing requirements, protection semantics,
queued setup decode, PPROT/PSTRB propagation, report and residue movement,
support-accounting identities, diagnostics, validation, rollback, and whether
`.638` can implement directly. No-policy multi-peripheral multi-register,
sideband data16 no-policy multi-register, data16-protection generalization,
generalized register shapes, deeper queues, alternate overflow, accepted-less
requesters, multiple-active transfers, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL behavior
remain deferred.
