---
id: ial2-apb-data16-no-policy-multi-peripheral-multi-register-back-to-back-contract-selection
title: APB data16 no-policy multi-peripheral multi-register back-to-back contract selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.644?"
  - "what APB data16 no-policy multi-peripheral multi-register contract was selected?"
  - "what APB data16 no-policy multi-peripheral multi-register sources should .645 implement?"
  - "which APB data16 no-policy multi-peripheral multi-register timing variants remain deferred after .644?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, no-policy, multi-peripheral, multi-register, back-to-back, contract, task-tree]
evidence: docs/IAL2_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_POST_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.ppif; ppif/apb_composition_multi_peripheral_sideband_data16.ppif; ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.644|IAL2-FEATURE-COMPLETENESS-FRONTIER\.645|apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back|status window base default|control window base default|reg1 at byte address' docs/IAL2_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.644` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.645` to directly implement exactly:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.apb`

The selected contract is one requester, two peripheral completers, 32-bit
addresses, 16-bit APB/register data, `PPROT width 3`, `PSTRB width 2`,
status/control windows at bases `0` and `258` with size `258`, adjacent setup
on both peripherals, and exactly no-policy `reg0` at local address `0` plus
`reg1` at local address `2` in each peripheral.

`.645` must keep data16-protection generalization, generalized register
shapes, queue depths other than `1`, overflow policies other than `reject`,
accepted-less requesters, multiple active APB transfers, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL deferred.
