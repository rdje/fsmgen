---
id: ial2-apb-multi-peripheral-data16-protection-back-to-back-contract-selection
title: APB multi-peripheral data16 protection back-to-back contract selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.633?"
  - "which APB multi-peripheral data16 protection back-to-back samples are selected?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.634 implement?"
  - "what is the selected APB multi-peripheral data16 protection timing contract?"
  - "what APB timing work remains deferred after .633?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, protection, pprot, multi-peripheral, back-to-back, contract, task-tree]
evidence: docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_POST_APB_DATA16_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif; ppif/apb_composition_multi_peripheral_sideband_data16_protection.apb; ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.ppif; ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.633|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.634|apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back|multi-peripheral data16-protection|back_to_back_policy' docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/Support/RegressionCorpus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.633` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.634` to directly implement the bounded APB
sideband-aware multi-peripheral data16-protection back-to-back timing-policy
contract.

The selected public sources are:

- `ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.apb`

The selected family keeps the existing two-peripheral status/control topology,
32-bit address map, 16-bit data, `PPROT width 3`, `PSTRB width 2`, and
peripheral-completer-owned register-local privileged `PPROT[0]` policy. It
adds requester `accepted/busy/status` depth-1 queued timing, adjacent setup on
both selected peripheral completers, and aggregate multi-peripheral
`back_to_back_policy` reporting through the generated interconnect.

`.634` may widen only the exact selected multi-peripheral data16-protection
timing guard and add the two selected support-accounting identities. Broader
multi-peripheral multi-register timing, deeper queues, alternate overflow,
accepted-less requesters, multiple active APB transfers, broader protection
policies, direct backend, verification-output, backend-language variants, AXI,
AHB, and VHDL remain deferred.
