---
id: ial2-apb-data16-back-to-back-contract-selection
title: APB data16 back-to-back contract selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.624?"
  - "what APB data16 back-to-back contract was selected?"
  - "what APB data16 back-to-back samples should .625 implement?"
  - "which files are selected for APB data16 back-to-back?"
  - "does .624 select APB protection back-to-back timing?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.625?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, sideband, multi-register, back-to-back, contract, task-tree]
evidence: docs/IAL2_APB_DATA16_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_POST_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR.md; docs/IAL2_APB_PPROT_EFFECTS_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.624|IAL2-FEATURE-COMPLETENESS-FRONTIER\.625|apb_requester_transfer_sideband_data16_status_back_to_back|apb_completer_multi_register_sideband_data16_back_to_back|apb_composition_multi_register_sideband_data16_status_back_to_back|apb_remaining_widths_deferred|apb_protection_policy_effects_deferred' docs/IAL2_APB_DATA16_BACK_TO_BACK_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.624` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.625` to directly implement the bounded APB
sideband-aware data16 back-to-back timing-policy contract.

The selected public sources are:

- `ppif/apb_requester_transfer_sideband_data16_status_back_to_back.ppif`
- `ppif/apb_requester_transfer_sideband_data16_status_back_to_back.apb`
- `ppif/apb_completer_multi_register_sideband_data16_back_to_back.ppif`
- `ppif/apb_completer_multi_register_sideband_data16_back_to_back.apb`
- `ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.ppif`
- `ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.apb`

The selected contract combines a 16-bit sideband requester with
`accepted/busy/status`, depth-1 queued overflow-reject timing, a 16-bit
sideband two-register no-policy completer with `reg0` at address `0` and
`reg1` at address `2`, and fixed one-requester/one-completer composition.

`.624` does not select protection-only timing, combined data16-protection
timing, or multi-peripheral multi-register timing. Selected reports should
remove broad back-to-back residue only for the six selected sources while
keeping remaining-width and protection-policy residue explicit.
